# SILVER BEAUTY PARLOUR — GitHub + Render Deployment

Production-oriented full-stack salon appointment application for **Silver Beauty Parlour**, Bhopalpura 2nd Street, Udaipur, Rajasthan – 313001.

## Architecture

- Next.js + React + TypeScript
- Tailwind CSS
- Supabase PostgreSQL + Supabase Auth
- Server-only Supabase service-role operations
- Razorpay server-side order/signature/webhook verification
- WhatsApp click-to-chat fallback
- Render Node Web Service
- GitHub source control + GitHub Actions build check

## 1. Put the project on GitHub

From the project root:

```bash
git init
git add .
git commit -m "Initial Silver Beauty Parlour app"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/silver-beauty-parlour.git
git push -u origin main
```

Do **not** commit `.env.local`, API secrets, Supabase service-role keys, Razorpay secrets, or passwords. `.gitignore` already excludes local environment files.

## 2. Create Supabase

1. Create a Supabase project.
2. Open **SQL Editor**.
3. Run `supabase/schema.sql` completely.
4. In **Authentication → Users**, create the owner login email/password.
5. Copy that user's UUID.
6. In SQL Editor, add the owner to `admin_users`:

```sql
insert into public.admin_users (id, name, role)
values ('YOUR_AUTH_USER_UUID', 'Salon Owner', 'OWNER');
```

Use the UUID of the Auth user you actually created.

## 3. Create the Render service

This repository contains `render.yaml`, so Render can use the included configuration.

In Render:

1. **New → Blueprint** or **New → Web Service**.
2. Connect the GitHub repository.
3. If using the Blueprint, Render reads `render.yaml`.
4. Runtime: **Node**.
5. Build command:

```text
npm install --no-audit --no-fund && npm run build
```

6. Start command:

```text
npm start
```

7. Health check:

```text
/api/health
```

8. Enable automatic deploys from the `main` branch.

The included Render blueprint uses the Singapore region and the free plan as a starting point. Change the plan/region in Render if required.

## 4. Render environment variables

Set these in **Render → Environment**. Never put secrets in GitHub source code.

```text
NODE_ENV=production
NEXT_PUBLIC_SUPABASE_URL=https://YOUR-PROJECT.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_SUPABASE_SERVICE_ROLE_KEY
NEXT_PUBLIC_SITE_URL=https://YOUR-RENDER-SERVICE.onrender.com

RAZORPAY_KEY_ID=YOUR_RAZORPAY_KEY_ID
RAZORPAY_KEY_SECRET=YOUR_RAZORPAY_KEY_SECRET
RAZORPAY_WEBHOOK_SECRET=YOUR_RAZORPAY_WEBHOOK_SECRET
```

Razorpay variables may remain unset until online payments are enabled; the app will report that online payment is not configured rather than using fake credentials.

## 5. Verify deployment

After Render finishes deployment, open:

```text
https://YOUR-RENDER-SERVICE.onrender.com/api/health
```

Expected response contains:

```json
{"ok":true,"service":"silver-beauty-parlour"}
```

Then test:

- `/`
- `/book`
- `/track`
- `/admin`

## 6. Admin login

Open `/admin` and sign in with the Supabase Auth owner account created earlier.

The browser does not receive the Supabase service-role key. Admin API routes verify the signed-in user and check `admin_users` role before accessing private management data.

## 7. Razorpay webhook

When Razorpay is configured, create a webhook pointing to:

```text
https://YOUR-RENDER-SERVICE.onrender.com/api/payments/webhook
```

Use the webhook secret stored in Render as `RAZORPAY_WEBHOOK_SECRET`.

The server verifies the webhook signature before changing payment state.

## 8. WhatsApp

The fallback uses a WhatsApp click-to-chat URL, so the booking workflow does not depend on a WhatsApp API credential.

The salon WhatsApp number is configured through the admin/salon settings. No phone number is hard-coded.

For automated WhatsApp Business messages, add the provider integration/credentials server-side later; never put the access token in browser code.

## 9. GitHub → Render deployment flow

```text
Your Android/PC
      ↓ git push
GitHub main
      ↓ automatic deploy
Render
      ↓ npm install
      ↓ npm run build
      ↓ npm start
Live Silver Beauty Parlour website
      ↓
Supabase PostgreSQL/Auth
```

Every new push to `main` can trigger a Render deployment when Auto Deploy is enabled.

## 10. Database/business rules

The application preserves the important business workflow:

- Customer-selected date/time is a preference only.
- New requests start as `PENDING_CONFIRMATION`.
- Admin selects the actual confirmed date/time and staff member.
- Server checks holidays, staff leave, working hours and overlapping confirmed appointments.
- Cancelled appointments are retained.
- Appointment status and payment status are separate.
- Service price/name/duration snapshots are stored with appointments.
- Customer tracking requires appointment ID + matching mobile number.

## 11. Before real launch

Test the complete flow with a real Supabase project:

1. Customer creates a request.
2. Admin receives it in `/admin`.
3. Admin selects staff/date/time and confirms.
4. Customer tracks the appointment.
5. Customer requests cancellation/rescheduling.
6. Test conflicting staff appointments.
7. Test salon holiday and staff leave.
8. Test Razorpay in test mode before live mode.
9. Test Render deployment after every major schema/API change.

Do not use fake business credentials or real customer information in demo/testing records.
