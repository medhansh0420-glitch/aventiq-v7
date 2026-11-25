# AventIQ V6 implementation status

## Implemented in this project ZIP
- Preserved the existing V5 Next.js App Router project and all 1,055 `opportunities.ts` records.
- Premium editorial UI, sticky navigation, responsive layouts, scroll reveal and reduced-motion handling.
- Supabase SSR browser/server clients, saved opportunities, recipient-private notifications and role-checked server API helpers.
- Public-safe worldwide profile directory, profile editor and member profile pages.
- Consultation request/list/state APIs with an adult-verification gate. Private meeting URLs are stored on participant-only rows and are not exposed by public APIs.
- Verified mentor reviews: database trigger requires a completed consultation, one review per consultation, and pending moderation before public visibility.
- Global community posts/comments with pending moderation, reporting API and staff moderation queue.
- Admin overview, opportunity approval/rejection/publishing endpoints, source management, scan queue/history and system settings APIs.
- RSS/Atom worker, OpenAI structured extraction, URL verification with public-HTTPS/private-network checks, duplicate candidate detection and conservative confidence scoring.
- Scheduled GitHub Actions worker workflow (requires repository secrets and approved source records).
- Idempotent script to import exactly 1,055 legacy opportunity rows into Supabase as `pending_review`.

## Requires external setup before it operates across users
- Apply both SQL migrations in order in the Supabase SQL Editor.
- Configure Supabase Auth redirect URLs and environment variables in Vercel.
- Import the 1,055 legacy rows with `npm run import:opportunities` from a trusted local environment.
- Create an initial admin by changing the `profiles.role` value for the chosen Auth user from the Supabase SQL Editor. Never expose service-role credentials in the browser.
- Add approved RSS/Atom sources from the admin source API/UI and configure GitHub repository secrets for the scheduled worker.
- Configure `OPENAI_API_KEY` as a GitHub Actions secret for AI extraction.
- Worker auto-publishing is disabled by default. Enable it only after source quality and extraction output are audited; mandatory missing fields and duplicate candidates always block auto-publishing.
- Payment processing is not enabled. The database records a safe integration boundary; an adult platform owner must configure a merchant account, legal terms, refunds, tax handling and payment provider webhooks before accepting payments.
- Video meetings use private participant-only Jitsi room links. For production, configure an authenticated meeting provider if stronger access control is required.

## Honest test status
- This source ZIP has not been connected to a live Supabase project and no real account/consultation/review data exists yet.
- The 1,055 legacy rows remain preserved in the local TypeScript dataset and are imported only when the owner runs the explicit import script.
- Do not claim public reviews, scheduled discovery, payments or global profiles are live until credentials, migrations and worker hosting are configured and verified.
