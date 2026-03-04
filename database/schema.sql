-- Skill categories table
CREATE TABLE IF NOT EXISTS skill_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role_id UUID REFERENCES project_roles(id) ON DELETE SET NULL,
  role_title TEXT NOT NULL,
  joined_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(project_id, user_id, role_id)
);

CREATE INDEX IF NOT EXISTS idx_project_members_project ON project_members(project_id);
CREATE INDEX IF NOT EXISTS idx_project_members_user ON project_members(user_id);
