import type { SupabaseClient } from "@supabase/supabase-js";

export const BUCKET = "paintings";

const PAGE_SIZE = 100;
const MAX_PAGES = 1000;

// Removes every file in a user's folder; returns an error message, or null when the folder is empty.
export async function removeUserFiles(admin: SupabaseClient, userId: string): Promise<string | null> {
  const files = admin.storage.from(BUCKET);
  for (let page = 0; page < MAX_PAGES; page++) {
    const { data: objects, error: listError } = await files.list(userId, { limit: PAGE_SIZE });
    if (listError) return "Could not list files";
    if (!objects || objects.length === 0) return null;

    const { data: removed, error: removeError } = await files.remove(objects.map((o) => `${userId}/${o.name}`));
    if (removeError || !removed || removed.length === 0) return "Could not remove files";
  }
  return "Too many files";
}
