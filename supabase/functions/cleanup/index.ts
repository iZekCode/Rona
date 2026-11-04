import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "@supabase/supabase-js";
import { BUCKET, removeUserFiles } from "../_shared/storage.ts";

// A device that was offline longer than this could bring a deleted painting back, so keep tombstones long.
const TOMBSTONE_DAYS = 90;
const ABANDONED_USER_DAYS = 30;
const BATCH_SIZE = 100;
const MAX_BATCHES = 50;

const daysAgo = (days: number) => new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

// Called on a schedule with the service role key: purges old tombstones, then deletes abandoned anonymous users.
Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (token !== serviceKey) {
    return new Response("Unauthorized", { status: 401 });
  }

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, serviceKey, { auth: { persistSession: false } });

  const purged = await purgeTombstones(admin);
  const users = await deleteAbandonedUsers(admin);
  const failed = purged.error ?? users.error;

  return Response.json(
    { purgedPaintings: purged.count, deletedUsers: users.count, error: failed ?? null },
    { status: failed ? 500 : 200 },
  );
});

type Result = { count: number; error?: string };

// Files go first, so a failure leaves the rows in place and the next run retries them.
async function purgeTombstones(admin: ReturnType<typeof createClient>): Promise<Result> {
  let count = 0;
  for (let batch = 0; batch < MAX_BATCHES; batch++) {
    const { data: rows, error } = await admin
      .from("paintings")
      .select("id, image_path")
      .lt("deleted_at", daysAgo(TOMBSTONE_DAYS))
      .limit(BATCH_SIZE);
    if (error) return { count, error: "Could not list tombstones" };
    if (!rows || rows.length === 0) break;

    const { error: removeError } = await admin.storage.from(BUCKET).remove(rows.map((r) => r.image_path));
    if (removeError) return { count, error: "Could not remove painting files" };

    const { error: deleteError } = await admin.from("paintings").delete().in("id", rows.map((r) => r.id));
    if (deleteError) return { count, error: "Could not delete tombstones" };
    count += rows.length;
  }
  return { count };
}

// A user who never saved a painting can still have an orphaned upload, so their folder is cleared too.
async function deleteAbandonedUsers(admin: ReturnType<typeof createClient>): Promise<Result> {
  let count = 0;
  for (let batch = 0; batch < MAX_BATCHES; batch++) {
    const { data: ids, error } = await admin.rpc("abandoned_anonymous_users", {
      cutoff: daysAgo(ABANDONED_USER_DAYS),
      max_rows: BATCH_SIZE,
    });
    if (error) return { count, error: "Could not list abandoned users" };
    if (!ids || ids.length === 0) break;

    let deletedInBatch = 0;
    for (const id of ids as string[]) {
      if (await removeUserFiles(admin, id)) continue;
      const { error: deleteError } = await admin.auth.admin.deleteUser(id);
      if (!deleteError) deletedInBatch++;
    }
    count += deletedInBatch;
    if (deletedInBatch === 0) return { count, error: "No abandoned user could be deleted" };
  }
  return { count };
}
