-- Discovery-pET - Admin moderation policies

-- Helper function to check if the current user is admin.
create or replace function public.is_admin()
returns boolean as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'admin'
  );
$$ language sql stable security definer;

-- Allow admins to read all flags.
create policy "Admins can read all flags"
on public.report_flags
for select
to authenticated
using (public.is_admin());

-- Allow admins to update flags.
create policy "Admins can update flags"
on public.report_flags
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Allow admins to update any report for moderation purposes.
create policy "Admins can update any report"
on public.animal_reports
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Optional: allow admins to read all reports, even hidden ones.
create policy "Admins can read all reports"
on public.animal_reports
for select
to authenticated
using (public.is_admin());
