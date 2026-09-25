import { createSupabaseServerClient } from './supabase-server';
import { supabaseAdmin } from './supabase-admin';

export async function requireAdmin(roles?: string[]) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { user: null, admin: null, error: 'Unauthorized' as const };
  const { data: admin } = await supabaseAdmin.from('admin_users').select('*').eq('id', user.id).single();
  if (!admin || (roles && !roles.includes(admin.role))) return { user: null, admin: null, error: 'Forbidden' as const };
  return { user, admin, error: null };
}
