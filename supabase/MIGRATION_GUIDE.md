# ThExempt Database — Migration Guide

> **Canonical schema:** `supabase/schema.sql`

This guide covers everything contributors need to apply the unified schema to
Supabase, migrate data from the legacy structure, verify correctness, and roll
back safely if needed.

---

## Table of Contents

1. [Before You Begin](#1-before-you-begin)
2. [Fresh Install (New Environments)](#2-fresh-install)
3. [Migrating from the Legacy Schema](#3-migrating-from-the-legacy-schema)
4. [Storage Bucket Setup](#4-storage-bucket-setup)
5. [Verification Queries](#5-verification-queries)
6. [Rollback Procedures](#6-rollback-procedures)
7. [Adding Future Schema Changes](#7-adding-future-schema-changes)
8. [Common Issues](#8-common-issues)

---

## 1. Before You Begin

### 1a. Take a full database backup

Download a snapshot before touching anything:

**Supabase Dashboard → Project Settings → Database → Backups → Download**

Or via the CLI:

```bash
supabase db dump --linked -f backup_$(date +%Y%m%d).sql
```

### 1b. Identify what is currently live

```sql
-- List all public tables
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

### 1c. Understand the source-of-truth rule

From this point forward **`supabase/schema.sql` is the only canonical schema
file**. Do not create separate migration fragments unless you also update this
file and add a versioned section to this guide.

---

## 2. Fresh Install

For new environments (local dev, staging, new Supabase project):

1. Open the **Supabase SQL Editor**.
2. Copy and paste the entire contents of `supabase/schema.sql`.
3. Click **Run**.
4. *(Optional)* Load sample data: copy and paste `supabase/seed.sql`, replace
   `USER_ID_1 / _2 / _3` with real UUIDs from `auth.users`, then run it.
5. Confirm with the [verification queries](#5-verification-queries) below.

---

## 3. Migrating from the Legacy Schema

### Step 1 — Export data you want to keep

```sql
-- Profiles
COPY (SELECT * FROM profiles)      TO '/tmp/profiles_bak.csv'      CSV HEADER;

-- Projects
COPY (SELECT * FROM projects)      TO '/tmp/projects_bak.csv'      CSV HEADER;

-- Contributions
COPY (SELECT * FROM contributions) TO '/tmp/contributions_bak.csv' CSV HEADER;

-- Discussions
COPY (SELECT * FROM discussions)   TO '/tmp/discussions_bak.csv'   CSV HEADER;
```

### Step 2 — Remove legacy tables not in the new schema

The following tables existed in the old `database/schema.sql` or
`database/community_schema.sql` but have been superseded. Drop them **after**
exporting anything you need:

```sql
-- project_team is replaced by project_members
DROP TABLE IF EXISTS project_team CASCADE;
```

All other legacy tables (`discussions`, `profiles`, `projects`, etc.) are
retained with the same name but with improved columns; use `ALTER TABLE` to
add missing columns rather than dropping and recreating if you have live data.

### Step 3 — Apply the new schema

Paste `supabase/schema.sql` into the SQL Editor and run it.

> ⚠️ The schema uses `CREATE TABLE` (not `CREATE TABLE IF NOT EXISTS`).
> If tables already exist, add a `DROP TABLE IF EXISTS … CASCADE;` line before
> each `CREATE TABLE`, **or** apply only the `ALTER TABLE` statements for
> columns you need to add.

### Step 4 — Column mapping reference

| Old location | New location |
|---|---|
| `project_team.role` | `project_members.role_title` |
| `skills.skill_category` (TEXT) | `skills.skill_category_id` (UUID FK → `skill_categories`) |
| `credit_transactions.transaction_type = 'subscription'` | `'subscription_credit'` |
| `credit_transactions.transaction_type = 'investment'` | `'investment_debit'` |
| `discussion_media.uploaded_at` | `discussion_media.created_at` |
| `profiles.name` | `profiles.full_name` |
| `live_events` (from `community_schema.sql`) | `live_events` (unchanged; now in unified schema) |
| `event_rsvps` (from `community_schema.sql`) | `event_rsvps` (unchanged; now in unified schema) |
| `live_chat_messages` (from `community_schema.sql`) | `live_chat_messages` (unchanged) |
| `live_reactions` (from `community_schema.sql`) | `live_reactions` (unchanged) |

### Step 5 — Re-import exported data

Example for profiles:

```sql
INSERT INTO profiles (id, username, full_name, bio, avatar_url, membership_tier, total_credits)
SELECT id, username, full_name, bio, avatar_url, membership_tier, total_credits
FROM legacy_profiles_staging
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  bio       = EXCLUDED.bio;
```

---

## 4. Storage Bucket Setup

The schema covers only database tables. Storage bucket policies must be
configured separately via the Supabase Dashboard or CLI.

### Required bucket: `discussion-media`

```sql
-- Run in Supabase SQL Editor (requires service role)
INSERT INTO storage.buckets (id, name, public)
VALUES ('discussion-media', 'discussion-media', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload under their own user_id prefix
CREATE POLICY "Users can upload discussion media"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'discussion-media'
    AND auth.uid()::text = (string_to_array(name, '/'))[1]
  );

-- Public read access
CREATE POLICY "Discussion media is public"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'discussion-media');

-- Users can delete their own files
CREATE POLICY "Users can delete their own discussion media"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'discussion-media'
    AND auth.uid()::text = (string_to_array(name, '/'))[1]
  );
```

See `supabase/docs/storage_structure.md` for the full file path convention.

---

## 5. Verification Queries

Run these after applying the schema to confirm everything is correct.

### 5a. Table count

```sql
SELECT COUNT(*) AS table_count
FROM pg_tables
WHERE schemaname = 'public';
-- Expected: 27 tables
```

### 5b. All tables have RLS enabled

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
-- All rows should show rowsecurity = true
```

### 5c. All triggers present

```sql
SELECT trigger_name, event_object_table, event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;
```

### 5d. Indexes present

```sql
SELECT indexname, tablename
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

### 5e. Skill categories seeded

```sql
SELECT COUNT(*) FROM skill_categories;
-- Expected: 78
```

### 5f. Auto-profile trigger works

After creating a test user via Supabase Auth, verify their profile was
auto-created:

```sql
SELECT id, username FROM profiles ORDER BY created_at DESC LIMIT 5;
```

### 5g. RLS policy list

```sql
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### 5h. Views accessible

```sql
SELECT * FROM trending_discussions LIMIT 5;
SELECT * FROM project_funding_summary LIMIT 5;
SELECT * FROM user_portfolio LIMIT 5;
SELECT * FROM discussions_with_media LIMIT 5;
```

---

## 6. Rollback Procedures

### Option A — Restore from Supabase backup (recommended)

**Supabase Dashboard → Project Settings → Database → Backups →
Restore to point-in-time**

### Option B — Manual drop and re-apply

Drop all new tables in reverse dependency order, then re-apply your saved
backup SQL:

```sql
-- Drop in reverse FK order
DROP TABLE IF EXISTS comments             CASCADE;
DROP TABLE IF EXISTS project_updates      CASCADE;
DROP TABLE IF EXISTS investments          CASCADE;
DROP TABLE IF EXISTS credit_transactions  CASCADE;
DROP TABLE IF EXISTS subscriptions        CASCADE;
DROP TABLE IF EXISTS notifications        CASCADE;
DROP TABLE IF EXISTS follows              CASCADE;
DROP TABLE IF EXISTS live_reactions       CASCADE;
DROP TABLE IF EXISTS live_chat_messages   CASCADE;
DROP TABLE IF EXISTS event_rsvps          CASCADE;
DROP TABLE IF EXISTS live_events          CASCADE;
DROP TABLE IF EXISTS project_members      CASCADE;
DROP TABLE IF EXISTS role_applications    CASCADE;
DROP TABLE IF EXISTS project_roles        CASCADE;
DROP TABLE IF EXISTS project_milestones   CASCADE;
DROP TABLE IF EXISTS project_media        CASCADE;
DROP TABLE IF EXISTS skill_requests       CASCADE;
DROP TABLE IF EXISTS skill_offers         CASCADE;
DROP TABLE IF EXISTS skills               CASCADE;
DROP TABLE IF EXISTS skill_categories     CASCADE;
DROP TABLE IF EXISTS discussion_media     CASCADE;
DROP TABLE IF EXISTS discussion_likes     CASCADE;
DROP TABLE IF EXISTS discussion_replies   CASCADE;
DROP TABLE IF EXISTS discussions          CASCADE;
DROP TABLE IF EXISTS contributions        CASCADE;
DROP TABLE IF EXISTS projects             CASCADE;
DROP TABLE IF EXISTS profiles             CASCADE;

-- Then paste your backup SQL and run it.
```

---

## 7. Adding Future Schema Changes

All schema evolution must follow this process to keep things tidy:

1. **Edit `supabase/schema.sql`** — add the new table, column, index, or
   policy to the relevant section.
2. **Write the incremental SQL** — document the exact `ALTER TABLE` /
   `CREATE INDEX` / etc. statement in a new numbered sub-section below.
3. **Test on staging** before applying to production.
4. **Update `docs/DATABASE.md`** if the change affects documented queries or
   behaviour.

### Migration 003 — Add `category` column to `discussions`

**File:** `supabase/migrations/003_add_category_to_discussions.sql`

**What it does:**
- Adds `category TEXT NULL` to `public.discussions` (nullable so existing rows
  are unaffected).
- Creates `idx_discussions_category` index for fast category-filter queries.

**Apply it:**

```sql
-- Paste the contents of supabase/migrations/003_add_category_to_discussions.sql
-- into the Supabase SQL Editor and click Run.
-- Or via CLI:  supabase db push
```

**Verify:**

```sql
-- Column exists and is nullable
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'discussions'
  AND column_name  = 'category';
-- Expected: category | text | YES

-- Index exists
SELECT indexname FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename  = 'discussions'
  AND indexname  = 'idx_discussions_category';

-- Insert without category (NULL)
INSERT INTO public.discussions (user_id, title, content)
VALUES ('<valid-user-uuid>', 'Test no-category', 'body')
RETURNING id, category;   -- category should be NULL

-- Insert with category
INSERT INTO public.discussions (user_id, title, content, category)
VALUES ('<valid-user-uuid>', 'Test with category', 'body', 'general')
RETURNING id, category;   -- category should be 'general'
```

**Rollback:**

```sql
ALTER TABLE public.discussions DROP COLUMN IF EXISTS category;
DROP INDEX IF EXISTS public.idx_discussions_category;
```

---

### v1.0 → vNext example (template)

```sql
-- Example: add a "category" column to notifications
ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'general';

-- Example: new index
CREATE INDEX IF NOT EXISTS idx_notifications_category ON notifications(category);
```

---

## 8. Common Issues

### "column already exists"

You're running the full schema against a partially-migrated database. Use
`ALTER TABLE … ADD COLUMN IF NOT EXISTS` for incremental changes instead of
running the full `CREATE TABLE` block.

### "relation already exists"

Add a `DROP TABLE IF EXISTS … CASCADE;` before the `CREATE TABLE` statement,
or only apply the `ALTER TABLE` statements you need.

### "permission denied"

Ensure you're connected as the `postgres` superuser in the Supabase SQL
Editor. This role bypasses RLS by default, which is required for schema
changes.

### "violates row-level security policy"

When seeding data via the SQL Editor as `postgres`, this should not happen —
the superuser bypasses RLS. If you see this from your app, check that the
correct policy exists for the operation and that `auth.uid()` is set.

### Trigger not firing

Verify the function exists:

```sql
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION'
ORDER BY routine_name;
```

### Performance issues

Check slow queries (requires `pg_stat_statements` extension):

```sql
SELECT query, calls, total_exec_time, mean_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```
