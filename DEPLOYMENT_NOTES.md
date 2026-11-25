# AventIQ V6 — V5 Premium UI merge

- V6 API routes, Supabase migrations, workers, opportunity records, auth helpers and backend-connected components are preserved.
- The V5 premium landing-page composition and primary stylesheet are used.
- V6-only styles for auth, admin and community widgets are retained without overriding V5 styles.
- Supabase cookie callback has an explicit `CookieToSet[]` parameter type.
- The project root contains only the intended Next.js `app/` routes. Stray copied `route (n).ts` / `page (n).tsx` files are intentionally excluded.

## Vercel
Set Framework Preset to Next.js and Root Directory to `./`. Add the Supabase environment variables from `.env.example` in Vercel before enabling backend features.
