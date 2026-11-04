-- Private bucket for painting PNGs; only PNG files up to 10 MB are accepted.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('paintings', 'paintings', false, 10485760, array['image/png']);

-- Objects live under {user_id}/{painting_id}.png, so the first folder must be the caller's own id.
create policy "paintings_objects_select_own" on storage.objects
    for select to authenticated
    using (bucket_id = 'paintings' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "paintings_objects_insert_own" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'paintings' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "paintings_objects_update_own" on storage.objects
    for update to authenticated
    using (bucket_id = 'paintings' and (storage.foldername(name))[1] = (select auth.uid())::text)
    with check (bucket_id = 'paintings' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "paintings_objects_delete_own" on storage.objects
    for delete to authenticated
    using (bucket_id = 'paintings' and (storage.foldername(name))[1] = (select auth.uid())::text);