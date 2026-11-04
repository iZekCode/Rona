begin;
select plan(18);

-- Two users, each with a profile, a painting and its stats.
insert into auth.users (id, is_anonymous) values
    ('00000000-0000-0000-0000-0000000000a1', true),
    ('00000000-0000-0000-0000-0000000000a2', true);
insert into public.profiles (id, consented_at, consent_version) values
    ('00000000-0000-0000-0000-0000000000a1', now(), 1),
    ('00000000-0000-0000-0000-0000000000a2', now(), 1);
insert into public.paintings (id, user_id, painted_at, image_path) values
    ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000a1', now(), '00000000-0000-0000-0000-0000000000a1/1.png'),
    ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000000a2', now(), '00000000-0000-0000-0000-0000000000a2/2.png'),
    ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-0000000000a2', now(), '00000000-0000-0000-0000-0000000000a2/5.png');
insert into public.painting_stats (painting_id, user_id, schema_version, stats) values
    ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000a1', 1, '{}'),
    ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000000a2', 1, '{}');

-- From here on we act as user A.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);

select is((select count(*) from public.profiles), 1::bigint, 'A sees only their own profile');
select is((select count(*) from public.paintings), 1::bigint, 'A sees only their own painting');
select is((select count(*) from public.painting_stats), 1::bigint, 'A sees only their own stats');

select lives_ok(
    $$insert into public.paintings (id, user_id, painted_at, image_path)
      values ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-0000000000a1', now(), 'a1/3.png')$$,
    'A can insert a painting for themselves');
select throws_ok(
    $$insert into public.paintings (id, user_id, painted_at, image_path)
      values ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-0000000000a2', now(), 'a2/4.png')$$,
    '42501', null, 'A cannot insert a painting for B');
select is_empty(
    $$update public.paintings set template_id = 'x' where id = '10000000-0000-0000-0000-000000000002' returning id$$,
    'A cannot update the painting of B');
select throws_ok(
    $$update public.paintings set user_id = '00000000-0000-0000-0000-0000000000a2' where id = '10000000-0000-0000-0000-000000000001'$$,
    '42501', null, 'A cannot hand a painting over to B');
select isnt_empty(
    $$update public.paintings set deleted_at = now() where id = '10000000-0000-0000-0000-000000000001' returning id$$,
    'A can tombstone their own painting');
select is_empty(
    $$delete from public.profiles where id = '00000000-0000-0000-0000-0000000000a1' returning id$$,
    'A cannot delete their own profile through the API');

select throws_ok(
    $$insert into public.painting_stats (painting_id, user_id, schema_version, stats)
      values ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000000a2', 1, '{}')$$,
    '42501', null, 'A cannot insert stats as B');
select throws_ok(
    $$insert into public.painting_stats (painting_id, user_id, schema_version, stats)
      values ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-0000000000a1', 1, '{}')$$,
    '23503', null, 'A cannot attach stats to the painting of B');

-- Storage: the first folder of the object path must be the caller id.
select lives_ok(
    $$insert into storage.objects (bucket_id, name) values ('paintings', '00000000-0000-0000-0000-0000000000a1/1.png')$$,
    'A can upload into their own folder');
select throws_ok(
    $$insert into storage.objects (bucket_id, name) values ('paintings', '00000000-0000-0000-0000-0000000000a2/1.png')$$,
    '42501', null, 'A cannot upload into the folder of B');

-- Now user B: sees only their own data and cannot reach A's files.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a2","role":"authenticated"}', true);
select is((select count(*) from public.paintings), 2::bigint, 'B sees only their own paintings');
select is_empty(
    $$select 1 from storage.objects where bucket_id = 'paintings' and name like '00000000-0000-0000-0000-0000000000a1/%'$$,
    'B cannot see the files of A');

-- A visitor who is not signed in gets nothing.
set local role anon;
select is((select count(*) from public.paintings), 0::bigint, 'anon sees no paintings');

-- Back to the superuser: the bucket is private, and deleting a user removes all their rows.
reset role;
select is((select public from storage.buckets where id = 'paintings'), false, 'the paintings bucket is private');
delete from auth.users where id = '00000000-0000-0000-0000-0000000000a1';
select is(
    (select count(*) from public.profiles p, public.paintings g, public.painting_stats s
      where p.id = '00000000-0000-0000-0000-0000000000a1'
         or g.user_id = '00000000-0000-0000-0000-0000000000a1'
         or s.user_id = '00000000-0000-0000-0000-0000000000a1'),
    0::bigint, 'deleting a user removes their profile, paintings and stats');

select * from finish();
rollback;
