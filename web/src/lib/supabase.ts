import { createClient } from "@supabase/supabase-js";

// Same public credentials the iOS app uses (publishable / anon key — safe in client).
const SUPABASE_URL = "https://qpawgtxbjatyfngvaayy.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_TpvrAYhloJQ7MNg7JJ6csg_kimv9HG1";

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: false,
  },
});
