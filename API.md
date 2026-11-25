# AventIQ API notes

All request bodies are validated with Zod. Authenticated endpoints use Supabase Auth cookies. Admin endpoints verify `profiles.role` on the server and rely on RLS as a second boundary.

Public profile and review endpoints return only explicit safe columns. Private contact information, private meeting URLs, payment metadata and private messages are not included in public response shapes.

Review submission requires `consultation_id`, `mentor_id`, `rating` (1–5) and `body` (10–2,000 chars). The database trigger independently checks that the consultation is completed and belongs to the reviewer/mentor pair. Public review reads include only `approved` records.

Community posts/comments are inserted as `pending`; only staff moderation can publish them. Reports are private to the reporter and staff.

Discovery scans are queued in `processing_jobs`. The Python worker must be running for queued scans to execute. Worker candidates are never auto-published unless the owner enables the setting and all mandatory verification/confidence gates pass.
