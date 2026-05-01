// ============================================================================
// auth-telegram — Supabase Edge Function
// Принимает Telegram WebApp initData, проверяет подпись, апсертит юзера,
// при первом входе копирует дефолтные рецепты, выдаёт JWT для Supabase RLS.
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

// ─── ENV ────────────────────────────────────────────────────────────────────
const BOT_TOKEN = Deno.env.get("BOT_TOKEN");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
// SUPABASE_JWT_SECRET больше не выдаётся платформой автоматически.
// Достаём через `GET /v1/projects/{ref}/postgrest` и кладём в кастомный секрет.
const JWT_SECRET = Deno.env.get("PROJECT_JWT_SECRET");

const MAX_AUTH_AGE_SEC = 24 * 60 * 60;   // 24 часа — окно валидности initData
const JWT_TTL_SEC      = 24 * 60 * 60;   // 24 часа — срок действия выданного JWT

// ─── CORS ───────────────────────────────────────────────────────────────────
const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// ─── HMAC helpers ───────────────────────────────────────────────────────────
const enc = new TextEncoder();

async function hmacSha256(key: ArrayBuffer | Uint8Array, data: string): Promise<ArrayBuffer> {
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    key,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return crypto.subtle.sign("HMAC", cryptoKey, enc.encode(data));
}

function bufToHex(buf: ArrayBuffer): string {
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

// Постоянное по времени сравнение hex-строк — чтобы не словить timing-атаку
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

// ─── Telegram initData verification ─────────────────────────────────────────
// https://core.telegram.org/bots/webapps#validating-data-received-via-the-mini-app
async function verifyInitData(initData: string, botToken: string): Promise<{
  ok: boolean;
  reason?: string;
  user?: { id: number; username?: string; first_name?: string };
  authDate?: number;
}> {
  const params = new URLSearchParams(initData);
  const hash = params.get("hash");
  if (!hash) return { ok: false, reason: "no hash" };
  params.delete("hash");

  // data_check_string: пары key=value, отсортированные по ключу, склеенные \n
  const pairs: string[] = [];
  for (const [k, v] of params.entries()) pairs.push(`${k}=${v}`);
  pairs.sort();
  const dataCheckString = pairs.join("\n");

  // secret_key = HMAC_SHA256(<bot_token>, "WebAppData")
  // (data = bot_token, key = "WebAppData")
  const secretKey = await hmacSha256(enc.encode("WebAppData"), botToken);
  const computed = bufToHex(await hmacSha256(secretKey, dataCheckString));

  if (!timingSafeEqual(computed, hash)) return { ok: false, reason: "bad signature" };

  // auth_date — отбрасываем старые initData (защита от replay)
  const authDate = Number(params.get("auth_date") ?? "0");
  if (!Number.isFinite(authDate) || authDate <= 0) return { ok: false, reason: "no auth_date" };
  const ageSec = Math.floor(Date.now() / 1000) - authDate;
  if (ageSec > MAX_AUTH_AGE_SEC) return { ok: false, reason: "initData expired" };

  // user — это URL-decoded JSON
  const userRaw = params.get("user");
  if (!userRaw) return { ok: false, reason: "no user" };
  let user: { id: number; username?: string; first_name?: string };
  try {
    user = JSON.parse(userRaw);
  } catch {
    return { ok: false, reason: "bad user json" };
  }
  if (typeof user.id !== "number") return { ok: false, reason: "bad user.id" };

  return { ok: true, user, authDate };
}

// ─── JWT signing ────────────────────────────────────────────────────────────
async function signSupabaseJwt(telegramId: number, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
  return create(
    { alg: "HS256", typ: "JWT" },
    {
      sub: String(telegramId),
      telegram_id: telegramId,
      role: "authenticated",
      iat: getNumericDate(0),
      exp: getNumericDate(JWT_TTL_SEC),
    },
    key,
  );
}

// ─── Handler ────────────────────────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  if (!BOT_TOKEN || !SUPABASE_URL || !SERVICE_ROLE_KEY || !JWT_SECRET) {
    return json({ error: "server misconfigured: missing env" }, 500);
  }

  let initData: string;
  try {
    const body = await req.json();
    initData = body?.initData;
    if (typeof initData !== "string" || initData.length === 0) {
      return json({ error: "initData required" }, 400);
    }
  } catch {
    return json({ error: "bad json" }, 400);
  }

  // 1) Проверяем подпись
  const verified = await verifyInitData(initData, BOT_TOKEN);
  if (!verified.ok || !verified.user) {
    return json({ error: `invalid initData: ${verified.reason}` }, 401);
  }
  const tgUser = verified.user;

  // 2) Апсертим юзера через service_role (минуя RLS)
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Проверяем — был ли юзер до этого
  const { data: existing, error: selectErr } = await admin
    .from("users")
    .select("telegram_id")
    .eq("telegram_id", tgUser.id)
    .maybeSingle();
  if (selectErr) return json({ error: `db select: ${selectErr.message}` }, 500);

  const isNew = !existing;

  const { error: upsertErr } = await admin.from("users").upsert(
    {
      telegram_id: tgUser.id,
      username: tgUser.username ?? null,
      first_name: tgUser.first_name ?? null,
    },
    { onConflict: "telegram_id" },
  );
  if (upsertErr) return json({ error: `db upsert: ${upsertErr.message}` }, 500);

  // 3) Если юзер новый — копируем дефолтные рецепты
  if (isNew) {
    const { error: rpcErr } = await admin.rpc("copy_defaults_to_user", {
      p_user_id: tgUser.id,
    });
    if (rpcErr) return json({ error: `rpc copy_defaults: ${rpcErr.message}` }, 500);
  }

  // 4) Подписываем JWT
  let token: string;
  try {
    token = await signSupabaseJwt(tgUser.id, JWT_SECRET);
  } catch (e) {
    return json({ error: `jwt sign: ${(e as Error).message}` }, 500);
  }

  return json({
    token,
    user: {
      telegram_id: tgUser.id,
      username: tgUser.username ?? null,
      first_name: tgUser.first_name ?? null,
    },
    is_new: isNew,
  });
});
