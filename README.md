# SILVER BEAUTY PARLOUR — Fresh GitHub + Render Package

Production-ready Next.js application for SILVER BEAUTY PARLOUR, Udaipur.

## Stack
- Next.js 15.5.7
- React 19.1.0
- TypeScript 5.7.3
- Tailwind CSS 3.4.17
- Supabase PostgreSQL/Auth
- Render Node Web Service
- Razorpay server-side payment verification/webhook
- WhatsApp click-to-chat fallback

## Important fixes in this package
- `lib/validation.ts` is included.
- `tsconfig.json` contains the correct `@/*` path alias.
- All TypeScript include globs are correct.
- Dependency versions are pinned instead of `latest`.
- Old TypeScript build cache (`tsconfig.tsbuildinfo`) is removed.
- Render build/start commands are defined in `render.yaml`.

## Fresh GitHub upload
1. Create a clean repository or remove the old source files from the target repository.
2. Extract this ZIP on your computer.
3. Upload the **contents of this folder** to the repository root, not the ZIP file itself.
4. Commit to the `main` branch.
5. Confirm that the repository root contains `app`, `lib`, `supabase`, `package.json`, `tsconfig.json`, and `render.yaml`.

## Render
Build command:
`npm install --no-audit --no-fund && npm run build`

Start command:
`npm start`

Health check:
`/api/health`

## Environment variables
Set these in Render:
- `NODE_ENV=production`
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `NEXT_PUBLIC_SITE_URL`
- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `RAZORPAY_WEBHOOK_SECRET`

Never put the Supabase service-role key or Razorpay secret in GitHub.

## Supabase
Run `supabase/schema.sql` in the Supabase SQL Editor once for a fresh database.

## Admin
Create the admin login user in Supabase Auth, then add the same Auth user UUID to `admin_users` with the required role as described by the schema.
