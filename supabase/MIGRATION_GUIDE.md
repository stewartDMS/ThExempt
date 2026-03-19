# ThExempt Database Migration Guide

This guide explains how to apply the consolidated MVP schema to your Supabase project and, if needed, how to migrate the existing `contributions` table without losing data.

---

## Overview

The schema is now consolidated into a **single file** (path relative to the repository root):

```
supabase/schema.sql
```

It replaces the following scattered files that have been removed:

| Removed file | Reason |
|---|---|
| `database/schema.sql` | Merged into `supabase/schema.sql` |
| `database/community_schema.sql` | Merged into `supabase/schema.sql` |
| `supabase/migrations/004_discussion_media.sql` | Merged into `supabase/schema.sql` |
| `supabase/migrations/005_update_discussions_media.sql` | Merged into `supabase/schema.sql` |
| `supabase/migrations/006_discussion_media_functions.sql` | Merged into `supabase/schema.sql` |
| `supabase/migrations/007_discussion_media_views.sql` | Merged into `supabase/schema.sql` |

---

## Tables in the New Schema

### Core (MVP Essential)

| Table | Description |
|---|---|
| `profiles` | User profile data (extends `auth.users`) |
| `projects` | Social impact projects |
| `contributions` | User contributions to projects |
| `discussions` | Community discussion threads |
| `discussion_replies` | Threaded replies within discussions |
| `discussion_likes` | Likes on discussions and replies |
| `discussion_media` | Images and videos attached to discussions |

### Supporting (Near-term)

| Table | Description |
|---|---|
| `notifications` | User notification inbox |
| `follows` | User follow relationships |
| `project_updates` | Project announcements and progress updates |
| `comments` | Comments on projects and contributions |

---

## Option A: Fresh Supabase Project (Recommended for New Deployments)

If you are setting up a brand-new Supabase project with no data:

1. Open the **Supabase Dashboard** → select your project.
2. Click **SQL Editor** in the left sidebar.
3. Open `supabase/schema.sql` from the repository.
4. **Copy the entire file contents** and paste them into the SQL Editor.
5. Click **Run** (or press `Ctrl+Enter`).
6. Verify the result:

```sql
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

Expected tables: `comments`, `contributions`, `discussion_likes`, `discussion_media`, `discussion_replies`, `discussions`, `follows`, `notifications`, `profiles`, `project_updates`, `projects`.

---

## Option B: Existing Project with Partial Schema

If you already have some tables (e.g. `contributions`, `profiles`, `discussions`), follow these steps carefully to avoid conflicts.

### Step 1 – Back up existing data

Run this in the SQL Editor to export current `contributions` data:

```sql
-- Save this output before running any migrations
SELECT * FROM contributions;
```

For a full backup, use the **Supabase Dashboard → Database → Backups** feature, or run `pg_dump` locally:

```bash
pg_dump --data-only --table=contributions <connection-string> > contributions_backup.sql
```

### Step 2 – Check which tables already exist

```sql
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

### Step 3 – Apply only missing tables

The new schema uses `CREATE TABLE IF NOT EXISTS` throughout, so it is safe to run against a project that already has some of these tables. Tables that already exist will be skipped.

Open `supabase/schema.sql` in the SQL Editor, paste it, and click **Run**.

### Step 4 – Migrate the existing `contributions` table

The new schema adds the following columns to `contributions`:

| Column | Type | Default | Description |
|---|---|---|---|
| `contribution_type` | `TEXT` | `NULL` | e.g. `code`, `design`, `content`, `funding`, `advocacy`, `other` |
| `status` | `TEXT` | `'pending'` | `pending`, `verified`, `rejected` |
| `verified_at` | `TIMESTAMPTZ` | `NULL` | When the contribution was verified |
| `verification_proof` | `TEXT` | `NULL` | URL or description of proof |
| `impact_description` | `TEXT` | `NULL` | How the contribution created impact |
| `tags` | `TEXT[]` | `'{}'` | Topic tags |

If your existing `contributions` table is missing these columns, run:

```sql
-- Add new columns to existing contributions table (safe, non-destructive)
ALTER TABLE contributions
  ADD COLUMN IF NOT EXISTS contribution_type TEXT
    CHECK (contribution_type IN ('code', 'design', 'content', 'funding', 'advocacy', 'other')),
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending'
    CHECK (status IN ('pending', 'verified', 'rejected')),
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS verification_proof TEXT,
  ADD COLUMN IF NOT EXISTS impact_description TEXT,
  ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
```

### Step 5 – Verify RLS is enabled on all tables

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

All tables should show `rowsecurity = true`.

---

## Option C: Full Reset (Destroys All Data)

> ⚠️ **WARNING:** This permanently deletes all data. Only use this on a development or staging environment, or when starting completely fresh.

```sql
-- Drop and recreate public schema
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

Then run the full `supabase/schema.sql` as described in Option A.

---

## Rollback Instructions

If you need to undo the schema changes, use the following script:

```sql
-- Remove tables added by new schema (reverse dependency order)
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS project_updates CASCADE;
DROP TABLE IF EXISTS follows CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS discussion_media CASCADE;
DROP TABLE IF EXISTS discussion_likes CASCADE;
DROP TABLE IF EXISTS discussion_replies CASCADE;
DROP TABLE IF EXISTS discussions CASCADE;
DROP TABLE IF EXISTS contributions CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Remove utility function
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS handle_discussion_like() CASCADE;
DROP FUNCTION IF EXISTS handle_discussion_reply() CASCADE;
DROP FUNCTION IF EXISTS handle_discussion_media_count() CASCADE;
DROP FUNCTION IF EXISTS handle_follow_counts() CASCADE;
```

> **Note:** `CASCADE` will drop all dependent objects (indexes, triggers, policies, views). If you want to keep any data, export it first.

---

## Loading Test Data

After the schema is applied, you can load sample data from `database/seed.sql`:

1. Sign up three test users in your Flutter app or via **Supabase Dashboard → Authentication → Users**.
2. Note their UUIDs from `auth.users`:

   ```sql
   SELECT id, email FROM auth.users;
   ```

3. Open `database/seed.sql` and replace `USER_ID_1`, `USER_ID_2`, `USER_ID_3` with the real UUIDs.
4. Run the edited `seed.sql` in the SQL Editor.

---

## Verifying the Schema

After applying the schema, run these checks:

```sql
-- 1. Check all expected tables exist
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- 2. Confirm RLS is enabled on all tables
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = true
ORDER BY tablename;

-- 3. Check indexes were created
SELECT indexname, tablename
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 4. Verify triggers exist
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;
```
