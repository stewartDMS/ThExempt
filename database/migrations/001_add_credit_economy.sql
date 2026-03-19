-- ============================================================
-- Migration 001: Add Credit Economy & Enhanced Features
-- ============================================================
-- NON-DESTRUCTIVE: Uses IF NOT EXISTS and conditional column adds.
-- Safe to run against a database that already has:
--   applications, connections, contributions, discussion_likes,
--   discussion_media, discussion_replies, discussions, event_rsvps,
--   live_chat_messages, live_events, live_reactions, posts, profiles,
--   project_media, project_members, project_roles, projects,
--   role_applications, skill_categories, user_skills
-- ============================================================

-- ============================================================
-- SECTION 1: ALTER EXISTING TABLES (add missing columns)
-- ============================================================

-- profiles: membership, credits, reputation
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='membership_tier') THEN
    ALTER TABLE profiles ADD COLUMN membership_tier TEXT DEFAULT 'free' CHECK (membership_tier IN ('free', 'changemaker', 'movement_builder', 'founding_partner'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='stripe_customer_id') THEN
    ALTER TABLE profiles ADD COLUMN stripe_customer_id TEXT UNIQUE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='total_credits') THEN
    ALTER TABLE profiles ADD COLUMN total_credits INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='total_invested') THEN
    ALTER TABLE profiles ADD COLUMN total_invested INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='projects_backed') THEN
    ALTER TABLE profiles ADD COLUMN projects_backed INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='trust_score') THEN
    ALTER TABLE profiles ADD COLUMN trust_score INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='expertise_areas') THEN
    ALTER TABLE profiles ADD COLUMN expertise_areas TEXT[] DEFAULT '{}';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='badges') THEN
    ALTER TABLE profiles ADD COLUMN badges TEXT[] DEFAULT '{}';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='contributions_count') THEN
    ALTER TABLE profiles ADD COLUMN contributions_count INTEGER DEFAULT 0;
  END IF;
END $$;

-- projects: funding, verification, dates
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='funding_goal') THEN
    ALTER TABLE projects ADD COLUMN funding_goal INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='funding_raised') THEN
    ALTER TABLE projects ADD COLUMN funding_raised INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='funding_deadline') THEN
    ALTER TABLE projects ADD COLUMN funding_deadline TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='equity_offered') THEN
    ALTER TABLE projects ADD COLUMN equity_offered INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='min_investment') THEN
    ALTER TABLE projects ADD COLUMN min_investment INTEGER DEFAULT 10;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='backers_count') THEN
    ALTER TABLE projects ADD COLUMN backers_count INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='is_verified') THEN
    ALTER TABLE projects ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='is_featured') THEN
    ALTER TABLE projects ADD COLUMN is_featured BOOLEAN DEFAULT FALSE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='published_at') THEN
    ALTER TABLE projects ADD COLUMN published_at TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='funded_at') THEN
    ALTER TABLE projects ADD COLUMN funded_at TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='completed_at') THEN
    ALTER TABLE projects ADD COLUMN completed_at TIMESTAMPTZ;
  END IF;
END $$;

-- contributions: credit/equity rewards and review tracking
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='contributions' AND column_name='credits_earned') THEN
    ALTER TABLE contributions ADD COLUMN credits_earned INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='contributions' AND column_name='equity_earned') THEN
    ALTER TABLE contributions ADD COLUMN equity_earned NUMERIC(5,2) DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='contributions' AND column_name='reviewed_by') THEN
    ALTER TABLE contributions ADD COLUMN reviewed_by UUID REFERENCES profiles(id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='contributions' AND column_name='reviewed_at') THEN
    ALTER TABLE contributions ADD COLUMN reviewed_at TIMESTAMPTZ;
  END IF;
END $$;

-- ============================================================
-- SECTION 2: CREATE NEW TABLES
-- ============================================================

-- Subscriptions (Stripe-synced)
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  stripe_subscription_id TEXT UNIQUE NOT NULL,
  stripe_price_id TEXT NOT NULL,

  tier TEXT NOT NULL CHECK (tier IN ('changemaker', 'movement_builder', 'founding_partner')),
  status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'past_due', 'trialing')),

  current_period_start TIMESTAMPTZ NOT NULL,
  current_period_end TIMESTAMPTZ NOT NULL,
  cancel_at TIMESTAMPTZ,
  canceled_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Credit Transactions (Full Ledger)
CREATE TABLE IF NOT EXISTS credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  amount INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,

  transaction_type TEXT NOT NULL CHECK (transaction_type IN (
    'subscription',
    'investment',
    'contribution_reward',
    'equity_sale',
    'admin_adjustment'
  )),
  source_id UUID,

  description TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Investments (Credits → Equity)
CREATE TABLE IF NOT EXISTS investments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  investor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

  credits_invested INTEGER NOT NULL,
  equity_percentage NUMERIC(5,2) NOT NULL,

  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'exited', 'cancelled')),

  equity_value_usd NUMERIC(12,2) DEFAULT 0,
  last_valuation_date TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Skills (User Capabilities)
CREATE TABLE IF NOT EXISTS skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  skill_name TEXT NOT NULL,
  skill_category TEXT,
  proficiency TEXT CHECK (proficiency IN ('beginner', 'intermediate', 'expert')),
  years_experience INTEGER,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (user_id, skill_name)
);

-- Skill Offers (Services Users Provide)
CREATE TABLE IF NOT EXISTS skill_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  title TEXT NOT NULL,
  description TEXT NOT NULL,
  skill_categories TEXT[] DEFAULT '{}',

  rate_credits_per_hour INTEGER,
  equity_preferred BOOLEAN DEFAULT FALSE,

  available_hours_per_week INTEGER,
  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Skill Requests (Help Projects Need)
CREATE TABLE IF NOT EXISTS skill_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,

  title TEXT NOT NULL,
  description TEXT NOT NULL,
  skill_categories TEXT[] DEFAULT '{}',

  budget_credits INTEGER,
  equity_offered NUMERIC(5,2),

  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'completed', 'cancelled')),

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Project Milestones
CREATE TABLE IF NOT EXISTS project_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

  title TEXT NOT NULL,
  description TEXT,
  due_date TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  display_order INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- SECTION 3: INDEXES
-- ============================================================

-- Subscriptions
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);

-- Credit Transactions
CREATE INDEX IF NOT EXISTS idx_credit_transactions_user ON credit_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_created ON credit_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_type ON credit_transactions(transaction_type);

-- Investments
CREATE INDEX IF NOT EXISTS idx_investments_investor ON investments(investor_id);
CREATE INDEX IF NOT EXISTS idx_investments_project ON investments(project_id);
CREATE INDEX IF NOT EXISTS idx_investments_status ON investments(status);

-- Skills
CREATE INDEX IF NOT EXISTS idx_skills_user ON skills(user_id);
CREATE INDEX IF NOT EXISTS idx_skills_category ON skills(skill_category);

-- Skill Offers
CREATE INDEX IF NOT EXISTS idx_skill_offers_user ON skill_offers(user_id);
CREATE INDEX IF NOT EXISTS idx_skill_offers_active ON skill_offers(is_active);

-- Skill Requests
CREATE INDEX IF NOT EXISTS idx_skill_requests_requester ON skill_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_skill_requests_project ON skill_requests(project_id);
CREATE INDEX IF NOT EXISTS idx_skill_requests_status ON skill_requests(status);

-- Project Milestones
CREATE INDEX IF NOT EXISTS idx_milestones_project ON project_milestones(project_id);

-- Additional indexes on altered existing tables
CREATE INDEX IF NOT EXISTS idx_projects_funding ON projects(funding_raised DESC);
CREATE INDEX IF NOT EXISTS idx_projects_verified ON projects(is_verified);
CREATE INDEX IF NOT EXISTS idx_profiles_membership ON profiles(membership_tier);
CREATE INDEX IF NOT EXISTS idx_profiles_credits ON profiles(total_credits);

-- ============================================================
-- SECTION 4: TRIGGERS
-- ============================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to new tables that have updated_at
DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;
CREATE TRIGGER update_subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_skill_offers_updated_at ON skill_offers;
CREATE TRIGGER update_skill_offers_updated_at
  BEFORE UPDATE ON skill_offers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_skill_requests_updated_at ON skill_requests;
CREATE TRIGGER update_skill_requests_updated_at
  BEFORE UPDATE ON skill_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Update profile and project stats when an investment is created
CREATE OR REPLACE FUNCTION update_investment_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET
    total_invested = total_invested + NEW.credits_invested,
    projects_backed = projects_backed + 1
  WHERE id = NEW.investor_id;

  UPDATE projects
  SET
    funding_raised = funding_raised + NEW.credits_invested,
    backers_count = backers_count + 1
  WHERE id = NEW.project_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_investment_stats ON investments;
CREATE TRIGGER update_investment_stats
  AFTER INSERT ON investments
  FOR EACH ROW EXECUTE FUNCTION update_investment_stats();

-- ============================================================
-- SECTION 5: ROW-LEVEL SECURITY
-- ============================================================

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE investments ENABLE ROW LEVEL SECURITY;
ALTER TABLE skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_milestones ENABLE ROW LEVEL SECURITY;

-- Subscriptions: users can only see their own
CREATE POLICY "Users can see own subscriptions"
  ON subscriptions FOR SELECT
  USING (auth.uid() = user_id);

-- Credit Transactions: users can only see their own
CREATE POLICY "Users can see own credit transactions"
  ON credit_transactions FOR SELECT
  USING (auth.uid() = user_id);

-- Investments: investors see own; project owners see investments in their projects
CREATE POLICY "Users can see own investments"
  ON investments FOR SELECT
  USING (auth.uid() = investor_id);

CREATE POLICY "Project owners can see project investments"
  ON investments FOR SELECT
  USING (
    auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id)
  );

CREATE POLICY "Users can create investments"
  ON investments FOR INSERT
  WITH CHECK (auth.uid() = investor_id);

-- Skills: public read, owner write
CREATE POLICY "Skills are viewable by everyone"
  ON skills FOR SELECT
  USING (true);

CREATE POLICY "Users can manage own skills"
  ON skills FOR ALL
  USING (auth.uid() = user_id);

-- Skill Offers: public read, owner write
CREATE POLICY "Skill offers are viewable by everyone"
  ON skill_offers FOR SELECT
  USING (true);

CREATE POLICY "Users can manage own skill offers"
  ON skill_offers FOR ALL
  USING (auth.uid() = user_id);

-- Skill Requests: public read, requester write
CREATE POLICY "Skill requests are viewable by everyone"
  ON skill_requests FOR SELECT
  USING (true);

CREATE POLICY "Users can create skill requests"
  ON skill_requests FOR INSERT
  WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Users can manage own skill requests"
  ON skill_requests FOR UPDATE
  USING (auth.uid() = requester_id);

-- Project Milestones: public read, project owner write
CREATE POLICY "Milestones are viewable by everyone"
  ON project_milestones FOR SELECT
  USING (true);

CREATE POLICY "Project owners can manage milestones"
  ON project_milestones FOR ALL
  USING (
    auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id)
  );

-- ============================================================
-- SECTION 6: VIEWS
-- ============================================================

-- User portfolio summary
CREATE OR REPLACE VIEW user_portfolio AS
SELECT
  i.investor_id AS user_id,
  COUNT(DISTINCT i.project_id) AS projects_backed,
  SUM(i.credits_invested) AS total_invested,
  SUM(i.equity_percentage) AS total_equity_percentage,
  SUM(i.equity_value_usd) AS total_equity_value_usd
FROM investments i
WHERE i.status = 'active'
GROUP BY i.investor_id;

-- Project funding summary
CREATE OR REPLACE VIEW project_funding_summary AS
SELECT
  p.id AS project_id,
  p.title,
  p.funding_goal,
  p.funding_raised,
  p.backers_count,
  CASE
    WHEN p.funding_goal > 0 THEN ROUND((p.funding_raised::NUMERIC / p.funding_goal) * 100, 2)
    ELSE 0
  END AS funding_percentage,
  p.funding_deadline,
  p.status
FROM projects p;
