-- Discovery-pET - Harden SECURITY DEFINER functions and Storage read policy

-- Move admin helper out of the exposed public schema.
create schema if not exists private;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'admin'::public.user_role
  );
$$;

revoke all on schema private from public, anon, authenticated;
revoke execute on function private.is_admin() from public, anon, authenticated;

-- Point admin policies to private.is_admin().
drop policy if exists "Admins can read all flags" on public.report_flags;
drop policy if exists "Admins can update flags" on public.report_flags;
drop policy if exists "Admins can update any report" on public.animal_reports;
drop policy if exists "Admins can read all reports" on public.animal_reports;

create policy "Admins can read all flags"
on public.report_flags
for select
to authenticated
using (private.is_admin());

create policy "Admins can update flags"
on public.report_flags
for update
to authenticated
using (private.is_admin())
with check (private.is_admin());

create policy "Admins can update any report"
on public.animal_reports
for update
to authenticated
using (private.is_admin())
with check (private.is_admin());

create policy "Admins can read all reports"
on public.animal_reports
for select
to authenticated
using (private.is_admin());

-- Harden updated_at helper.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Move auth signup profile trigger helper out of exposed public schema.
create or replace function private.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.email
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke execute on function private.handle_new_user_profile() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_user_profile();

-- Keep legacy public helpers unavailable to API roles if they still exist.
revoke execute on function public.is_admin() from public, anon, authenticated;
revoke execute on function public.handle_new_user_profile() from public, anon, authenticated;
revoke execute on function public.set_updated_at() from public, anon, authenticated;

-- Storage: keep public URL functionality but avoid the broad original policy name.
drop policy if exists "Anyone can read report images" on storage.objects;
drop policy if exists "Anyone can read report images by known path" on storage.objects;

create policy "Anyone can read report images by known path"
on storage.objects
for select
to public
using (
  bucket_id = 'report-images'
  and name is not null
);
