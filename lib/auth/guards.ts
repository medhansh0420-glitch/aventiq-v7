import { createSupabaseServerClient } from '@/lib/supabase/server';

export async function requireUser() {
  const db = await createSupabaseServerClient();
  const { data: { user }, error } = await db.auth.getUser();
  if (error || !user) return { db, user: null, response: Response.json({ error: 'Authentication required' }, { status: 401 }) };
  return { db, user, response: null };
}

export async function requireStaff() {
  const result = await requireUser();
  if (result.response || !result.user) return result;
  const { data: profile } = await result.db.from('profiles').select('role').eq('id', result.user.id).maybeSingle();
  if (!profile || !['admin','moderator'].includes(profile.role)) return { ...result, response: Response.json({ error: 'Staff access required' }, { status: 403 }) };
  return result;
}
