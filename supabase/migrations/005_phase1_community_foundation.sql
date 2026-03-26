-- ============================================================================
-- Migration 005 — Phase 1 Community Foundation
-- Idempotently adds all Phase 1 tables and columns that may be missing from
-- older databases that only ran the original schema bootstrap.
-- Safe to re-run (IF NOT EXISTS / ON CONFLICT DO NOTHING throughout).
-- ============================================================================

-- ── discussions — Phase 1 pipeline columns ──────────────────────────────────

ALTER TABLE discussions
  ADD COLUMN IF NOT EXISTS stage TEXT NOT NULL DEFAULT 'problem'
    CHECK (stage IN ('problem', 'solution', 'project_proposal', 'project_linked'));

ALTER TABLE discussions
  ADD COLUMN IF NOT EXISTS votes_count INTEGER NOT NULL DEFAULT 0;

ALTER TABLE discussions
  ADD COLUMN IF NOT EXISTS linked_project_id UUID REFERENCES projects(id) ON DELETE SET NULL;

-- ── discussion_votes ─────────────────────────────────────────────────────────
-- One upvote (+1) or downvote (-1) per user per discussion.

CREATE TABLE IF NOT EXISTS discussion_votes (
  id            UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id UUID     NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
  user_id       UUID     NOT NULL REFERENCES profiles(id)   ON DELETE CASCADE,
  value         SMALLINT NOT NULL DEFAULT 1 CHECK (value IN (1, -1)),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (discussion_id, user_id)
);

COMMENT ON TABLE  discussion_votes IS 'Upvotes/downvotes on pipeline discussions. One vote per user per discussion; value IN (1, -1).';
COMMENT ON COLUMN discussion_votes.value IS '1 = upvote, -1 = downvote';

-- ── discussion_resources ─────────────────────────────────────────────────────
-- Links, documents, videos, and datasets attached to a discussion thread.

CREATE TABLE IF NOT EXISTS discussion_resources (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id   UUID    NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
  uploaded_by     UUID    NOT NULL REFERENCES profiles(id)   ON DELETE CASCADE,
  resource_type   TEXT    NOT NULL DEFAULT 'link'
    CHECK (resource_type IN ('link', 'document', 'video', 'image', 'dataset')),
  title           TEXT    NOT NULL,
  description     TEXT,
  url             TEXT,
  file_name       TEXT,
  file_size       BIGINT  CHECK (file_size IS NULL OR file_size > 0),
  mime_type       TEXT,
  tags            TEXT[]  NOT NULL DEFAULT '{}',
  is_featured     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  discussion_resources IS 'Resources (links, docs, videos, datasets) attached to a discussion thread.';
COMMENT ON COLUMN discussion_resources.resource_type IS 'link | document | video | image | dataset';

-- ── user_expertise ────────────────────────────────────────────────────────────
-- Expertise areas claimed or verified for each user.

CREATE TABLE IF NOT EXISTS user_expertise (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  area          TEXT    NOT NULL,
  level         TEXT    NOT NULL DEFAULT 'self_declared'
    CHECK (level IN ('self_declared', 'community_verified', 'expert_verified', 'platform_verified')),
  evidence_url  TEXT,
  is_primary    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, area)
);

COMMENT ON TABLE user_expertise IS 'Expertise areas claimed or endorsed for each user; feeds trust_score and badge logic.';
COMMENT ON COLUMN user_expertise.level IS 'self_declared | community_verified | expert_verified | platform_verified';

-- ── expert_verifications ──────────────────────────────────────────────────────
-- Endorsement events; 3 community endorsements escalates level automatically.

CREATE TABLE IF NOT EXISTS expert_verifications (
  id                UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_expertise_id UUID    NOT NULL REFERENCES user_expertise(id) ON DELETE CASCADE,
  verified_by       UUID    NOT NULL REFERENCES profiles(id)       ON DELETE CASCADE,
  verification_type TEXT    NOT NULL DEFAULT 'community'
    CHECK (verification_type IN ('community', 'admin', 'credential')),
  notes             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_expertise_id, verified_by)
);

COMMENT ON TABLE expert_verifications IS 'Endorsement events for user expertise entries. 3+ community verifications auto-escalates level.';

-- ── profiles — badge/trust columns ──────────────────────────────────────────

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS trust_score INTEGER NOT NULL DEFAULT 0;

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS badges TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS expertise_areas TEXT[] NOT NULL DEFAULT '{}';

-- ── Indexes ──────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_discussions_stage          ON discussions(stage);
CREATE INDEX IF NOT EXISTS idx_discussions_linked_project ON discussions(linked_project_id) WHERE linked_project_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_discussion_votes_discussion ON discussion_votes(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_votes_user       ON discussion_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_discussion_resources_disc   ON discussion_resources(discussion_id);
CREATE INDEX IF NOT EXISTS idx_user_expertise_user         ON user_expertise(user_id);
CREATE INDEX IF NOT EXISTS idx_expert_verifications_exp    ON expert_verifications(user_expertise_id);

-- ── Trigger: sync votes_count on discussions ─────────────────────────────────

CREATE OR REPLACE FUNCTION sync_discussion_votes_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE discussions
  SET    votes_count = COALESCE(
           (SELECT SUM(value) FROM discussion_votes WHERE discussion_id = COALESCE(NEW.discussion_id, OLD.discussion_id)),
           0
         )
  WHERE  id = COALESCE(NEW.discussion_id, OLD.discussion_id);
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_discussion_votes ON discussion_votes;
CREATE TRIGGER trg_sync_discussion_votes
AFTER INSERT OR UPDATE OR DELETE ON discussion_votes
FOR EACH ROW EXECUTE FUNCTION sync_discussion_votes_count();

-- ── RLS ──────────────────────────────────────────────────────────────────────

ALTER TABLE discussion_votes    ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_expertise       ENABLE ROW LEVEL SECURITY;
ALTER TABLE expert_verifications ENABLE ROW LEVEL SECURITY;

-- discussion_votes
CREATE POLICY IF NOT EXISTS "Anyone can read discussion votes"
  ON discussion_votes FOR SELECT USING (true);

CREATE POLICY IF NOT EXISTS "Authenticated users can vote"
  ON discussion_votes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can update own vote"
  ON discussion_votes FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can delete own vote"
  ON discussion_votes FOR DELETE
  USING (auth.uid() = user_id);

-- discussion_resources
CREATE POLICY IF NOT EXISTS "Anyone can read resources"
  ON discussion_resources FOR SELECT USING (true);

CREATE POLICY IF NOT EXISTS "Authenticated users can add resources"
  ON discussion_resources FOR INSERT
  WITH CHECK (auth.uid() = uploaded_by);

CREATE POLICY IF NOT EXISTS "Users can update own resources"
  ON discussion_resources FOR UPDATE
  USING (auth.uid() = uploaded_by);

CREATE POLICY IF NOT EXISTS "Users can delete own resources"
  ON discussion_resources FOR DELETE
  USING (auth.uid() = uploaded_by);

-- user_expertise
CREATE POLICY IF NOT EXISTS "Anyone can read expertise"
  ON user_expertise FOR SELECT USING (true);

CREATE POLICY IF NOT EXISTS "Users can manage own expertise"
  ON user_expertise FOR ALL
  USING (auth.uid() = user_id);

-- expert_verifications
CREATE POLICY IF NOT EXISTS "Anyone can read verifications"
  ON expert_verifications FOR SELECT USING (true);

CREATE POLICY IF NOT EXISTS "Authenticated users can verify"
  ON expert_verifications FOR INSERT
  WITH CHECK (auth.uid() = verified_by AND auth.uid() != (
    SELECT user_id FROM user_expertise WHERE id = user_expertise_id
  ));

-- ── Phase 1 seed: discussion_categories ──────────────────────────────────────

INSERT INTO discussion_categories (slug, name, description, icon, color, display_order, is_systemic)
VALUES
  ('democracy',              '🏛️ Democracy',               'Voting rights, electoral reform, civic participation, open government',            '🏛️', '#1565C0', 10, true),
  ('climate_crisis',         '🌡️ Climate Crisis',           'Climate change, environmental justice, clean energy',                               '🌡️', '#E53935', 20, true),
  ('economic_inequality',    '⚖️ Economic Inequality',      'Wealth gaps, fair wages, economic justice',                                          '⚖️', '#FB8C00', 30, true),
  ('healthcare_access',      '🏥 Healthcare Access',        'Universal healthcare, mental health, public health',                                  '🏥', '#E91E63', 40, true),
  ('education_reform',       '📚 Education Reform',         'Public education, student debt, lifelong learning',                                   '📚', '#3F51B5', 50, true),
  ('housing_justice',        '🏠 Housing Justice',          'Affordable housing, homelessness, tenant rights',                                     '🏠', '#009688', 60, true),
  ('criminal_justice',       '🔒 Criminal Justice',         'Policing reform, prison abolition, restorative justice',                              '🔒', '#795548', 70, true),
  ('immigration_justice',    '🌐 Immigration Justice',      'Immigration reform, refugee support, human rights',                                   '🌐', '#607D8B', 80, true),
  ('mental_health_crisis',   '🧠 Mental Health Crisis',     'Mental health access, stigma reduction, support systems',                             '🧠', '#9C27B0', 90, true),
  ('community_building',     '🤝 Community',                'Mutual aid, grassroots organizing, local resilience',                                 '🤝', '#43A047', 100, true),
  ('technology',             '💻 Technology',               'Open source, digital rights, ethical AI, civic tech',                                 '💻', '#00ACC1', 110, true)
ON CONFLICT (slug) DO NOTHING;
