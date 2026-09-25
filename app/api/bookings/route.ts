import { supabaseAdmin } from '@/lib/supabase-admin';
import { normalizePhone, validIndianPhone, isPastDate, jsonError } from '@/lib/validation';

export async function POST(req: Request) {
  try {
    const b = await req.json();
    const phone = normalizePhone(String(b.phone || ''));
    if (!b.name || String(b.name).trim().length < 2 || !validIndianPhone(phone) || !b.date || !b.time || !Array.isArray(b.service_ids) || !b.service_ids.length) return jsonError('Please enter valid details and select at least one service.');
    if (isPastDate(b.date)) return jsonError('Please choose a future date.');
    const { data: holiday } = await supabaseAdmin.from('salon_holidays').select('reason').eq('date', b.date).maybeSingle();
    if (holiday) return jsonError(`The salon is closed on this date${holiday.reason ? `: ${holiday.reason}` : ''}.`);
    const ids = [...new Set(b.service_ids.map(String))];
    const { data: services, error: se } = await supabaseAdmin.from('services').select('id,name,price,duration_minutes').in('id', ids).eq('is_active', true);
    if (se || !services || services.length !== ids.length) return jsonError('One or more selected services are unavailable.');
    const total = services.reduce((a,s)=>a+Number(s.price||0),0), duration = services.reduce((a,s)=>a+Number(s.duration_minutes||0),0);
    let { data: customer } = await supabaseAdmin.from('customers').select('id').eq('phone', phone).maybeSingle();
    if (!customer) { const r=await supabaseAdmin.from('customers').insert({name:String(b.name).trim(),phone}).select('id').single(); if(r.error) throw r.error; customer=r.data; }
    else { await supabaseAdmin.from('customers').update({name:String(b.name).trim(),updated_at:new Date().toISOString()}).eq('id',customer.id); }
    const { data: created, error } = await supabaseAdmin.rpc('create_pending_appointment', { p_customer_id:customer.id, p_date:b.date, p_time:b.time, p_note:b.note?.trim()||null, p_total:total, p_duration:duration });
    if (error || !created?.appointment_id) throw error || new Error('Appointment creation failed');
    const rows = services.map(s=>({appointment_id:created.appointment_id,service_id:s.id,service_name_snapshot:s.name,price_snapshot:s.price,duration_snapshot:s.duration_minutes}));
    const ar=await supabaseAdmin.from('appointment_services').insert(rows); if(ar.error) throw ar.error;
    await supabaseAdmin.from('payments').insert({appointment_id:created.appointment_id,payment_method:'PAY_AT_SALON',amount:total,status:'PAY_AT_SALON'});
    return Response.json({ appointment_number:created.appointment_number, status:'PENDING_CONFIRMATION', estimated_total:total, estimated_duration:duration });
  } catch { return jsonError('Something went wrong while submitting your appointment request. Please try again or contact the salon on WhatsApp.',500); }
}
