-- ============================================================
-- SEED DATA FOR TESTING
-- ============================================================
-- NOTE: Requires auth.users to exist first.
-- Sign up users via Supabase Auth, then replace the placeholder
-- UUIDs below with real UUIDs from auth.users before running.
-- ============================================================

-- Example profiles (replace UUIDs with real auth.users IDs)
-- ON CONFLICT handles idempotent re-runs after the placeholders are replaced with real UUIDs.
INSERT INTO profiles (id, username, full_name, bio) VALUES
('USER_ID_1', 'alex_changemaker', 'Alex Rivera', 'Climate organizer, community builder'),
('USER_ID_2', 'sam_builder', 'Sam Chen', 'Full-stack developer passionate about civic tech'),
('USER_ID_3', 'jordan_founder', 'Jordan Taylor', 'Serial social entrepreneur')
ON CONFLICT (id) DO NOTHING;

-- Test projects
INSERT INTO projects (owner_id, title, tagline, description, category, status, tags) VALUES
('USER_ID_3', 'Open Source Community Land Trust Platform', 'Making housing affordable through tech', 'Building open source software to help communities create and manage community land trusts. This platform will enable grassroots organizations to manage properties, track affordability covenants, and engage residents.', 'civic_tech', 'active', ARRAY['housing', 'open-source', 'cooperative'])
ON CONFLICT DO NOTHING;

-- Test contributions
INSERT INTO contributions (contributor_id, project_id, title, description, contribution_type, status, hours_worked, tags) VALUES
('USER_ID_1',
  (SELECT id FROM projects WHERE title = 'Open Source Community Land Trust Platform' LIMIT 1),
  'Community outreach strategy',
  'Developed outreach plan to engage 10 local housing organizations.',
  'advocacy',
  'verified',
  8,
  ARRAY['outreach', 'housing']),
('USER_ID_2',
  (SELECT id FROM projects WHERE title = 'Open Source Community Land Trust Platform' LIMIT 1),
  'Initial Flutter mobile app scaffold',
  'Set up Flutter project with routing, state management, and Supabase integration.',
  'code',
  'pending',
  12,
  ARRAY['flutter', 'mobile'])
ON CONFLICT DO NOTHING;

-- Test discussions
INSERT INTO discussions (author_id, category, title, content, tags) VALUES
('USER_ID_1', 'world_problems', 'Why is housing unaffordable?', 'Let''s discuss the root causes of the housing crisis and what communities can do about it.', ARRAY['housing', 'economics', 'policy']),
('USER_ID_2', 'ideas', 'Community Land Trusts as a solution', 'Here''s how we can make housing affordable forever through community land trusts...', ARRAY['housing', 'solution', 'cooperative']),
('USER_ID_3', 'networking', 'Looking for co-founders with civic tech experience', 'Building a platform to connect community organizers. Need technical co-founder.', ARRAY['co-founder', 'civic-tech', 'networking'])
ON CONFLICT DO NOTHING;

-- Test project update
INSERT INTO project_updates (project_id, author_id, title, content) VALUES
((SELECT id FROM projects WHERE title = 'Open Source Community Land Trust Platform' LIMIT 1),
 'USER_ID_3',
 'Week 1 update: Project kickoff',
 'We have officially kicked off the project! Our first sprint will focus on core data models and authentication.')
ON CONFLICT DO NOTHING;
