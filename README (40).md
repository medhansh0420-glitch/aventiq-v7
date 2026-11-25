# Discovery worker

The worker is separate from Vercel serverless requests. It reads active sources from Supabase, checks robots.txt and public HTTPS destinations, fetches RSS/Atom, public JSON/API or one approved HTML page, extracts structured candidate fields with OpenAI, verifies application URLs, detects likely duplicates and stores candidate records/logs.

All new records remain `pending_review` unless a trusted administrator explicitly enables `auto_publish_enabled` and every mandatory field, URL and duplicate gate passes. Missing deadlines, missing application URLs, failed verification or duplicate candidates always block auto-publishing.

Run locally:
```bash
pip install -r workers/requirements.txt
python -m workers.run_worker
```

GitHub Actions workflow: `.github/workflows/aventiq-discovery.yml`. Configure repository Actions secrets `NEXT_PUBLIC_SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and `OPENAI_API_KEY`. Add only approved public source URLs. Do not put the service-role or OpenAI key in Vercel client variables or commit them to Git.
