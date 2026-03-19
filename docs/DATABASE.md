# ThExempt Database Documentation

## Overview

ThExempt uses **Supabase** (PostgreSQL) as the primary database with:
- ✅ Row-Level Security (RLS)
- ✅ Realtime subscriptions
- ✅ Automatic triggers
- ✅ Optimized indexes

---

## Schema Diagram

```
┌─────────────┐
│  auth.users │ (Supabase Auth)
└──────┬──────┘
       │
       ├─→ profiles
       │
       ├─→ discussions ───→ discussion_replies
       │                  └─→ discussion_likes
       │                  └─→ discussion_media
       │
       ├─→ projects ───→ project_media
       │              ├─→ project_milestones
       │              └─→ project_team
       │
       ├─→ subscriptions ───→ credit_transactions
       │
       ├─→ investments
       │
       ├─→ skills ───→ skill_offers
       │             └─→ skill_requests
       │
       └─→ contributions
```

---

## Core Tables

### **profiles**
Extended user data (public profile, membership, reputation)

**Key columns:**
- `membership_tier` - free | changemaker | movement_builder | founding_partner
- `total_credits` - Current credit balance
- `trust_score` - Reputation score (0-100)
- `stripe_customer_id` - For Stripe integration

### **discussions**
Community discussions (problems, ideas, feedback)

**Key columns:**
- `category` - world_problems | ideas | learning | live_events | networking | feedback | general
- `is_verified` - Marked as credible by moderators
- `is_pinned` - Featured discussion

### **projects**
Fundable initiatives with milestones and teams

**Key columns:**
- `funding_goal` - Target credits to raise
- `funding_raised` - Current funding
- `equity_offered` - Percentage offered to backers
- `status` - draft | active | funded | in_progress | completed | cancelled

### **investments**
Credits invested in projects → equity earned

**Key columns:**
- `credits_invested` - Amount invested
- `equity_percentage` - Ownership earned
- `equity_value_usd` - Current valuation (updated externally)

### **credit_transactions**
Full ledger of all credit movements

**Key columns:**
- `amount` - Positive (credit) or negative (debit)
- `balance_after` - Running balance
- `transaction_type` - subscription | investment | contribution_reward | equity_sale | admin_adjustment
- `source_id` - References the source record

### **contributions**
Work logged on projects → credits + equity earned

**Key columns:**
- `hours_worked` - Time spent
- `credits_earned` - Credits rewarded
- `equity_earned` - Equity percentage rewarded
- `status` - pending | approved | rejected

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
ORDER BY funding_deadline ASC;
```

---

## Row-Level Security

All tables use RLS. Key policies:

- **Public read**: discussions, projects, profiles
- **Private read**: investments, credit_transactions, subscriptions
- **Owner-only write**: Most tables (can only update your own data)

---

## Triggers

### Auto-update timestamps
- `updated_at` is automatically set on UPDATE for profiles, discussions, and projects

### Auto-increment counters
- `discussions.likes_count` increments/decrements on like insert/delete
- `discussions.replies_count` increments on reply insert
- `projects.funding_raised` updates on investment insert
- `projects.backers_count` increments on investment insert

---

## Performance Tips

### Use indexes
All foreign keys and common queries have indexes

### Use views for complex aggregations
- `user_portfolio` - Pre-aggregated portfolio stats
- `project_funding_summary` - Funding progress
- `trending_discussions` - Hot topics

### Batch updates
Use transactions for multiple related updates:

```sql
BEGIN;
UPDATE profiles SET total_credits = total_credits - 100 WHERE id = 'USER_ID';
INSERT INTO credit_transactions (...);
INSERT INTO investments (...);
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
SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;
```

### Check table sizes

```sql
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```
