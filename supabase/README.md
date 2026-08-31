# Supabase

This directory tracks the database structure for Teatechnology.

## Baseline strategy

The production database already had migration history before this folder was committed to GitHub. To avoid replaying old migrations against production, the original migration versions are preserved here.

- `20260831201348_initialize_teatechnology_cms.sql` is a **current-schema baseline** that can recreate the database structure from scratch.
- Later historical migration files are intentionally no-op placeholders because their final effects are already folded into the baseline.
- Existing production data (including repair price rows) is **not** stored in migrations.
- Supabase-managed system event triggers are intentionally excluded.

## Production safety

Keep **Deploy to production** disabled until this migration set has been reviewed and, ideally, tested with a local Supabase instance or a preview branch.

Future schema changes should be added as new timestamped migration files rather than editing the historical baseline.
