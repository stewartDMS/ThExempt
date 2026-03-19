# ThExempt Database

## Quick Start

### 1. Run the schema in Supabase SQL Editor

Copy and paste the contents of `schema.sql` into the Supabase SQL Editor and run it.

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
| `schema.sql` | Complete production-ready PostgreSQL schema |
| `seed.sql` | Test data for local development |
| `community_schema.sql` | Community discussions and live events schema |
| `migrations/README.md` | Migration guide and troubleshooting |

## Documentation

See [`docs/DATABASE.md`](../docs/DATABASE.md) for full documentation including schema diagrams, common queries, and performance tips.
