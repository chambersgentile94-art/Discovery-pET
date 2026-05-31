-- Discovery-pET - Alert events generated from active alert preferences

create table if not exists public.alert_events (
  id uuid primary key default gen_random_uuid(),
  alert_preference_id uuid not null references public.alert_preferences(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  report_id uuid not null references public.animal_reports(id) on delete cascade,
  distance_km numeric not null,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  read_at timestamptz,
  constraint alert_events_status_check check (status in ('pending', 'seen', 'dismissed', 'sent'))
);

alter table public.alert_events enable row level security;

create unique index if not exists idx_alert_events_unique_user_report
on public.alert_events(user_id, report_id);

create index if not exists idx_alert_events_user_status
on public.alert_events(user_id, status, created_at desc);

create index if not exists idx_alert_events_report_id
on public.alert_events(report_id);

drop policy if exists "Users can read own alert events" on public.alert_events;
drop policy if exists "Users can update own alert events" on public.alert_events;

create policy "Users can read own alert events"
on public.alert_events
for select
to authenticated
using (user_id = auth.uid());

create policy "Users can update own alert events"
on public.alert_events
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create or replace function private.distance_km(
  lat1 numeric,
  lon1 numeric,
  lat2 numeric,
  lon2 numeric
)
returns numeric
language sql
stable
set search_path = public, pg_temp
as $$
  select (
    6371 * 2 * asin(
      sqrt(
        power(sin(radians((lat2 - lat1)::double precision) / 2), 2) +
        cos(radians(lat1::double precision)) *
        cos(radians(lat2::double precision)) *
        power(sin(radians((lon2 - lon1)::double precision) / 2), 2)
      )
    )
  )::numeric;
$$;

create or replace function private.create_alert_events_for_report()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.alert_events (
    alert_preference_id,
    user_id,
    report_id,
    distance_km,
    status
  )
  select
    ap.id,
    ap.user_id,
    new.id,
    private.distance_km(ap.latitude, ap.longitude, new.latitude, new.longitude),
    'pending'
  from public.alert_preferences ap
  where ap.is_enabled = true
    and new.is_public = true
    and ap.latitude is not null
    and ap.longitude is not null
    and ap.user_id <> new.created_by
    and (
      (new.category = 'lost'::public.report_category and ap.notify_lost = true) or
      (new.category = 'seen'::public.report_category and ap.notify_seen = true) or
      (new.category = 'abandoned'::public.report_category and ap.notify_abandoned = true) or
      (new.category = 'injured'::public.report_category and ap.notify_injured = true) or
      (new.category = 'adoption'::public.report_category and ap.notify_adoption = true)
    )
    and private.distance_km(ap.latitude, ap.longitude, new.latitude, new.longitude) <= ap.radius_km
  on conflict (user_id, report_id) do nothing;

  return new;
end;
$$;

revoke execute on function private.distance_km(numeric, numeric, numeric, numeric) from public, anon, authenticated;
revoke execute on function private.create_alert_events_for_report() from public, anon, authenticated;

drop trigger if exists create_alert_events_after_report_insert on public.animal_reports;
create trigger create_alert_events_after_report_insert
after insert on public.animal_reports
for each row execute function private.create_alert_events_for_report();
