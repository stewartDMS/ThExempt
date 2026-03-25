-- ============================================================================
-- Migration 004: Add Phase 1 systemic-change discussion categories
-- ============================================================================
-- Adds 'democracy', 'community_building', and 'technology' category slugs to
-- the discussion_categories lookup table so the app can filter and display them.
-- The discussions.category column is plain TEXT so no ALTER TABLE is required.
-- ============================================================================

-- Insert the three new systemic-change categories (idempotent: do nothing on conflict)
INSERT INTO discussion_categories (slug, name, description, icon, display_order)
VALUES
  ('democracy',         'Democracy',         'Voting rights, electoral reform, civic participation, open government', '🏛️', 20),
  ('community_building','Community',         'Mutual aid, grassroots organizing, local resilience',                   '🤝', 21),
  ('technology',        'Technology',        'Open source, digital rights, ethical AI, civic tech',                   '💻', 22)
ON CONFLICT (slug) DO NOTHING;

-- Update the column comment to document all current category values
COMMENT ON COLUMN discussions.category IS
  'Optional thread category. Values: world_problems | ideas | learning | live_events | networking | feedback | general | democracy | climate_crisis | economic_inequality | healthcare_access | education_reform | housing_justice | criminal_justice | immigration_justice | mental_health_crisis | community_building | technology. Nullable to allow posts without a category.';
