import { supabaseAdmin } from '@/lib/supabase-admin';
export async function GET(){const {data}=await supabaseAdmin.from('salon_settings').select('salon_name,phone,address,opening_time,closing_time,whatsapp_number,currency,booking_settings').limit(1).single();return Response.json({settings:data||null});}
