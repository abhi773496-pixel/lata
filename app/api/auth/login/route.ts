import { createSupabaseServerClient } from '@/lib/supabase-server';
export async function POST(req: Request) {
  const { email, password } = await req.json();
  if (!email || !password) return Response.json({ error: 'Email and password are required.' }, { status: 400 });
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return Response.json({ error: 'Invalid admin credentials.' }, { status: 401 });
  return Response.json({ ok: true });
}
