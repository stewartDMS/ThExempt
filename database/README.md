# ThExempt Database

## Quick Start

### 1. Run the schema in Supabase SQL Editor

The single source of truth for the database schema is **`supabase/schema.sql`**.

Copy and paste the contents of that file into the Supabase SQL Editor and run it.
See [`supabase/MIGRATION_GUIDE.md`](../supabase/MIGRATION_GUIDE.md) for full step-by-step instructions, including how to apply the schema to an existing project without losing data.

### 2. (Optional) Load seed data for local development

Edit `seed.sql` and replace `USER_ID_1`, `USER_ID_2`, `USER_ID_3` with real UUIDs from `auth.users`, then run it in the Supabase SQL Editor.

### 3. Verify

```sql
SELECT schemaname, COUNT(*)
FROM pg_tables
WHERE schemaname = 'public'
GROUP BY schemaname;
```

## Files

| File | Description |
|------|-------------|
| `seed.sql` | Test data for local development |
| `migrations/README.md` | Migration guide and troubleshooting |

## Schema Location

The complete database schema lives in **[`supabase/schema.sql`](../supabase/schema.sql)** (single source of truth).

## Documentation

See [`supabase/MIGRATION_GUIDE.md`](../supabase/MIGRATION_GUIDE.md) for migration instructions.
See [`docs/DATABASE.md`](../docs/DATABASE.md) for full documentation including schema diagrams, common queries, and performance tips.
