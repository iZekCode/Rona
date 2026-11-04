import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "@supabase/supabase-js";
import { removeUserFiles } from "../_shared/storage.ts";

// Deletes the caller's account: first their Storage files (they do not cascade from the database),
// then the auth user, which removes the profile, paintings and stats through the foreign keys.
Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) {
    return new Response("Unauthorized", { status: 401 });
  }

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });

  // The user id comes from the verified token, never from the request body.
  const { data: { user }, error: userError } = await admin.auth.getUser(token);
  if (userError || !user) {
    return new Response("Unauthorized", { status: 401 });
  }

  const filesError = await removeUserFiles(admin, user.id);
  if (filesError) {
    return new Response(filesError, { status: 500 });
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) {
    return new Response("Could not delete user", { status: 500 });
  }

  return new Response(null, { status: 204 });
});
