# ThExempt Database Documentation

> **Canonical schema:** [`supabase/schema.sql`](../supabase/schema.sql)
> **Migration guide:** [`supabase/MIGRATION_GUIDE.md`](../supabase/MIGRATION_GUIDE.md)

## Overview

ThExempt uses **Supabase** (PostgreSQL) as the primary database with:
- ✅ Row-Level Security (RLS) on every table
- ✅ Realtime subscriptions
- ✅ Automatic triggers (updated_at, counters, auto-profile creation)
- ✅ Optimized composite indexes
- ✅ Soft-delete support (`deleted_at`) on key tables

---

## Schema Diagram

```
┌─────────────┐
│  auth.users │ (Supabase Auth)
└──────┬──────┘
       │ (auto-created via trigger)
       ├─→ profiles
       │
       ├─→ discussions ──→ discussion_replies
       │                ├─→ discussion_likes
       │                └─→ discussion_media
       │
       ├─→ projects ──→ project_media
       │             ├─→ project_milestones
       │             ├─→ project_roles ──→ role_applications
       │             ├─→ project_members
       │             └─→ project_updates ──→ comments
       │
       ├─→ live_events ──→ event_rsvps
       │               ├─→ live_chat_messages
       │               └─→ live_reactions
       │
       ├─→ skill_categories ──→ skills
       ├─→ skill_offers
       ├─→ skill_requests
       │
       ├─→ subscriptions
       ├─→ credit_transactions
       ├─→ investments
       │
       ├─→ follows
       ├─→ notifications
       └─→ contributions
```

---

## Core Tables

### **profiles**
Public user profile extending Supabase `auth.users`. Central entity tied to
membership tiers, credits, and reputation.

**Key columns:**
- `membership_tier` — `free | changemaker | movement_builder | founding_partner`
- `total_credits` — Cached credit balance (maintained by trigger)
- `trust_score` — Reputation score 0–100
- `stripe_customer_id` — Stripe integration
- `deleted_at` — Soft-delete timestamp

### **discussions**
Community discussion threads. Core to the Problem → Solution → Project pipeline.

**Key columns:**
- `category` — `world_problems | ideas | learning | live_events | networking | feedback | general`
- `is_verified` — Credibility marker set by moderators
- `is_pinned` — Featured/pinned discussion
- `media_count` — Cached count of attached media

### **projects**
Fundable community initiatives with milestones and team roles.

**Key columns:**
- `funding_goal / funding_raised` — Credit-based funding target and progress
- `equity_offered` — Total equity percentage offered to all backers
- `status` — `draft | active | funded | in_progress | completed | cancelled`
- `impact_metrics` — Free-form JSONB for social/environmental KPIs

### **investments**
Credits invested in a project, converting to an equity stake.

**Key columns:**
- `credits_invested` — Amount invested
- `equity_percentage` — Ownership stake earned
- `equity_value_usd` — Current USD valuation (updated by equity platform)

### **credit_transactions**
Immutable ledger of every credit movement (double-entry).

**Key columns:**
- `amount` — Positive = earned; negative = spent
- `balance_after` — Running balance snapshot
- `transaction_type` — `subscription_credit | investment_debit | contribution_reward | equity_sale | refund | admin_adjustment`

### **contributions**
Work logged against projects; reviewed for credit/equity rewards.

**Key columns:**
- `contribution_type` — `code | design | research | writing | community | general`
- `hours_worked` — Time spent
- `credits_earned / equity_earned` — Rewards after approval
- `status` — `pending | approved | rejected`

### **live_events**
Scheduled or live community events with chat and reaction support.

**Key columns:**
- `event_type` — `panel | workshop | ama | townhall | demo | social | other`
- `is_live` — Whether the event is currently broadcasting
- `allow_chat / allow_reactions` — Feature toggles

### **skill_categories**
Canonical taxonomy of 80+ skills. Reference data seeded by the schema.

### **skills**
Skills declared by individual users, linked to `skill_categories`.

### **skill_offers / skill_requests**
The skills marketplace: users advertise availability; projects post gaps.

### **notifications**
Polymorphic in-app notification feed. `target_type` + `target_id` identify the
subject (discussion, project, contribution, etc.).

---

## Common Queries

### Get user's portfolio

```sql
SELECT * FROM user_portfolio WHERE user_id = 'USER_ID';
```

### Get trending discussions (past 7 days)

```sql
SELECT * FROM trending_discussions LIMIT 10;
```

### Get project funding progress

```sql
SELECT * FROM project_funding_summary WHERE project_id = 'PROJECT_ID';
```

### Get discussions with media

```sql
SELECT * FROM discussions_with_media WHERE id = 'DISCUSSION_ID';
```

### Get user's credit history

```sql
SELECT * FROM credit_transactions
WHERE user_id = 'USER_ID'
ORDER BY created_at DESC;
```

### Get active projects needing funding

```sql
SELECT * FROM projects
WHERE status = 'active'
  AND funding_raised < funding_goal
  AND deleted_at IS NULL
ORDER BY funding_deadline ASC;
```

### Get open skill requests

```sql
SELECT sr.*, p.title AS project_title
FROM skill_requests sr
LEFT JOIN projects p ON sr.project_id = p.id
WHERE sr.status = 'open' AND sr.deleted_at IS NULL;
```

---

## Row-Level Security

RLS is enabled on every table. Policy summary:

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `profiles` | Public (non-deleted) | Own | Own | Own |
| `projects` | Public non-drafts; owner sees drafts | Own | Own | Own |
| `discussions` | Public (non-archived) | Authenticated | Own | Own |
| `investments` | Investor + project owner | Own investor | — | — |
| `credit_transactions` | Own | Service role | — | — |
| `subscriptions` | Own | Service role | — | — |
| `notifications` | Own | System | Own (mark read) | — |
| `skill_categories` | Public | — | — | — |

---

## Triggers

### Auto-update timestamps
`updated_at` is automatically set on `UPDATE` for all 19 mutable tables.

### Auto-increment counters
- `discussions.likes_count` ↑↓ on like insert/delete
- `discussions.replies_count` ↑↓ on reply insert/delete
- `discussions.media_count` ↑↓ on media insert/delete
- `projects.funding_raised` and `backers_count` ↑ on investment insert
- `profiles.total_invested` and `projects_backed` ↑ on investment insert
- `live_events.rsvp_count` ↑↓ on RSVP insert/delete

### Media upload validation
`fn_validate_media_upload()` enforces: max 5 files per discussion, images ≤ 10 MB,
videos ≤ 100 MB.

### Auto-create profile on signup
`fn_handle_new_user()` fires after every `auth.users` insert and creates the
corresponding `profiles` row automatically.

---

## Performance Tips

### Use views for aggregations
- `user_portfolio` — Investment portfolio stats per user
- `project_funding_summary` — Funding progress per project
- `trending_discussions` — Hot topics (past 7 days)
- `discussions_with_media` — Discussions with media pre-aggregated as JSON

### Batch financial updates in a transaction

```sql
BEGIN;
UPDATE profiles SET total_credits = total_credits - 100 WHERE id = 'USER_ID';
INSERT INTO credit_transactions (user_id, amount, balance_after, transaction_type, description)
  VALUES ('USER_ID', -100, 0, 'investment_debit', 'Investment in …');
INSERT INTO investments (investor_id, project_id, credits_invested, equity_percentage)
  VALUES ('USER_ID', 'PROJECT_ID', 100, 0.5);
COMMIT;
```

---

## Maintenance

### Vacuum regularly

```sql
VACUUM ANALYZE;
```

### Monitor slow queries

```sql
SELECT query, calls, total_exec_time, mean_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

### Check table sizes

```sql
SELECT
  tablename,
  pg_size_pretty(pg_total_relation_size('public.' || tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size('public.' || tablename) DESC;
```
