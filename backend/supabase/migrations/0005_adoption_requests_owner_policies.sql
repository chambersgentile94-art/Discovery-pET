-- Discovery-pET - Adoption request owner policies

-- Allow report owners to read adoption requests made on their reports.
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

-- Allow report owners to update adoption request status on their reports.
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

-- Optional: prevent duplicated pending requests from same user for same report.
create unique index if not exists idx_adoption_requests_unique_requester_report
on public.adoption_requests(report_id, requester_id);
