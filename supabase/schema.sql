-- ============================================================================
-- Meal Prep Planner — schema.sql
-- Создаёт таблицы, RLS-политики и функцию копирования дефолтных рецептов.
-- Запускать в Supabase SQL Editor ПЕРЕД seed.sql.
-- ============================================================================

-- Расширение для gen_random_uuid()
create extension if not exists "pgcrypto";

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. USERS — пользователи Telegram
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.users (
  telegram_id bigint primary key,
  username    text,
  first_name  text,
  created_at  timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. RECIPES — рецепты заготовок
--    user_id NULL означает дефолтный рецепт (виден всем)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.recipes (
  id           uuid primary key default gen_random_uuid(),
  user_id      bigint references public.users(telegram_id) on delete cascade,
  name         text not null,
  type         text not null,                 -- 'chicken' | 'pork'
  category     text not null,                 -- 'marinade' | 'semi'
  emoji        text,
  recipe       text,                          -- как заготовить
  serve        text,                          -- как подавать
  time         int  not null default 20,      -- минут на финальную готовку
  meat         jsonb not null,                -- { type, grams }
  ingredients  jsonb not null default '[]'::jsonb,
  nutrition    jsonb,                         -- { kcal, protein, fat, carbs } | null
  is_default   boolean not null default false,
  created_at   timestamptz not null default now()
);

create index if not exists recipes_user_id_idx on public.recipes(user_id);
create index if not exists recipes_is_default_idx on public.recipes(is_default) where is_default = true;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. SIDES — справочник гарниров
--    Дефолтные (is_default=true) видны всем, пользовательские привязаны к user_id
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.sides (
  id          uuid primary key default gen_random_uuid(),
  user_id     bigint references public.users(telegram_id) on delete cascade,
  name        text not null,
  emoji       text,
  portion     int,                            -- граммы стандартной порции
  nutrition   jsonb,                          -- { kcal, protein, fat, carbs }
  is_default  boolean not null default false
);

create index if not exists sides_user_id_idx on public.sides(user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. PLAN — план ужинов на 14 дней (две недели)
--    day_index 0..13, week_start = дата начала текущего цикла планирования
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.plan (
  id          uuid primary key default gen_random_uuid(),
  user_id     bigint not null references public.users(telegram_id) on delete cascade,
  day_index   int  not null check (day_index between 0 and 13),
  recipe_id   uuid references public.recipes(id) on delete set null,
  side        text,
  status      text,                           -- null | 'prepped' | 'thawing' | 'done'
  week_start  date not null,
  updated_at  timestamptz not null default now(),
  unique (user_id, week_start, day_index)
);

create index if not exists plan_user_week_idx on public.plan(user_id, week_start);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. ACTIVE_RECIPES — какие рецепты пользователь включил «галочкой»
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.active_recipes (
  user_id    bigint not null references public.users(telegram_id) on delete cascade,
  recipe_id  uuid   not null references public.recipes(id) on delete cascade,
  primary key (user_id, recipe_id)
);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Хелпер: достать telegram_id из JWT-клейма (Edge Function кладёт его туда)
create or replace function public.current_telegram_id()
returns bigint
language sql
stable
as $$
  select nullif(current_setting('request.jwt.claims', true)::jsonb ->> 'telegram_id', '')::bigint
$$;

-- ─── USERS ───
alter table public.users enable row level security;

drop policy if exists users_select_own on public.users;
create policy users_select_own on public.users
  for select
  using (telegram_id = public.current_telegram_id());

drop policy if exists users_update_own on public.users;
create policy users_update_own on public.users
  for update
  using (telegram_id = public.current_telegram_id())
  with check (telegram_id = public.current_telegram_id());

-- INSERT в users делает только Edge Function (через service_role, RLS не применяется)

-- ─── RECIPES ───
alter table public.recipes enable row level security;

drop policy if exists recipes_select on public.recipes;
create policy recipes_select on public.recipes
  for select
  using (is_default = true or user_id = public.current_telegram_id());

drop policy if exists recipes_insert_own on public.recipes;
create policy recipes_insert_own on public.recipes
  for insert
  with check (user_id = public.current_telegram_id() and is_default = false);

drop policy if exists recipes_update_own on public.recipes;
create policy recipes_update_own on public.recipes
  for update
  using (user_id = public.current_telegram_id())
  with check (user_id = public.current_telegram_id());

drop policy if exists recipes_delete_own on public.recipes;
create policy recipes_delete_own on public.recipes
  for delete
  using (user_id = public.current_telegram_id());

-- ─── SIDES ───
alter table public.sides enable row level security;

drop policy if exists sides_select on public.sides;
create policy sides_select on public.sides
  for select
  using (is_default = true or user_id = public.current_telegram_id());

drop policy if exists sides_insert_own on public.sides;
create policy sides_insert_own on public.sides
  for insert
  with check (user_id = public.current_telegram_id() and is_default = false);

drop policy if exists sides_update_own on public.sides;
create policy sides_update_own on public.sides
  for update
  using (user_id = public.current_telegram_id())
  with check (user_id = public.current_telegram_id());

drop policy if exists sides_delete_own on public.sides;
create policy sides_delete_own on public.sides
  for delete
  using (user_id = public.current_telegram_id());

-- ─── PLAN ───
alter table public.plan enable row level security;

drop policy if exists plan_select_own on public.plan;
create policy plan_select_own on public.plan
  for select
  using (user_id = public.current_telegram_id());

drop policy if exists plan_insert_own on public.plan;
create policy plan_insert_own on public.plan
  for insert
  with check (user_id = public.current_telegram_id());

drop policy if exists plan_update_own on public.plan;
create policy plan_update_own on public.plan
  for update
  using (user_id = public.current_telegram_id())
  with check (user_id = public.current_telegram_id());

drop policy if exists plan_delete_own on public.plan;
create policy plan_delete_own on public.plan
  for delete
  using (user_id = public.current_telegram_id());

-- ─── ACTIVE_RECIPES ───
alter table public.active_recipes enable row level security;

drop policy if exists active_recipes_select_own on public.active_recipes;
create policy active_recipes_select_own on public.active_recipes
  for select
  using (user_id = public.current_telegram_id());

drop policy if exists active_recipes_insert_own on public.active_recipes;
create policy active_recipes_insert_own on public.active_recipes
  for insert
  with check (user_id = public.current_telegram_id());

drop policy if exists active_recipes_delete_own on public.active_recipes;
create policy active_recipes_delete_own on public.active_recipes
  for delete
  using (user_id = public.current_telegram_id());

-- ============================================================================
-- FUNCTION copy_defaults_to_user
-- При первой авторизации копирует все is_default=true рецепты в данные юзера
-- и проставляет их как активные (active_recipes). Также ничего не делает,
-- если у пользователя уже есть свои рецепты (повторный вызов безопасен).
-- ============================================================================
create or replace function public.copy_defaults_to_user(p_user_id bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_count int;
begin
  -- Если у пользователя уже есть рецепты — выходим (idempotent)
  if exists (select 1 from public.recipes where user_id = p_user_id) then
    return;
  end if;

  -- Копируем дефолтные рецепты
  with copied as (
    insert into public.recipes
      (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, nutrition, is_default)
    select
      p_user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, nutrition, false
    from public.recipes
    where is_default = true
    returning id
  )
  insert into public.active_recipes (user_id, recipe_id)
  select p_user_id, id from copied;

  get diagnostics inserted_count = row_count;
end;
$$;

-- Дать возможность Edge Function вызывать функцию
grant execute on function public.copy_defaults_to_user(bigint) to service_role;
