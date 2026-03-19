# Database Migrations

## Initial Setup

The database schema is maintained in a single file:

```
supabase/schema.sql
```

For full step-by-step instructions (including migrating an existing database without data loss), see **[`supabase/MIGRATION_GUIDE.md`](../../supabase/MIGRATION_GUIDE.md)**.

### 1. Run the schema

In Supabase SQL Editor, copy/paste the full contents of `supabase/schema.sql` and click **Run**.

### 2. Load seed data (optional, for testing)

Replace `USER_ID_1`, `USER_ID_2`, `USER_ID_3` with real UUIDs from `auth.users`:

```sql
-- Copy/paste contents of database/seed.sql
```

### 3. Verify setup

```sql
-- Check table count
SELECT schemaname, COUNT(*)
FROM pg_tables
WHERE schemaname = 'public'
GROUP BY schemaname;

-- Test RLS
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = true;

-- Should show all main tables with RLS enabled
```

---

## Future Migrations

### Adding new columns

```sql
ALTER TABLE projects ADD COLUMN impact_metrics JSONB DEFAULT '{}';
```

### Adding indexes

```sql
CREATE INDEX idx_projects_tags ON projects USING GIN(tags);
```

### Backfilling data

```sql
UPDATE contributions SET status = 'pending' WHERE status IS NULL;
```

---

## Troubleshooting

### RLS blocking queries?

Check policies:

```sql
SELECT * FROM pg_policies WHERE tablename = 'projects';
```

### Performance issues?

Check slow queries:

```sql
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

### Missing foreign keys?

```sql
SELECT conname, conrelid::regclass, confrelid::regclass
FROM pg_constraint
WHERE contype = 'f';
```
