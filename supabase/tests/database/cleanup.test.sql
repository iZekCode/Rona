begin;
select plan(7);

-- u1: old anonymous, never painted. u2: old anonymous with a deleted painting. u3: new anonymous.
-- u4: old but signed in with an identity (not anonymous). u5: old anonymous, never painted.
insert into auth.users (id, is_anonymous, created_at) values
    ('00000000-0000-0000-0000-0000000000b1', true, now() - interval '40 days'),
    ('00000000-0000-0000-0000-0000000000b2', true, now() - interval '40 days'),
    ('00000000-0000-0000-0000-0000000000b3', true, now() - interval '1 day'),
    ('00000000-0000-0000-0000-0000000000b4', false, now() - interval '40 days'),
    ('00000000-0000-0000-0000-0000000000b5', true, now() - interval '41 days');
insert into public.profiles (id, consented_at, consent_version)
    select id, now(), 1 from auth.users where id::text like '00000000-0000-0000-0000-0000000000b%';
insert into public.paintings (id, user_id, painted_at, image_path, deleted_at) values
    ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000000b2', now(), 'b2/2.png', now());

select is(
    (select array_agg(id order by id) from public.abandoned_anonymous_users(now() - interval '30 days') as id
      where id::text like '00000000-0000-0000-0000-0000000000b%'),
    array['00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-0000000000b5']::uuid[],
    'only old anonymous users without any painting are returned');

select is(
    (select count(*) from public.abandoned_anonymous_users(now() - interval '30 days') as id where id = '00000000-0000-0000-0000-0000000000b2'),
    0::bigint, 'a user with a deleted painting is kept');
select is(
    (select count(*) from public.abandoned_anonymous_users(now() - interval '30 days') as id where id = '00000000-0000-0000-0000-0000000000b3'),
    0::bigint, 'a recent anonymous user is kept');
select is(
    (select count(*) from public.abandoned_anonymous_users(now() - interval '30 days') as id where id = '00000000-0000-0000-0000-0000000000b4'),
    0::bigint, 'a user with a linked identity is kept');
select is(
    (select count(*) from public.abandoned_anonymous_users(now() - interval '30 days', 1)),
    1::bigint, 'max_rows limits the result');

set local role authenticated;
select throws_ok(
    $$select * from public.abandoned_anonymous_users(now())$$,
    '42501', null, 'a signed-in user cannot call it');
set local role anon;
select throws_ok(
    $$select * from public.abandoned_anonymous_users(now())$$,
    '42501', null, 'anon cannot call it');

select * from finish();
rollback;
