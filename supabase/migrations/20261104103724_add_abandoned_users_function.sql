-- Anonymous users created before the cutoff that never saved a painting (not even a deleted one).
create function public.abandoned_anonymous_users(cutoff timestamptz, max_rows int default 100)
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
    select u.id
    from auth.users u
    where u.is_anonymous
      and u.created_at < cutoff
      and not exists (select 1 from public.paintings p where p.user_id = u.id)
    order by u.created_at
    limit max_rows;
$$;

-- It reads auth.users, so only the service role (the cleanup function) may call it.
revoke execute on function public.abandoned_anonymous_users(timestamptz, int) from public, anon, authenticated;
grant execute on function public.abandoned_anonymous_users(timestamptz, int) to service_role;
