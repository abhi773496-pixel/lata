import { supabaseAdmin } from '@/lib/supabase-admin';
export async function GET() {
  const { data, error } = await supabaseAdmin.from('services').select('id,name,description,price,duration_minutes,image_url,is_featured,price_display_type,discounted_price,service_categories(id,name)').eq('is_active', true).order('is_featured', { ascending:false }).order('name');
  if (error) return Response.json({ error:'Unable to load services' }, { status:500 });
  return Response.json({ services:data ?? [] }, { headers:{'Cache-Control':'public, max-age=60'} });
}
