-- Live demo sync: one shared JSON row that the officer app (/app) and control room (/portal)
-- read and write, pushed to every open screen by Supabase Realtime.
-- Demo only: anyone with the public anon key can change this row. Real data goes in the
-- relational tables from the initial schema once proper sign-in is wired up.
create table if not exists public.demo_state (
  id         text primary key,
  state      jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.demo_state enable row level security;

drop policy if exists demo_state_read   on public.demo_state;
drop policy if exists demo_state_insert on public.demo_state;
drop policy if exists demo_state_update on public.demo_state;
create policy demo_state_read   on public.demo_state for select to anon, authenticated using (id = 'demo');
create policy demo_state_insert on public.demo_state for insert to anon, authenticated with check (id = 'demo');
create policy demo_state_update on public.demo_state for update to anon, authenticated using (id = 'demo') with check (id = 'demo');

grant select, insert, update on public.demo_state to anon, authenticated;

do $$ begin
  alter publication supabase_realtime add table public.demo_state;
exception when duplicate_object then null;
end $$;
