-- Discovery-pET - Device registry for future push notifications

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null default 'android',
  device_id text,
  push_token text not null,
  app_version text,
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_devices_platform_check check (platform in ('android', 'ios', 'web'))
);

alter table public.user_devices enable row level security;

create unique index if not exists idx_user_devices_unique_push_token
on public.user_devices(push_token);

create index if not exists idx_user_devices_user_id
on public.user_devices(user_id);

create index if not exists idx_user_devices_active_user
on public.user_devices(user_id, is_active);

drop policy if exists "Users can read own devices" on public.user_devices;
drop policy if exists "Users can create own devices" on public.user_devices;
drop policy if exists "Users can update own devices" on public.user_devices;
drop policy if exists "Users can delete own devices" on public.user_devices;

create policy "Users can read own devices"
on public.user_devices
for select
to authenticated
using (user_id = auth.uid());

create policy "Users can create own devices"
on public.user_devices
for insert
to authenticated
with check (user_id = auth.uid());

create policy "Users can update own devices"
on public.user_devices
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users can delete own devices"
on public.user_devices
for delete
to authenticated
using (user_id = auth.uid());

drop trigger if exists set_user_devices_updated_at on public.user_devices;
create trigger set_user_devices_updated_at
before update on public.user_devices
for each row execute function public.set_updated_at();
