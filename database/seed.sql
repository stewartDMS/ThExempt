-- ============================================================
-- SEED DATA FOR TESTING
-- ============================================================
-- NOTE: Requires auth.users to exist first.
-- Sign up users via Supabase Auth, then replace the placeholder
-- UUIDs below with real UUIDs from auth.users before running.
-- ============================================================

-- Example profiles (replace UUIDs with real auth.users IDs)
INSERT INTO profiles (id, username, full_name, bio, membership_tier, total_credits) VALUES
('USER_ID_1', 'alex_changemaker', 'Alex Rivera', 'Climate organizer, community builder', 'changemaker', 100),
('USER_ID_2', 'sam_builder', 'Sam Chen', 'Full-stack developer passionate about civic tech', 'movement_builder', 500),
('USER_ID_3', 'jordan_founder', 'Jordan Taylor', 'Serial social entrepreneur', 'founding_partner', 2000);

-- Test discussions
INSERT INTO discussions (author_id, category, title, content, tags) VALUES
('USER_ID_1', 'world_problems', 'Why is housing unaffordable?', 'Let''s discuss the root causes of the housing crisis and what communities can do about it.', ARRAY['housing', 'economics', 'policy']),
('USER_ID_2', 'ideas', 'Community Land Trusts as a solution', 'Here''s how we can make housing affordable forever through community land trusts...', ARRAY['housing', 'solution', 'cooperative']),
('USER_ID_3', 'networking', 'Looking for co-founders with civic tech experience', 'Building a platform to connect community organizers. Need technical co-founder.', ARRAY['co-founder', 'civic-tech', 'networking']);

-- Test projects
INSERT INTO projects (owner_id, title, tagline, description, category, funding_goal, equity_offered, status, tags) VALUES
('USER_ID_3', 'Open Source Community Land Trust Platform', 'Making housing affordable through tech', 'Building open source software to help communities create and manage community land trusts. This platform will enable grassroots organizations to manage properties, track affordability covenants, and engage residents.', 'civic_tech', 5000, 5, 'active', ARRAY['housing', 'open-source', 'cooperative']);

-- Test investments (depends on profiles and projects above)
INSERT INTO investments (investor_id, project_id, credits_invested, equity_percentage) VALUES
('USER_ID_1', (SELECT id FROM projects WHERE title = 'Open Source Community Land Trust Platform' LIMIT 1), 100, 0.50),
('USER_ID_2', (SELECT id FROM projects WHERE title = 'Open Source Community Land Trust Platform' LIMIT 1), 500, 2.50);

-- Test credit transactions
INSERT INTO credit_transactions (user_id, amount, balance_after, transaction_type, description) VALUES
('USER_ID_1', 100, 100, 'subscription', 'Monthly credits from Changemaker subscription'),
('USER_ID_2', 500, 500, 'subscription', 'Monthly credits from Movement Builder subscription'),
('USER_ID_3', 2000, 2000, 'subscription', 'Monthly credits from Founding Partner subscription');

-- Test subscriptions
INSERT INTO subscriptions (user_id, stripe_subscription_id, stripe_price_id, tier, status, current_period_start, current_period_end) VALUES
('USER_ID_1', 'sub_test_changemaker', 'price_changemaker_monthly', 'changemaker', 'active', NOW(), NOW() + INTERVAL '1 month'),
('USER_ID_2', 'sub_test_movement_builder', 'price_movement_builder_monthly', 'movement_builder', 'active', NOW(), NOW() + INTERVAL '1 month'),
('USER_ID_3', 'sub_test_founding_partner', 'price_founding_partner_monthly', 'founding_partner', 'active', NOW(), NOW() + INTERVAL '1 month');

-- Test skills
INSERT INTO skills (user_id, skill_name, skill_category, proficiency, years_experience) VALUES
('USER_ID_1', 'Community Organizing', 'Soft Skills', 'expert', 5),
('USER_ID_1', 'Grant Writing', 'Business', 'intermediate', 3),
('USER_ID_2', 'Frontend Development', 'Technical', 'expert', 7),
('USER_ID_2', 'Backend Development', 'Technical', 'expert', 6),
('USER_ID_3', 'Business Strategy', 'Business', 'expert', 10),
('USER_ID_3', 'Fundraising', 'Business', 'expert', 8);

-- Test skill offers
INSERT INTO skill_offers (user_id, title, description, skill_categories, rate_credits_per_hour, available_hours_per_week) VALUES
('USER_ID_2', 'Full-Stack Development for Social Impact', 'Available to build web applications for civic tech projects. Experienced with React, Node.js, and PostgreSQL.', ARRAY['Technical'], 50, 10);

-- Test skill requests
INSERT INTO skill_requests (requester_id, project_id, title, description, skill_categories, budget_credits, equity_offered, status) VALUES
('USER_ID_3',
  (SELECT id FROM projects WHERE title = 'Open Source Community Land Trust Platform' LIMIT 1),
  'Need Flutter Mobile Developer',
  'Looking for an experienced Flutter developer to build the mobile app component of our community land trust platform.',
  ARRAY['Technical'],
  500,
  1.00,
  'open');

-- Test project milestones
INSERT INTO project_milestones (project_id, title, description, due_date, display_order) VALUES
((SELECT id FROM projects WHERE title = 'Open Source Community Land Trust Platform' LIMIT 1), 'MVP Launch', 'Launch the minimum viable product with core land trust management features', NOW() + INTERVAL '3 months', 1),
((SELECT id FROM projects WHERE title = 'Open Source Community Land Trust Platform' LIMIT 1), 'Beta Testing with 5 CLTs', 'Onboard 5 community land trusts for beta testing and feedback', NOW() + INTERVAL '6 months', 2),
((SELECT id FROM projects WHERE title = 'Open Source Community Land Trust Platform' LIMIT 1), 'Public Launch', 'Open the platform to all community land trusts nationally', NOW() + INTERVAL '12 months', 3);
