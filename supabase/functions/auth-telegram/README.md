# auth-telegram

Edge Function для авторизации Telegram Mini App в Supabase.

## Как работает

1. Клиент (Mini App) отправляет `POST` с телом `{ initData: string }` — это строка `window.Telegram.WebApp.initData`.
2. Функция проверяет HMAC-подпись Telegram, используя `BOT_TOKEN`.
3. Апсертит запись в таблицу `users`. Если юзер новый — вызывает `copy_defaults_to_user(telegram_id)` для копии дефолтных рецептов.
4. Подписывает JWT секретом `SUPABASE_JWT_SECRET` с клеймами `{ sub, telegram_id, role: 'authenticated' }`.
5. Возвращает `{ token, user, is_new }`.

Этот JWT клиент потом передаёт в `createClient(SUPABASE_URL, ANON_KEY, { global: { headers: { Authorization: 'Bearer ' + token } } })` — и RLS-политики увидят `telegram_id` в клейме.

## Переменные окружения

Платформа Supabase автоматически прокидывает в Edge Function:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_JWT_SECRET`

**Тебе нужно поставить только один секрет вручную:**
- `BOT_TOKEN` — токен бота, выданный @BotFather

## Деплой — пошагово

### 1. Установить Supabase CLI

**Windows (через Scoop):**
```powershell
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

**Windows (через Chocolatey):**
```powershell
choco install supabase
```

**Mac (через Homebrew):**
```bash
brew install supabase/tap/supabase
```

Проверка: `supabase --version`

### 2. Залогиниться

```bash
supabase login
```

Откроется браузер — авторизуешься в Supabase.

### 3. Связать локальную папку с проектом

В корне `meal-prep/` выполни (`<project-ref>` — это id Supabase-проекта, его видно в URL дашборда `https://supabase.com/dashboard/project/<project-ref>`):

```bash
supabase link --project-ref <project-ref>
```

Спросит database password — подставь пароль БД (тот, что задавался при создании проекта).

### 4. Поставить секрет с токеном бота

```bash
supabase secrets set BOT_TOKEN=1234567890:AAA-BBBcccDDDeee
```

(Замени на реальный токен от @BotFather.)

Проверка:
```bash
supabase secrets list
```

Должна быть строчка `BOT_TOKEN`.

### 5. Задеплоить функцию

```bash
supabase functions deploy auth-telegram
```

Если всё ок — увидишь URL функции вида:
```
https://<project-ref>.supabase.co/functions/v1/auth-telegram
```

**Запомни этот URL — он понадобится в Этапе 3 (вставлять в `CONFIG.AUTH_FUNCTION_URL`).**

### 6. Проверить, что функция отвечает

```bash
curl -i -X POST \
  -H "Content-Type: application/json" \
  -d '{"initData":""}' \
  https://<project-ref>.supabase.co/functions/v1/auth-telegram
```

Ожидаемый ответ — `400 Bad Request` с JSON `{"error":"initData required"}`. Это нормально: пустой initData валидно отклонён.

Если получаешь `500 server misconfigured: missing env` — значит, не поставлен `BOT_TOKEN` (см. шаг 4) либо пустой `SUPABASE_JWT_SECRET` (это редко, но проверь в Settings → API).

### 7. (Опционально) Посмотреть логи

```bash
supabase functions logs auth-telegram
```

Или в дашборде: **Edge Functions → auth-telegram → Logs**.

## Полная проверка с настоящим initData

Полноценно протестировать получится только из Telegram (initData генерирует сам Telegram-клиент при открытии Mini App). Это будем делать в Этапе 3, когда подключим SDK на фронте.

## Возможные ошибки

| Ответ | Причина |
|---|---|
| `400 initData required` | Тело запроса пустое или нет поля `initData` |
| `401 invalid initData: bad signature` | `BOT_TOKEN` не совпадает с тем, чем подписался клиент. Проверь, что секрет поставлен от того же бота, через которого открывается Mini App |
| `401 invalid initData: initData expired` | initData старше 24 часов (replay-protection) |
| `500 server misconfigured` | Не поставлен `BOT_TOKEN` (см. шаг 4) |
| `500 db ...` | Не выполнен `schema.sql` или `seed.sql` (см. Этап 1) |
| `500 rpc copy_defaults` | Функция `copy_defaults_to_user` не создалась — перезапусти `schema.sql` |
