# AventIQ V6 setup

## 1. Local install and checks
```bash
npm install
npm run typecheck
npm run build
```

## 2. Supabase setup
1. Create a Supabase project.
2. Run `supabase/migrations/202611220001_initial_schema.sql`.
3. Run `supabase/migrations/202611230002_global_platform.sql`.
4. Enable Email Auth and configure allowed redirect URLs for localhost and your Vercel domain.
5. Set the public URL and anon/publishable key in `.env.local` and Vercel environment variables.
6. Keep the service-role key only in a trusted server/worker secret store.

## 3. Initial admin
1. Sign up using `/auth`.
2. In Supabase SQL Editor, locate the user's UUID in Authentication → Users.
3. As the project owner, run `update public.profiles set role='admin' where id='YOUR_AUTH_USER_UUID';`.
4. Open `/admin`. Do not let users choose admin/moderator roles in the public profile editor.

## 4. Import the 1,055 legacy records
Run locally in a trusted terminal with Supabase credentials set as environment variables:
```bash
npm run import:opportunities
```
The script stops unless the source contains exactly 1,055 rows. It upserts by `legacy_id` and marks every imported row `pending_review`; no old deadline or verification label is silently treated as current. Review and publish through the admin workflow.

## 5. Vercel
- Import the GitHub repository.
- Framework: Next.js.
- Root Directory: `./` (the folder containing `package.json` and `app/`).
- Add `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
- Never add `SUPABASE_SERVICE_ROLE_KEY` or `OPENAI_API_KEY` as `NEXT_PUBLIC_` variables.

## 6. Discovery worker
Add these GitHub repository Actions secrets: `NEXT_PUBLIC_SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `OPENAI_API_KEY`. Apply the workflow `.github/workflows/aventiq-discovery.yml`; it runs every six hours and can also be manually dispatched. Add only approved HTTPS RSS/Atom sources. The worker runs separately from Vercel, respects public-network URL checks and stores candidates for review. OpenAI extraction is not a substitute for human review.

## 7. Reviews and consultation completion
One-to-one consultations are gated to accounts independently verified as adults (18+). The private `profiles.age_verified_adult` flag defaults to false, is never exposed publicly and cannot be set by the user. A trusted owner must verify age through an appropriate process before setting this flag, then run `update public.profiles set age_verified_adult=true where id='VERIFIED_AUTH_USER_UUID';` from the owner SQL session. Do not enable unsupervised one-to-one sessions for minors; provide a guardian-supervised safeguarding workflow before expanding access. Verified adult students can request a consultation from a public mentor profile. Mentors accept/decline. A staff member verifies completion using the authenticated admin workflow/API. Only the student who completed that consultation can submit one review. Reviews are pending until a moderator approves them. Public APIs show approved reviews only.

## 8. API routes
- `GET/POST /api/profiles`, `GET /api/profiles/{id}`
- `GET/POST /api/reviews`
- `GET/POST /api/community`, `POST /api/community/comments`
- `GET/POST /api/consultations`, `PATCH /api/consultations/{id}`
- `POST /api/reports`
- Admin: `/api/admin/overview`, `/api/admin/moderation`, `/api/admin/opportunities`, `/api/admin/sources`, `/api/admin/scans`, `/api/admin/scans/trigger`, `/api/admin/settings`
- `GET /api/opportunities`, `GET /api/opportunities/{id}`, `GET /api/health`

## 9. Payments
Payment collection is deliberately disabled in this build. Before enabling money movement, the platform owner must choose a supported provider, configure signed webhooks and idempotency, and review legal, tax, age, refund and payout requirements. Do not store card details in AventIQ.
