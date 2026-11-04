# Cleanup job (chunk A6)

The `cleanup` edge function does two things on each call, in this order:

1. Purges tombstones: paintings whose `deleted_at` is older than 90 days. It removes the PNG from Storage first, then the row (stats go with it through the cascade).
2. Deletes abandoned anonymous users: `is_anonymous`, created more than 30 days ago, and no painting row at all (not even a deleted one). Their Storage folder is cleared first, because an upload that never got its row can leave an orphan file. The candidates come from `public.abandoned_anonymous_users(cutoff, max_rows)`, which only the service role can call.

It accepts only `POST` with the service role key as bearer token and answers `{ purgedPaintings, deletedUsers, error }`. A failure stops that step and the next run retries it. The thresholds are constants at the top of `supabase/functions/cleanup/index.ts`.

## Things to keep in mind

- Tombstones are kept for 90 days so that a device that was offline for a long time cannot bring a deleted painting back through last-write-wins sync. If the sync engine (E4) allows longer offline periods, raise the constant.
- A user who only ever had paintings that were purged becomes an abandoned user on the same run and is deleted too. The app (E1) must handle a session whose user no longer exists by signing in anonymously again.
- The abandoned-user rule looks at `created_at`, not at activity. A child who uses the app for weeks without saving a painting is deleted too and starts again with a new anonymous user. Nothing is lost, but revisit the rule if that turns out to be common.

## Scheduling on the hosted project

The local stack does not run it on a schedule. Once the hosted project exists, enable the `pg_cron` and `pg_net` extensions, store the project URL and the service role key in Vault, and schedule a daily call (run once in the SQL editor):

```sql
select vault.create_secret('https://<project-ref>.supabase.co', 'project_url');
select vault.create_secret('<service role key>', 'service_role_key');

select cron.schedule('cleanup-daily', '0 3 * * *', $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url') || '/functions/v1/cleanup',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key')
    )
  );
$$);
```

The function compares the bearer token with its own `SUPABASE_SERVICE_ROLE_KEY`, so check on the hosted project that the key stored in Vault is the same value.
