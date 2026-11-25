# Tests

Run the worker confidence-gate tests:
```bash
PYTHONPATH=. python -m pytest -q tests/python
```

Run TypeScript and production checks after dependencies are installed:
```bash
npm run typecheck
npm run build
```

Integration tests against Supabase require a dedicated test project and are intentionally not run against production data.
