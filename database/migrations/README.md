# Database Migrations

## Initial Setup

### 1. Run the schema

In Supabase SQL Editor:

```sql
-- Copy/paste contents of database/schema.sql
```

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

-- Should return 20+ tables

-- Test RLS
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = true;

-- Should show all main tables with RLS enabled
```

---

## Migration 001: Add Credit Economy (`001_add_credit_economy.sql`)

### What this migration adds

This migration is **non-destructive** and safe to run against an existing database. It:

**Alters existing tables** (only adds columns if they don't already exist):
- `profiles` — membership tier, Stripe customer ID, credit balance, investment totals, reputation fields
- `projects` — funding goal/raised/deadline, equity offered, backer count, verification flags, lifecycle dates
- `contributions` — credits earned, equity earned, reviewer tracking

**Creates new tables** for the credit economy and skills marketplace:
- `subscriptions` — Stripe-synced membership tracking
- `credit_transactions` — Full credit ledger (all debits and credits)
- `investments` — Credits invested in projects → equity ownership
- `skills` — User capabilities (distinct from `user_skills`)
- `skill_offers` — Services users are willing to provide
- `skill_requests` — Help that projects are seeking
- `project_milestones` — Project progress checkpoints

**Adds indexes** for common query patterns (funding leaderboards, membership lookups, credit history).

**Adds triggers**:
- `update_updated_at` — Keeps `updated_at` current on `subscriptions`, `skill_offers`, `skill_requests`
- `update_investment_stats` — Automatically increments `profiles.total_invested`, `profiles.projects_backed`, `projects.funding_raised`, and `projects.backers_count` when a new investment is created

**Enables Row-Level Security** on all new tables with appropriate policies:
- Financial tables (`subscriptions`, `credit_transactions`) — owner-only read
- Investment tables — investor read + project-owner read
- Community tables (`skills`, `skill_offers`, `skill_requests`, `project_milestones`) — public read, owner write

**Adds views**:
- `user_portfolio` — Aggregate investment stats per user
- `project_funding_summary` — Funding progress including percentage funded

### How to run it

In the Supabase SQL Editor, copy and paste the contents of `001_add_credit_economy.sql` and execute it.

```sql
-- Copy/paste contents of database/migrations/001_add_credit_economy.sql
```

### How to verify it worked

```sql
-- Check new tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'subscriptions', 'credit_transactions', 'investments',
    'skills', 'skill_offers', 'skill_requests', 'project_milestones'
  )
ORDER BY table_name;
-- Should return 7 rows

-- Check new columns on profiles
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'profiles'
  AND column_name IN (
    'membership_tier', 'stripe_customer_id', 'total_credits',
    'total_invested', 'projects_backed', 'trust_score',
    'expertise_areas', 'badges', 'contributions_count'
  )
ORDER BY column_name;
-- Should return 9 rows (one for each column)

-- Check new columns on projects
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'projects'
  AND column_name IN (
    'funding_goal', 'funding_raised', 'funding_deadline',
    'equity_offered', 'min_investment', 'backers_count',
    'is_verified', 'is_featured', 'published_at', 'funded_at', 'completed_at'
  )
ORDER BY column_name;
-- Should return 11 rows (one for each column)

-- Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'subscriptions', 'credit_transactions', 'investments',
    'skills', 'skill_offers', 'skill_requests', 'project_milestones'
  )
ORDER BY tablename;
-- rowsecurity should be true for all 7 tables

-- Check views exist
SELECT viewname FROM pg_views
WHERE schemaname = 'public'
  AND viewname IN ('user_portfolio', 'project_funding_summary');
-- Should return 2 rows

-- Check triggers exist
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;
```

### Rollback instructions

> **Warning:** Rolling back will permanently delete data in the new tables. Only do this if you have not yet written any production data.

```sql
-- Drop views
DROP VIEW IF EXISTS user_portfolio;
DROP VIEW IF EXISTS project_funding_summary;

-- Drop triggers
DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;
DROP TRIGGER IF EXISTS update_skill_offers_updated_at ON skill_offers;
DROP TRIGGER IF EXISTS update_skill_requests_updated_at ON skill_requests;
DROP TRIGGER IF EXISTS update_investment_stats ON investments;

-- Drop functions (only if not used elsewhere)
-- DROP FUNCTION IF EXISTS update_updated_at();
-- DROP FUNCTION IF EXISTS update_investment_stats();

-- Drop new tables (order matters due to foreign keys)
DROP TABLE IF EXISTS project_milestones;
DROP TABLE IF EXISTS skill_requests;
DROP TABLE IF EXISTS skill_offers;
DROP TABLE IF EXISTS skills;
DROP TABLE IF EXISTS investments;
DROP TABLE IF EXISTS credit_transactions;
DROP TABLE IF EXISTS subscriptions;

-- Remove added columns from existing tables
-- profiles
ALTER TABLE profiles
  DROP COLUMN IF EXISTS membership_tier,
  DROP COLUMN IF EXISTS stripe_customer_id,
  DROP COLUMN IF EXISTS total_credits,
  DROP COLUMN IF EXISTS total_invested,
  DROP COLUMN IF EXISTS projects_backed,
  DROP COLUMN IF EXISTS trust_score,
  DROP COLUMN IF EXISTS expertise_areas,
  DROP COLUMN IF EXISTS badges,
  DROP COLUMN IF EXISTS contributions_count;

-- projects
ALTER TABLE projects
  DROP COLUMN IF EXISTS funding_goal,
  DROP COLUMN IF EXISTS funding_raised,
  DROP COLUMN IF EXISTS funding_deadline,
  DROP COLUMN IF EXISTS equity_offered,
  DROP COLUMN IF EXISTS min_investment,
  DROP COLUMN IF EXISTS backers_count,
  DROP COLUMN IF EXISTS is_verified,
  DROP COLUMN IF EXISTS is_featured,
  DROP COLUMN IF EXISTS published_at,
  DROP COLUMN IF EXISTS funded_at,
  DROP COLUMN IF EXISTS completed_at;

-- contributions
ALTER TABLE contributions
  DROP COLUMN IF EXISTS credits_earned,
  DROP COLUMN IF EXISTS equity_earned,
  DROP COLUMN IF EXISTS reviewed_by,
  DROP COLUMN IF EXISTS reviewed_at;
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
UPDATE profiles SET trust_score = 50 WHERE created_at < NOW() - INTERVAL '30 days';
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
