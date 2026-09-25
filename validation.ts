export function normalizePhone(input: string) { return input.replace(/\D/g, '').replace(/^91/, '').slice(-10); }
export function validIndianPhone(input: string) { return /^[6-9]\d{9}$/.test(normalizePhone(input)); }
export function isPastDate(date: string) { const today = new Date(); const local = new Date(today.getFullYear(), today.getMonth(), today.getDate()); return new Date(date + 'T00:00:00') < local; }
export function jsonError(message: string, status = 400) { return Response.json({ error: message }, { status }); }
