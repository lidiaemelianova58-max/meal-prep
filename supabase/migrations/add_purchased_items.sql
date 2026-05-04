-- ============================================================================
-- Этап 6.D — список купленных продуктов
-- Хранит галочки «куплено» из вкладки «Закупки». «Куплено навсегда» —
-- запись остаётся пока пользователь не снимет галочку вручную.
-- ============================================================================

create table if not exists public.purchased_items (
  user_id      bigint not null references public.users(telegram_id) on delete cascade,
  product_key  text   not null,
  purchased_at timestamptz not null default now(),
  primary key (user_id, product_key)
);

create index if not exists purchased_items_user_idx on public.purchased_items(user_id);

-- ─── RLS ───
alter table public.purchased_items enable row level security;

drop policy if exists purchased_select_own on public.purchased_items;
create policy purchased_select_own on public.purchased_items
  for select
  using (user_id = public.current_telegram_id());

drop policy if exists purchased_insert_own on public.purchased_items;
create policy purchased_insert_own on public.purchased_items
  for insert
  with check (user_id = public.current_telegram_id());

drop policy if exists purchased_delete_own on public.purchased_items;
create policy purchased_delete_own on public.purchased_items
  for delete
  using (user_id = public.current_telegram_id());
