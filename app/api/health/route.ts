export async function GET() {
  return Response.json({ ok: true, service: 'silver-beauty-parlour', timestamp: new Date().toISOString() });
}
