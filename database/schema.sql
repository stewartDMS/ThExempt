-- ============================================================
-- ThExempt Platform - Complete PostgreSQL Schema for Supabase
-- ============================================================

-- ============================================================
-- USERS & PROFILES
-- ============================================================

-- Extends Supabase auth.users with public profile data
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  full_name TEXT,
  bio TEXT,
  avatar_url TEXT,
  website_url TEXT,
  location TEXT,

  -- Membership
  membership_tier TEXT DEFAULT 'free' CHECK (membership_tier IN ('free', 'changemaker', 'movement_builder', 'founding_partner')),
  stripe_customer_id TEXT UNIQUE,

  -- Reputation
  trust_score INTEGER DEFAULT 0,
  expertise_areas TEXT[] DEFAULT '{}',
  badges TEXT[] DEFAULT '{}',

  -- Stats
  total_credits INTEGER DEFAULT 0,
  total_invested INTEGER DEFAULT 0,
  projects_backed INTEGER DEFAULT 0,
  contributions_count INTEGER DEFAULT 0,

  -- Meta
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- DISCUSSIONS
-- ============================================================

CREATE TABLE discussions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Content
  category TEXT NOT NULL CHECK (category IN ('world_problems', 'ideas', 'learning', 'live_events', 'networking', 'feedback', 'general')),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',

  -- Moderation
  is_pinned BOOLEAN DEFAULT FALSE,
  is_verified BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,

  -- Engagement
  likes_count INTEGER DEFAULT 0,
  replies_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,

  -- Meta
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE discussion_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id UUID NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  parent_reply_id UUID REFERENCES discussion_replies(id) ON DELETE CASCADE,

  -- Content
  content TEXT NOT NULL,

  -- Engagement
  likes_count INTEGER DEFAULT 0,

  -- Moderation
  is_solution BOOLEAN DEFAULT FALSE,
  is_verified BOOLEAN DEFAULT FALSE,

  -- Meta
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE discussion_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id UUID REFERENCES discussions(id) ON DELETE CASCADE,
  reply_id UUID REFERENCES discussion_replies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Only one discussion_id OR reply_id
  CHECK (
    (discussion_id IS NOT NULL AND reply_id IS NULL) OR
    (discussion_id IS NULL AND reply_id IS NOT NULL)
  ),

  -- Unique per user per item
  UNIQUE NULLS NOT DISTINCT (user_id, discussion_id, reply_id)
);

CREATE TABLE discussion_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id UUID NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,

  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
  file_url TEXT NOT NULL,
  thumbnail_url TEXT,
  file_name TEXT,
  file_size BIGINT,
  width INTEGER,
  height INTEGER,
  duration_seconds INTEGER,
  display_order INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- PROJECTS
-- ============================================================

CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Content
  title TEXT NOT NULL,
  tagline TEXT,
  description TEXT NOT NULL,
  problem_statement TEXT,
  solution_approach TEXT,
  category TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',

  -- Funding
  funding_goal INTEGER DEFAULT 0,
  funding_raised INTEGER DEFAULT 0,
  funding_deadline TIMESTAMPTZ,
  equity_offered INTEGER DEFAULT 0,
  min_investment INTEGER DEFAULT 10,

  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'funded', 'in_progress', 'completed', 'cancelled')),
  is_verified BOOLEAN DEFAULT FALSE,
  is_featured BOOLEAN DEFAULT FALSE,

  -- Engagement
  backers_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  likes_count INTEGER DEFAULT 0,

  -- Meta
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ,
  funded_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
);

CREATE TABLE project_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
  file_url TEXT NOT NULL,
  thumbnail_url TEXT,
  file_name TEXT,
  file_size BIGINT,
  width INTEGER,
  height INTEGER,
  duration_seconds INTEGER,
  display_order INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE project_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

  title TEXT NOT NULL,
  description TEXT,
  due_date TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  display_order INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE project_team (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  role TEXT NOT NULL,
  joined_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (project_id, user_id)
);

-- ============================================================
-- CREDIT ECONOMY
-- ============================================================

CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Stripe data
  stripe_subscription_id TEXT UNIQUE NOT NULL,
  stripe_price_id TEXT NOT NULL,

  -- Tier
  tier TEXT NOT NULL CHECK (tier IN ('changemaker', 'movement_builder', 'founding_partner')),

  -- Status
  status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'past_due', 'trialing')),

  -- Dates
  current_period_start TIMESTAMPTZ NOT NULL,
  current_period_end TIMESTAMPTZ NOT NULL,
  cancel_at TIMESTAMPTZ,
  canceled_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Credits ledger (double-entry accounting)
CREATE TABLE credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Transaction
  amount INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,

  -- Type & Source
  transaction_type TEXT NOT NULL CHECK (transaction_type IN (
    'subscription',
    'investment',
    'contribution_reward',
    'equity_sale',
    'admin_adjustment'
  )),
  source_id UUID,

  -- Description
  description TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Investments (credits → project equity)
CREATE TABLE investments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  investor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

  -- Investment
  credits_invested INTEGER NOT NULL,
  equity_percentage NUMERIC(5,2) NOT NULL,

  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'exited', 'cancelled')),

  -- Equity tracking
  equity_value_usd NUMERIC(12,2) DEFAULT 0,
  last_valuation_date TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- SKILLS MARKETPLACE
-- ============================================================

CREATE TABLE skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  skill_name TEXT NOT NULL,
  skill_category TEXT,
  proficiency TEXT CHECK (proficiency IN ('beginner', 'intermediate', 'expert')),
  years_experience INTEGER,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (user_id, skill_name)
);

CREATE TABLE skill_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  title TEXT NOT NULL,
  description TEXT NOT NULL,
  skill_categories TEXT[] DEFAULT '{}',

  -- Compensation
  rate_credits_per_hour INTEGER,
  equity_preferred BOOLEAN DEFAULT FALSE,

  -- Availability
  available_hours_per_week INTEGER,
  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE skill_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,

  title TEXT NOT NULL,
  description TEXT NOT NULL,
  skill_categories TEXT[] DEFAULT '{}',

  -- Compensation
  budget_credits INTEGER,
  equity_offered NUMERIC(5,2),

  -- Status
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'completed', 'cancelled')),

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- CONTRIBUTIONS (Work Tracking)
-- ============================================================

CREATE TABLE contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contributor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

  -- Work
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  hours_worked NUMERIC(5,1),

  -- Rewards
  credits_earned INTEGER DEFAULT 0,
  equity_earned NUMERIC(5,2) DEFAULT 0,

  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES profiles(id),
  reviewed_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================

-- Profiles
CREATE INDEX idx_profiles_username ON profiles(username);
CREATE INDEX idx_profiles_membership_tier ON profiles(membership_tier);

-- Discussions
CREATE INDEX idx_discussions_author ON discussions(author_id);
CREATE INDEX idx_discussions_category ON discussions(category);
CREATE INDEX idx_discussions_created ON discussions(created_at DESC);
CREATE INDEX idx_discussions_trending ON discussions(likes_count DESC, replies_count DESC);

-- Discussion Replies
CREATE INDEX idx_replies_discussion ON discussion_replies(discussion_id);
CREATE INDEX idx_replies_parent ON discussion_replies(parent_reply_id);
CREATE INDEX idx_replies_author ON discussion_replies(author_id);

-- Projects
CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_category ON projects(category);
CREATE INDEX idx_projects_funding ON projects(funding_raised DESC);
CREATE INDEX idx_projects_created ON projects(created_at DESC);

-- Investments
CREATE INDEX idx_investments_investor ON investments(investor_id);
CREATE INDEX idx_investments_project ON investments(project_id);

-- Credit Transactions
CREATE INDEX idx_credits_user ON credit_transactions(user_id);
CREATE INDEX idx_credits_created ON credit_transactions(created_at DESC);

-- Contributions
CREATE INDEX idx_contributions_contributor ON contributions(contributor_id);
CREATE INDEX idx_contributions_project ON contributions(project_id);
CREATE INDEX idx_contributions_status ON contributions(status);

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_discussions_updated_at BEFORE UPDATE ON discussions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-increment likes counters
CREATE OR REPLACE FUNCTION increment_discussion_likes()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.discussion_id IS NOT NULL THEN
    UPDATE discussions SET likes_count = likes_count + 1 WHERE id = NEW.discussion_id;
  ELSIF NEW.reply_id IS NOT NULL THEN
    UPDATE discussion_replies SET likes_count = likes_count + 1 WHERE id = NEW.reply_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER increment_likes AFTER INSERT ON discussion_likes FOR EACH ROW EXECUTE FUNCTION increment_discussion_likes();

-- Decrement likes on delete
CREATE OR REPLACE FUNCTION decrement_discussion_likes()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.discussion_id IS NOT NULL THEN
    UPDATE discussions SET likes_count = likes_count - 1 WHERE id = OLD.discussion_id;
  ELSIF OLD.reply_id IS NOT NULL THEN
    UPDATE discussion_replies SET likes_count = likes_count - 1 WHERE id = OLD.reply_id;
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER decrement_likes AFTER DELETE ON discussion_likes FOR EACH ROW EXECUTE FUNCTION decrement_discussion_likes();

-- Increment replies count
CREATE OR REPLACE FUNCTION increment_replies_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE discussions SET replies_count = replies_count + 1 WHERE id = NEW.discussion_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER increment_replies AFTER INSERT ON discussion_replies FOR EACH ROW EXECUTE FUNCTION increment_replies_count();

-- Update profile and project stats on investment
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

CREATE TRIGGER update_investment_stats AFTER INSERT ON investments FOR EACH ROW EXECUTE FUNCTION update_investment_stats();

-- ============================================================
-- ROW-LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussions ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE investments ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Profiles: public read, owner update
CREATE POLICY "Profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Discussions: public read, author write
CREATE POLICY "Discussions are viewable by everyone" ON discussions FOR SELECT USING (true);
CREATE POLICY "Users can create discussions" ON discussions FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Users can update own discussions" ON discussions FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Users can delete own discussions" ON discussions FOR DELETE USING (auth.uid() = author_id);

-- Replies: public read, author write
CREATE POLICY "Replies are viewable by everyone" ON discussion_replies FOR SELECT USING (true);
CREATE POLICY "Users can create replies" ON discussion_replies FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Users can update own replies" ON discussion_replies FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Users can delete own replies" ON discussion_replies FOR DELETE USING (auth.uid() = author_id);

-- Likes: public read, user-specific create/delete
CREATE POLICY "Likes are viewable by everyone" ON discussion_likes FOR SELECT USING (true);
CREATE POLICY "Users can like items" ON discussion_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unlike items" ON discussion_likes FOR DELETE USING (auth.uid() = user_id);

-- Projects: public read, owner write
CREATE POLICY "Projects are viewable by everyone" ON projects FOR SELECT USING (true);
CREATE POLICY "Users can create projects" ON projects FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Users can update own projects" ON projects FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Users can delete own projects" ON projects FOR DELETE USING (auth.uid() = owner_id);

-- Investments: investors and project owners can read
CREATE POLICY "Users can see own investments" ON investments FOR SELECT USING (auth.uid() = investor_id);
CREATE POLICY "Project owners can see project investments" ON investments FOR SELECT USING (
  auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id)
);
CREATE POLICY "Users can create investments" ON investments FOR INSERT WITH CHECK (auth.uid() = investor_id);

-- Credit Transactions: users can only see own
CREATE POLICY "Users can see own credit transactions" ON credit_transactions FOR SELECT USING (auth.uid() = user_id);

-- Contributions: contributor and project owner can see
CREATE POLICY "Users can see own contributions" ON contributions FOR SELECT USING (auth.uid() = contributor_id);
CREATE POLICY "Project owners can see project contributions" ON contributions FOR SELECT USING (
  auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id)
);
CREATE POLICY "Users can create contributions" ON contributions FOR INSERT WITH CHECK (auth.uid() = contributor_id);

-- Subscriptions: users can only see own
CREATE POLICY "Users can see own subscriptions" ON subscriptions FOR SELECT USING (auth.uid() = user_id);

-- ============================================================
-- VIEWS
-- ============================================================

-- User portfolio view
CREATE VIEW user_portfolio AS
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
CREATE VIEW project_funding_summary AS
SELECT
  p.id AS project_id,
  p.title,
  p.funding_goal,
  p.funding_raised,
  p.backers_count,
  ROUND((p.funding_raised::NUMERIC / NULLIF(p.funding_goal, 0)) * 100, 2) AS funding_percentage,
  p.funding_deadline,
  p.status
FROM projects p;

-- Trending discussions (past 7 days)
CREATE VIEW trending_discussions AS
SELECT
  d.id,
  d.title,
  d.category,
  d.author_id,
  d.likes_count,
  d.replies_count,
  d.views_count,
  (d.likes_count * 2 + d.replies_count * 3) AS trending_score,
  d.created_at
FROM discussions d
WHERE d.created_at > NOW() - INTERVAL '7 days'
ORDER BY trending_score DESC;

-- ============================================================
-- SKILL CATEGORIES (Reference Data)
-- ============================================================

-- Skill categories table
CREATE TABLE IF NOT EXISTS skill_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  parent_category TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  color TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_skill_categories_parent ON skill_categories(parent_category);
CREATE INDEX IF NOT EXISTS idx_skill_categories_name ON skill_categories(name);

-- Populate with comprehensive skills
INSERT INTO skill_categories (name, parent_category, description, icon, color, display_order) VALUES
  -- TECHNICAL SKILLS
  ('Frontend Development', 'Technical', 'React, Vue, Angular, HTML/CSS', '💻', '#3B82F6', 1),
  ('Backend Development', 'Technical', 'Node.js, Python, Java, PHP', '⚙️', '#3B82F6', 2),
  ('Mobile Development', 'Technical', 'Flutter, React Native, iOS, Android', '📱', '#3B82F6', 3),
  ('DevOps & Cloud', 'Technical', 'AWS, Docker, Kubernetes, CI/CD', '☁️', '#3B82F6', 4),
  ('Data Science & AI', 'Technical', 'Machine Learning, Analytics, Python', '🤖', '#3B82F6', 5),
  ('Database Management', 'Technical', 'SQL, PostgreSQL, MongoDB, Redis', '🗄️', '#3B82F6', 6),
  ('Blockchain & Web3', 'Technical', 'Solidity, Smart Contracts, Crypto', '⛓️', '#3B82F6', 7),
  ('QA & Testing', 'Technical', 'Automated Testing, Quality Assurance', '🧪', '#3B82F6', 8),
  ('UI/UX Design', 'Technical', 'User Interface, User Experience Design', '🎨', '#3B82F6', 9),
  ('Cybersecurity', 'Technical', 'Security, Penetration Testing, Compliance', '🔒', '#3B82F6', 10),

  -- BUSINESS & FINANCE SKILLS
  ('Business Strategy', 'Business', 'Strategic Planning, Business Models', '📊', '#10B981', 1),
  ('Financial Planning', 'Business', 'Budgeting, Forecasting, Financial Modeling', '💰', '#10B981', 2),
  ('Fundraising', 'Business', 'VC Relations, Investor Pitching, Grants', '💸', '#10B981', 3),
  ('Accounting', 'Business', 'Bookkeeping, Financial Reporting, Tax', '🧮', '#10B981', 4),
  ('Budget Management', 'Business', 'Cost Control, Financial Planning', '💵', '#10B981', 5),
  ('Investor Relations', 'Business', 'Stakeholder Communication, Reporting', '🤝', '#10B981', 6),
  ('Grant Writing', 'Business', 'Proposal Writing, Non-Profit Funding', '✍️', '#10B981', 7),
  ('Business Development', 'Business', 'Partnerships, Sales, Growth', '📈', '#10B981', 8),
  ('Entrepreneurship', 'Business', 'Startup Building, Innovation', '🚀', '#10B981', 9),

  -- MARKETING & GROWTH SKILLS
  ('Digital Marketing', 'Marketing', 'Online Marketing Strategy, Campaigns', '📢', '#F59E0B', 1),
  ('Content Marketing', 'Marketing', 'Content Strategy, Blogging, Thought Leadership', '📝', '#F59E0B', 2),
  ('Social Media Marketing', 'Marketing', 'Facebook, Instagram, Twitter, LinkedIn', '📱', '#F59E0B', 3),
  ('SEO & SEM', 'Marketing', 'Search Engine Optimization, Google Ads', '🔍', '#F59E0B', 4),
  ('Email Marketing', 'Marketing', 'Campaigns, Automation, Newsletters', '📧', '#F59E0B', 5),
  ('Growth Hacking', 'Marketing', 'Rapid Experimentation, Viral Growth', '🚀', '#F59E0B', 6),
  ('PR & Communications', 'Marketing', 'Public Relations, Media, Press', '📰', '#F59E0B', 7),
  ('Brand Strategy', 'Marketing', 'Branding, Positioning, Identity', '🎯', '#F59E0B', 8),
  ('Copywriting', 'Marketing', 'Sales Copy, Ad Copy, Messaging', '✏️', '#F59E0B', 9),
  ('Community Management', 'Marketing', 'Online Communities, Engagement', '👥', '#F59E0B', 10),
  ('Influencer Marketing', 'Marketing', 'Partnerships, Sponsorships', '⭐', '#F59E0B', 11),
  ('Marketing Analytics', 'Marketing', 'Data Analysis, KPIs, ROI Tracking', '📊', '#F59E0B', 12),

  -- OPERATIONS & MANAGEMENT SKILLS
  ('Project Management', 'Operations', 'Planning, Execution, Agile, Scrum', '📋', '#8B5CF6', 1),
  ('Product Management', 'Operations', 'Product Strategy, Roadmaps, Features', '📦', '#8B5CF6', 2),
  ('Operations Management', 'Operations', 'Process Optimization, Efficiency', '⚙️', '#8B5CF6', 3),
  ('Supply Chain Management', 'Operations', 'Logistics, Procurement, Distribution', '🚚', '#8B5CF6', 4),
  ('Process Optimization', 'Operations', 'Lean, Six Sigma, Efficiency', '📈', '#8B5CF6', 5),
  ('Agile/Scrum Master', 'Operations', 'Agile Methodologies, Sprint Planning', '🏃', '#8B5CF6', 6),
  ('Customer Success', 'Operations', 'Client Relations, Retention, Support', '😊', '#8B5CF6', 7),
  ('HR & Recruiting', 'Operations', 'Hiring, Talent Acquisition, Culture', '👔', '#8B5CF6', 8),
  ('Event Planning', 'Operations', 'Conferences, Meetups, Coordination', '🎉', '#8B5CF6', 9),

  -- CREATIVE & DESIGN SKILLS
  ('Graphic Design', 'Creative', 'Visual Design, Branding, Print', '🎨', '#EC4899', 1),
  ('Video Production', 'Creative', 'Filming, Editing, Post-Production', '🎥', '#EC4899', 2),
  ('Animation', 'Creative', '2D/3D Animation, Motion Graphics', '🎬', '#EC4899', 3),
  ('Photography', 'Creative', 'Product, Portrait, Event Photography', '📷', '#EC4899', 4),
  ('Illustration', 'Creative', 'Digital Art, Drawing, Character Design', '🖌️', '#EC4899', 5),
  ('3D Modeling', 'Creative', '3D Design, Rendering, CAD', '🧊', '#EC4899', 6),
  ('Audio Production', 'Creative', 'Podcast, Music, Sound Design', '🎵', '#EC4899', 7),
  ('Content Writing', 'Creative', 'Articles, Blogs, Web Content', '✍️', '#EC4899', 8),
  ('Technical Writing', 'Creative', 'Documentation, Guides, Manuals', '📖', '#EC4899', 9),
  ('Voice Acting', 'Creative', 'Narration, Character Voices', '🎙️', '#EC4899', 10),

  -- LEGAL & COMPLIANCE SKILLS
  ('Business Law', 'Legal', 'Corporate Law, Business Regulations', '⚖️', '#6366F1', 1),
  ('Contract Negotiation', 'Legal', 'Agreements, Terms, Legal Review', '📜', '#6366F1', 2),
  ('Intellectual Property', 'Legal', 'Patents, Trademarks, Copyrights', '©️', '#6366F1', 3),
  ('Regulatory Compliance', 'Legal', 'Industry Regulations, Standards', '✅', '#6366F1', 4),
  ('Privacy & GDPR', 'Legal', 'Data Protection, Privacy Laws', '🔐', '#6366F1', 5),
  ('Employment Law', 'Legal', 'HR Legal, Labor Laws', '👔', '#6366F1', 6),

  -- DOMAIN EXPERTISE
  ('Healthcare', 'Domain', 'Medical, HealthTech, Clinical', '🏥', '#EF4444', 1),
  ('Education & EdTech', 'Domain', 'Teaching, Learning, Curriculum', '📚', '#EF4444', 2),
  ('Finance & FinTech', 'Domain', 'Banking, Payments, Financial Services', '💳', '#EF4444', 3),
  ('Climate & Sustainability', 'Domain', 'Environmental, Green Tech, ESG', '🌱', '#EF4444', 4),
  ('Non-Profit & Social Impact', 'Domain', 'Charity, Community, NGO', '❤️', '#EF4444', 5),
  ('Real Estate & PropTech', 'Domain', 'Property, Construction, Housing', '🏠', '#EF4444', 6),
  ('Agriculture & AgTech', 'Domain', 'Farming, Food Systems, Rural', '🌾', '#EF4444', 7),
  ('Government & Civic Tech', 'Domain', 'Public Sector, Policy, Governance', '🏛️', '#EF4444', 8),
  ('Retail & E-Commerce', 'Domain', 'Online Shopping, Stores, Logistics', '🛒', '#EF4444', 9),
  ('Travel & Hospitality', 'Domain', 'Tourism, Hotels, Transportation', '✈️', '#EF4444', 10),
  ('Sports & Fitness', 'Domain', 'Athletics, Wellness, Training', '⚽', '#EF4444', 11),
  ('Entertainment & Media', 'Domain', 'Film, Music, Gaming, Streaming', '🎮', '#EF4444', 12),

  -- SOFT SKILLS & LEADERSHIP
  ('Leadership', 'Soft Skills', 'Team Leadership, Management, Vision', '👑', '#06B6D4', 1),
  ('Mentorship', 'Soft Skills', 'Coaching, Guidance, Training', '🎓', '#06B6D4', 2),
  ('Public Speaking', 'Soft Skills', 'Presentations, Talks, Speaking', '🎤', '#06B6D4', 3),
  ('Networking', 'Soft Skills', 'Relationship Building, Connections', '🤝', '#06B6D4', 4),
  ('Sales', 'Soft Skills', 'Selling, Negotiation, Closing', '💼', '#06B6D4', 5),
  ('Customer Service', 'Soft Skills', 'Support, Client Relations', '📞', '#06B6D4', 6),
  ('Teaching & Training', 'Soft Skills', 'Education, Workshops, Facilitation', '👨‍🏫', '#06B6D4', 7),
  ('Research', 'Soft Skills', 'Analysis, Investigation, Studies', '🔬', '#06B6D4', 8),
  ('Consulting', 'Soft Skills', 'Advisory, Expert Guidance', '💡', '#06B6D4', 9)
ON CONFLICT (name) DO NOTHING;

-- Update profiles table to add primary expertise
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS primary_expertise TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS expertise_level TEXT DEFAULT 'intermediate';

-- Create index on primary_expertise for filtering
CREATE INDEX IF NOT EXISTS idx_profiles_primary_expertise ON profiles(primary_expertise);

-- Project roles table
CREATE TABLE IF NOT EXISTS project_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  role_category TEXT NOT NULL,
  role_title TEXT NOT NULL,
  description TEXT,
  skills_required TEXT[],
  is_filled BOOLEAN DEFAULT FALSE,
  filled_by UUID REFERENCES profiles(id),
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_project_roles_project_id ON project_roles(project_id);

ALTER TABLE projects ADD COLUMN IF NOT EXISTS total_roles_needed INTEGER DEFAULT 0;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS roles_filled INTEGER DEFAULT 0;

-- Role applications table
CREATE TABLE IF NOT EXISTS role_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  role_id UUID REFERENCES project_roles(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  match_score INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(role_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_role_applications_project ON role_applications(project_id);
CREATE INDEX IF NOT EXISTS idx_role_applications_user ON role_applications(user_id);
CREATE INDEX IF NOT EXISTS idx_role_applications_status ON role_applications(status);

-- Project members table
CREATE TABLE IF NOT EXISTS project_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role_id UUID REFERENCES project_roles(id) ON DELETE SET NULL,
  role_title TEXT NOT NULL,
  joined_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(project_id, user_id, role_id)
);

CREATE INDEX IF NOT EXISTS idx_project_members_project ON project_members(project_id);
CREATE INDEX IF NOT EXISTS idx_project_members_user ON project_members(user_id);
