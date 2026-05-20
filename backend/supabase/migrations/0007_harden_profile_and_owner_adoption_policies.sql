-- Discovery-pET - Harden profile role updates and adoption request owner policies

-- Adoption requests: allow report owners to read/update requests received for their reports.
drop policy if exists "Report owners can read adoption requests" on public.adoption_requests;
drop policy if exists "Report owners can update adoption requests" on public.adoption_requests;

create policy "Report owners can read adoption requests"
on public.adoption_requests
for select
to authenticated
using (
  exists (
    select 1
    from public.animal_reports ar
    where ar.id = adoption_requests.report_id
      and ar.created_by = auth.uid()
  )
);

create policy "Report owners can update adoption requests"
on public.adoption_requests
for update
to authenticated
using (
  exists (
    select 1
    from public.animal_reports ar
    where ar.id = adoption_requests.report_id
      and ar.created_by = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.animal_reports ar
    where ar.id = adoption_requests.report_id
      and ar.created_by = auth.uid()
  )
);

create unique index if not exists idx_adoption_requests_unique_requester_report
on public.adoption_requests(report_id, requester_id);

-- Profiles: users may update their own profile, but cannot self-promote to admin.
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Users can update own profile except admin role" on public.profiles;

create policy "Users can update own profile except admin role"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (
  auth.uid() = id
  and role <> 'admin'::public.user_role
);

-- Generic updated_at trigger helper.
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_animal_reports_updated_at on public.animal_reports;
create trigger set_animal_reports_updated_at
before update on public.animal_reports
for each row execute function public.set_updated_at();
