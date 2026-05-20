-- Discovery-pET - Alert preferences by zone

create table if not exists public.alert_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  city text,
  latitude numeric,
  longitude numeric,
  radius_km numeric not null default 5,
  notify_lost boolean not null default true,
  notify_seen boolean not null default true,
  notify_abandoned boolean not null default true,
  notify_injured boolean not null default true,
  notify_adoption boolean not null default false,
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint alert_preferences_radius_check check (radius_km > 0 and radius_km <= 100)
);

alter table public.alert_preferences enable row level security;

create index if not exists idx_alert_preferences_user_id
on public.alert_preferences(user_id);

create index if not exists idx_alert_preferences_enabled
on public.alert_preferences(is_enabled);

drop policy if exists "Users can read own alert preferences" on public.alert_preferences;
drop policy if exists "Users can create own alert preferences" on public.alert_preferences;
drop policy if exists "Users can update own alert preferences" on public.alert_preferences;
drop policy if exists "Users can delete own alert preferences" on public.alert_preferences;

create policy "Users can read own alert preferences"
on public.alert_preferences
for select
to authenticated
using (user_id = auth.uid());

create policy "Users can create own alert preferences"
on public.alert_preferences
for insert
to authenticated
with check (user_id = auth.uid());

create policy "Users can update own alert preferences"
on public.alert_preferences
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users can delete own alert preferences"
on public.alert_preferences
for delete
to authenticated
using (user_id = auth.uid());

drop trigger if exists set_alert_preferences_updated_at on public.alert_preferences;
create trigger set_alert_preferences_updated_at
before update on public.alert_preferences
for each row execute function public.set_updated_at();
