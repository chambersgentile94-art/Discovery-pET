-- Discovery-pET - Fix RLS evaluation permissions for private admin helper

-- RLS policies use private.is_admin(). Authenticated users need permission to
-- resolve the private schema and execute the helper while PostgreSQL evaluates
-- the policy. This does not expose private tables or data.

grant usage on schema private to authenticated;
grant execute on function private.is_admin() to authenticated;

-- Keep signup trigger helper private and unavailable from API roles.
revoke execute on function private.handle_new_user_profile() from anon, authenticated;

-- Keep trigger helper unavailable from RPC/API roles.
revoke execute on function public.set_updated_at() from anon, authenticated;

-- Keep legacy public admin helper unavailable from API roles if it still exists.
do $$
begin
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'is_admin'
  ) then
    revoke execute on function public.is_admin() from public, anon, authenticated;
  end if;
end $$;
