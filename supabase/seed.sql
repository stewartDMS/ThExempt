-- ============================================================================
-- ThExempt Platform — Seed Data
-- ============================================================================
-- Sample data for local development and testing.
--
-- IMPORTANT: Replace USER_ID_1, USER_ID_2, USER_ID_3 with real UUIDs from
-- auth.users after signing up test accounts via Supabase Auth, then run this
-- file in the Supabase SQL Editor.
-- ============================================================================


-- ─── Profiles ─────────────────────────────────────────────────────────────
INSERT INTO profiles (id, username, full_name, bio, membership_tier, total_credits, trust_score, primary_expertise) VALUES
  ('USER_ID_1', 'alex_changemaker', 'Alex Rivera',   'Climate organizer and community builder with 5 years in grassroots activism.',         'changemaker',      100,  72, 'Community Organizing'),
  ('USER_ID_2', 'sam_builder',      'Sam Chen',      'Full-stack developer passionate about civic tech and open source.',                     'movement_builder', 500,  88, 'Backend Development'),
  ('USER_ID_3', 'jordan_founder',   'Jordan Taylor', 'Serial social entrepreneur. Building tools for the people who fix things.',             'founding_partner', 2000, 95, 'Business Strategy');


-- ─── Discussions ──────────────────────────────────────────────────────────
INSERT INTO discussions (author_id, category, title, content, tags) VALUES
  ('USER_ID_1', 'world_problems',
   'Why is housing still unaffordable in 2024?',
   'Despite decades of policy debate, housing costs have outpaced wages everywhere. Let''s break down the structural causes and what communities can actually do.',
   ARRAY['housing', 'economics', 'policy']),

  ('USER_ID_2', 'ideas',
   'Community Land Trusts: a permanent affordability solution',
   'CLTs remove land from the speculative market, keeping homes affordable forever. Here''s how they work and how we can scale them with technology.',
   ARRAY['housing', 'solution', 'cooperative', 'civic-tech']),

  ('USER_ID_3', 'networking',
   'Looking for a Flutter co-founder with civic tech experience',
   'Building a platform to connect community organizers nationwide. Need a technical co-founder who cares as much about impact as code quality.',
   ARRAY['co-founder', 'flutter', 'civic-tech', 'networking']);


-- ─── Projects ─────────────────────────────────────────────────────────────
INSERT INTO projects (
  owner_id, title, tagline, description, problem_statement, solution_approach,
  category, funding_goal, equity_offered, min_investment, status, tags, published_at
) VALUES (
  'USER_ID_3',
  'Open Source Community Land Trust Platform',
  'Making housing affordable — forever',
  'Open source software to help communities create and manage community land trusts. Enables grassroots organizations to manage properties, track affordability covenants, and engage residents.',
  'CLT management is done through spreadsheets and outdated software. Grassroots organizations lack the tools to scale.',
  'A modern, mobile-first platform built on Supabase + Flutter that CLTs can deploy in days, not months.',
  'civic_tech',
  5000, 5.00, 10, 'active',
  ARRAY['housing', 'open-source', 'cooperative', 'civic-tech'],
  NOW()
);


-- ─── Project Milestones ───────────────────────────────────────────────────
INSERT INTO project_milestones (project_id, title, description, due_date, display_order)
SELECT
  id,
  milestone_title,
  milestone_description,
  milestone_due,
  milestone_order
FROM projects
CROSS JOIN (VALUES
  ('MVP Launch',        'Core CLT management features: property tracking, affordability covenants, resident portal.',          NOW() + INTERVAL '3 months',  1),
  ('Beta with 5 CLTs',  'Onboard 5 community land trusts for beta testing and gather structured feedback.',                    NOW() + INTERVAL '6 months',  2),
  ('Public Launch',     'Open the platform to all CLTs nationally; publish documentation and onboarding guide.',               NOW() + INTERVAL '12 months', 3)
) AS milestones(milestone_title, milestone_description, milestone_due, milestone_order)
WHERE title = 'Open Source Community Land Trust Platform';


-- ─── Project Roles ────────────────────────────────────────────────────────
INSERT INTO project_roles (project_id, role_category, role_title, description, skills_required, display_order)
SELECT
  p.id,
  role_category,
  role_title,
  role_description,
  role_skills,
  role_order
FROM projects p
CROSS JOIN (VALUES
  ('Technical',   'Flutter Mobile Developer',       'Build the mobile app component. Strong Flutter/Dart skills required; Supabase experience is a plus.',     ARRAY['Mobile Development', 'Frontend Development'], 1),
  ('Operations',  'Community Partnerships Manager', 'Liaise with CLT partner organisations, gather requirements, and coordinate the beta rollout.',             ARRAY['Community Management', 'Non-Profit & Social Impact'], 2)
) AS roles(role_category, role_title, role_description, role_skills, role_order)
WHERE p.title = 'Open Source Community Land Trust Platform';


-- ─── Skills ───────────────────────────────────────────────────────────────
INSERT INTO skills (user_id, skill_name, proficiency, years_experience) VALUES
  ('USER_ID_1', 'Community Organizing', 'expert',       5),
  ('USER_ID_1', 'Grant Writing',        'intermediate', 3),
  ('USER_ID_2', 'Frontend Development', 'expert',       7),
  ('USER_ID_2', 'Backend Development',  'expert',       6),
  ('USER_ID_3', 'Business Strategy',    'expert',      10),
  ('USER_ID_3', 'Fundraising',          'expert',       8);


-- ─── Skill Offers ─────────────────────────────────────────────────────────
INSERT INTO skill_offers (user_id, title, description, skill_categories, rate_credits_per_hour, available_hours_per_week) VALUES
  ('USER_ID_2',
   'Full-Stack Development for Social Impact',
   'Available to build web/mobile applications for civic tech projects. React, Node.js, Flutter, and Supabase.',
   ARRAY['Frontend Development', 'Backend Development', 'Mobile Development'],
   50, 10);


-- ─── Skill Requests ───────────────────────────────────────────────────────
INSERT INTO skill_requests (requester_id, project_id, title, description, skill_categories, budget_credits, equity_offered)
SELECT
  'USER_ID_3',
  p.id,
  'Need Flutter Mobile Developer',
  'Looking for an experienced Flutter developer to build the mobile app. Budget: 500 credits or 1% equity.',
  ARRAY['Mobile Development'],
  500, 1.00
FROM projects p
WHERE p.title = 'Open Source Community Land Trust Platform';


-- ─── Investments ──────────────────────────────────────────────────────────
INSERT INTO investments (investor_id, project_id, credits_invested, equity_percentage)
SELECT 'USER_ID_1', p.id, 100, 0.50 FROM projects p WHERE p.title = 'Open Source Community Land Trust Platform'
UNION ALL
SELECT 'USER_ID_2', p.id, 500, 2.50 FROM projects p WHERE p.title = 'Open Source Community Land Trust Platform';


-- ─── Credit Transactions ──────────────────────────────────────────────────
INSERT INTO credit_transactions (user_id, amount, balance_after, transaction_type, description) VALUES
  ('USER_ID_1',  100,   100, 'subscription_credit', 'Monthly credits — Changemaker subscription'),
  ('USER_ID_2',  500,   500, 'subscription_credit', 'Monthly credits — Movement Builder subscription'),
  ('USER_ID_3', 2000,  2000, 'subscription_credit', 'Monthly credits — Founding Partner subscription'),
  ('USER_ID_1', -100,     0, 'investment_debit',     'Investment in Open Source Community Land Trust Platform');


-- ─── Subscriptions ────────────────────────────────────────────────────────
INSERT INTO subscriptions (user_id, stripe_subscription_id, stripe_price_id, tier, status, current_period_start, current_period_end) VALUES
  ('USER_ID_1', 'sub_test_changemaker',      'price_changemaker_monthly',      'changemaker',     'active', NOW(), NOW() + INTERVAL '1 month'),
  ('USER_ID_2', 'sub_test_movement_builder', 'price_movement_builder_monthly', 'movement_builder','active', NOW(), NOW() + INTERVAL '1 month'),
  ('USER_ID_3', 'sub_test_founding_partner', 'price_founding_partner_monthly', 'founding_partner','active', NOW(), NOW() + INTERVAL '1 month');


-- ─── Follows ──────────────────────────────────────────────────────────────
INSERT INTO follows (follower_id, following_id) VALUES
  ('USER_ID_1', 'USER_ID_3'),
  ('USER_ID_2', 'USER_ID_3'),
  ('USER_ID_1', 'USER_ID_2');


-- ─── Project Update ───────────────────────────────────────────────────────
INSERT INTO project_updates (project_id, author_id, title, content, update_type)
SELECT
  p.id,
  'USER_ID_3',
  'We''re live on ThExempt! 🎉',
  'Excited to launch our funding campaign. We''ve already had two early investors — every credit helps build the future of community housing!',
  'funding'
FROM projects p
WHERE p.title = 'Open Source Community Land Trust Platform';
