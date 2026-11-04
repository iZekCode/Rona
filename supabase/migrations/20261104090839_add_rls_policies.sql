-- profiles: a user can read, create and update only their own row; deleting goes through delete-account.
create policy "profiles_select_own" on public.profiles
    for select to authenticated
    using (id = (select auth.uid()));

create policy "profiles_insert_own" on public.profiles
    for insert to authenticated
    with check (id = (select auth.uid()));

create policy "profiles_update_own" on public.profiles
    for update to authenticated
    using (id = (select auth.uid()))
    with check (id = (select auth.uid()));

-- paintings: a user has full access to their own rows only.
create policy "paintings_select_own" on public.paintings
    for select to authenticated
    using (user_id = (select auth.uid()));

create policy "paintings_insert_own" on public.paintings
    for insert to authenticated
    with check (user_id = (select auth.uid()));

create policy "paintings_update_own" on public.paintings
    for update to authenticated
    using (user_id = (select auth.uid()))
    with check (user_id = (select auth.uid()));

create policy "paintings_delete_own" on public.paintings
    for delete to authenticated
    using (user_id = (select auth.uid()));

-- painting_stats: same rule, and the composite foreign key already ties each row to its painting's owner.
create policy "painting_stats_select_own" on public.painting_stats
    for select to authenticated
    using (user_id = (select auth.uid()));

create policy "painting_stats_insert_own" on public.painting_stats
    for insert to authenticated
    with check (user_id = (select auth.uid()));

create policy "painting_stats_update_own" on public.painting_stats
    for update to authenticated
    using (user_id = (select auth.uid()))
    with check (user_id = (select auth.uid()));

create policy "painting_stats_delete_own" on public.painting_stats
    for delete to authenticated
    using (user_id = (select auth.uid()));