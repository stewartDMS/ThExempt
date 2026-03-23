# ThExempt Database

> ⚠️ **This directory is no longer the canonical location for schema files.**
>
> The database schema has been consolidated into a single source of truth:
>
> **[`supabase/schema.sql`](../supabase/schema.sql)**

---

## Quick Start

### 1. Run the schema in Supabase SQL Editor

Copy and paste the contents of [`supabase/schema.sql`](../supabase/schema.sql)
into the Supabase SQL Editor and run it.

### 2. (Optional) Load seed data for local development

Copy and paste [`supabase/seed.sql`](../supabase/seed.sql) into the SQL
Editor, replace `USER_ID_1`, `USER_ID_2`, `USER_ID_3` with real UUIDs from
`auth.users`, then run it.

### 3. Verify

```sql
SELECT schemaname, COUNT(*)
FROM pg_tables
WHERE schemaname = 'public'
GROUP BY schemaname;
-- Expected: 27 tables
```

## Files

| File | Description |
|------|-------------|
| [`supabase/schema.sql`](../supabase/schema.sql) | **Canonical unified schema** — single source of truth |
| [`supabase/seed.sql`](../supabase/seed.sql) | Sample data for local development |
| [`supabase/MIGRATION_GUIDE.md`](../supabase/MIGRATION_GUIDE.md) | Migration, backup, rollback, and verification guide |

## Documentation

See [`docs/DATABASE.md`](../docs/DATABASE.md) for full documentation including
schema diagrams, common queries, and performance tips.
