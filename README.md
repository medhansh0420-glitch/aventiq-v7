# AventIQ V6 — global opportunity & mentorship platform

AventIQ keeps the existing V5 Next.js App Router UI and its complete 1,055-record opportunity collection while adding a Supabase-backed platform foundation, secure APIs, moderation workflows and a separately scheduled Python discovery worker.

## Root structure

The ZIP is intended to be extracted directly into the GitHub repository root. Do not nest the project under another folder.

```text
package.json
app/
  page.tsx
  layout.tsx
  globals.css
  auth/page.tsx
  profile/page.tsx
  consultations/page.tsx
  notifications/page.tsx
  admin/page.tsx
  api/...
components at root: DiscoverSection.tsx, MentorMarketplace.tsx, ConsultationHub.tsx
lib/
supabase/migrations/
workers/
scripts/import-opportunities.ts
opportunities.ts
```

Vercel settings: Framework **Next.js**, Root Directory `./`, build `npm run build`, install `npm install`.

## Implemented foundation

- Premium editorial scroll-led public site, responsive layouts, sticky navigation and reduced-motion support.
- Existing `opportunities.ts` preserved with exactly 1,055 records; import script validates the count and imports by legacy ID as `pending_review`.
- Supabase Auth, public profile editor and global directory with explicit public visibility.
- Public profile APIs return only safe profile fields; email, phone, payment details and private consultation links are not exposed publicly.
- Mentor marketplace uses real public profiles, approved review averages/counts and reviewer profile links.
- Consultation request/accept/decline/list workflow; private room URLs are participant-only. Adult verification is required for one-to-one sessions.
- Review submission requires a database-verified completed consultation and enters moderation; no fabricated reviews or ratings.
- Public community posts/comments, reporting, database-backed rate limits and staff moderation.
- Admin overview, opportunity review/publishing, source management, scan history, duplicate decisions, member role management, consultation completion verification and system publishing controls.
- Python worker supports approved RSS/Atom feeds, public JSON/API endpoints and public HTML pages, with robots checks, HTTPS/public-network checks, OpenAI structured extraction, URL verification, duplicate candidates and conservative confidence gates.
- GitHub Actions schedule runs the worker separately from Vercel when repository secrets and sources are configured.

## Activation required

This is a source-code deliverable, not a live configured production deployment. Before cross-user features work, follow `docs/SETUP.md`:

1. Apply both Supabase migrations in order.
2. Configure Supabase Auth and Vercel public environment variables.
3. Import the 1,055 existing rows with `npm run import:opportunities`. They remain pending review; deadlines and old verification labels are not treated as freshly verified.
4. Create an initial admin using the owner SQL procedure in the setup guide.
5. Verify adult status through a suitable owner-controlled process before enabling one-to-one consultation access. The private `age_verified_adult` field defaults to false and cannot be set by a user.
6. Add approved public sources and configure GitHub Actions secrets for the discovery worker.

Auto-publishing is disabled by default. Payments are deliberately not activated; a platform owner must configure a compliant provider, signed webhooks, refund/tax/payout terms and other safeguards before taking payments.

## Checks

- Python worker syntax compilation: passed.
- Python confidence-gate tests: 3 passed.
- TypeScript/TSX syntax transpilation: 52 files, zero syntax errors.
- Full `npm install`, TypeScript typecheck and Next.js production build could not be completed in this environment because package installation timed out. Run `npm install`, `npm run typecheck` and `npm run build` locally or in Vercel before treating the deployment as build-verified.

See `docs/SETUP.md`, `docs/API.md` and `docs/IMPLEMENTATION_STATUS.md` for setup and limitations.
