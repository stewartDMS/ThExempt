-- ============================================================================
-- Migration 001 — Phase 1: Community Foundation
-- Apply this script against an existing database that was created from the
-- schema BEFORE Phase 1.  It is idempotent (safe to re-run).
-- ============================================================================
-- Covers four workstreams:
--   A) Enhanced systemic discussion categories (new table + expanded CHECK)
--   B) Problem → Solution → Project pipeline   (new columns + discussion_votes)
--   C) Expert badges & trust system            (user_expertise, expert_verifications)
--   D) Resource library within discussions     (discussion_resources)
-- ============================================================================

BEGIN;

-- ============================================================================
-- A) discussion_categories table
-- ============================================================================

CREATE TABLE IF NOT EXISTS discussion_categories (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  slug          TEXT    UNIQUE NOT NULL,
  label         TEXT    NOT NULL,
  description   TEXT    NOT NULL DEFAULT '',
  emoji         TEXT    NOT NULL DEFAULT '',
  color_hex     TEXT    NOT NULL DEFAULT '#666666',
  is_systemic   BOOLEAN NOT NULL DEFAULT FALSE,
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  discussion_categories IS 'Canonical taxonomy of discussion categories. Slugs are used in discussions.category for validation and filtering.';
COMMENT ON COLUMN discussion_categories.slug        IS 'Machine-readable key used in discussions.category and API filters.';
COMMENT ON COLUMN discussion_categories.is_systemic IS 'TRUE for high-priority systemic issue categories.';

ALTER TABLE discussion_categories ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'discussion_categories'
      AND policyname = 'discussion_categories_select_public'
  ) THEN
    EXECUTE 'CREATE POLICY "discussion_categories_select_public"
      ON discussion_categories FOR SELECT USING (is_active = TRUE)';
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_discussion_categories_slug     ON discussion_categories(slug);
CREATE INDEX IF NOT EXISTS idx_discussion_categories_systemic ON discussion_categories(is_systemic) WHERE is_systemic = TRUE;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'trg_discussion_categories_updated_at'
  ) THEN
    EXECUTE 'CREATE TRIGGER trg_discussion_categories_updated_at
      BEFORE UPDATE ON discussion_categories
      FOR EACH ROW EXECUTE FUNCTION set_updated_at()';
  END IF;
END
$$;

-- Seed all categories
INSERT INTO discussion_categories (slug, label, description, emoji, color_hex, is_systemic, display_order) VALUES
  ('world_problems',       '🌍 World Problems',         'Discuss global challenges to solve',                    '🌍', '#057642', FALSE,  1),
  ('ideas',                '💡 Ideas & Brainstorming',   'Share startup ideas, get feedback',                     '💡', '#F5A623', FALSE,  2),
  ('learning',             '🎓 Learning & Resources',    'Share knowledge, tutorials',                            '🎓', '#0A66C2', FALSE,  3),
  ('live_events',          '🎤 Live Events',             'Upcoming training, workshops, AMAs',                    '🎤', '#CC1016', FALSE,  4),
  ('networking',           '🤝 Networking',              'Introductions, looking for co-founders',                '🤝', '#7B61FF', FALSE,  5),
  ('feedback',             '🐛 Feedback',                'Platform suggestions, bug reports',                     '🐛', '#E91E8C', FALSE,  6),
  ('general',              '💬 General',                 'Off-topic, community chat',                             '💬', '#666666', FALSE,  7),
  ('climate_crisis',       '🌡️ Climate Crisis',          'Climate change, environmental justice, clean energy',   '🌡️', '#E53935', TRUE,  10),
  ('economic_inequality',  '⚖️ Economic Inequality',     'Wealth gaps, fair wages, economic justice',             '⚖️', '#FB8C00', TRUE,  11),
  ('healthcare_access',    '🏥 Healthcare Access',       'Universal healthcare, mental health, public health',    '🏥', '#E91E63', TRUE,  12),
  ('education_reform',     '📚 Education Reform',        'Public education, student debt, lifelong learning',     '📚', '#3F51B5', TRUE,  13),
  ('housing_justice',      '🏠 Housing Justice',         'Affordable housing, homelessness, tenant rights',       '🏠', '#009688', TRUE,  14),
  ('criminal_justice',     '🔒 Criminal Justice',        'Policing reform, prison abolition, restorative justice','🔒', '#795548', TRUE,  15),
  ('immigration_justice',  '🌐 Immigration Justice',     'Immigration reform, refugee support, human rights',     '🌐', '#607D8B', TRUE,  16),
  ('mental_health_crisis', '🧠 Mental Health Crisis',    'Mental health access, stigma reduction, support systems','🧠', '#9C27B0', TRUE,  17)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- A) Expand discussions.category CHECK constraint
-- ============================================================================

ALTER TABLE discussions
  DROP CONSTRAINT IF EXISTS discussions_category_check;

ALTER TABLE discussions
  ADD CONSTRAINT discussions_category_check
  CHECK (category IN (
    'world_problems', 'ideas', 'learning', 'live_events', 'networking', 'feedback', 'general',
    'climate_crisis', 'economic_inequality', 'healthcare_access', 'education_reform',
    'housing_justice', 'criminal_justice', 'immigration_justice', 'mental_health_crisis'
  ));

-- ============================================================================
-- B) Problem → Solution → Project pipeline columns
-- ============================================================================

ALTER TABLE discussions
  ADD COLUMN IF NOT EXISTS stage             TEXT        NOT NULL DEFAULT 'problem'
    CHECK (stage IN ('problem', 'solution', 'project_proposal', 'project_linked')),
  ADD COLUMN IF NOT EXISTS votes_count       INTEGER     NOT NULL DEFAULT 0 CHECK (votes_count >= 0),
  ADD COLUMN IF NOT EXISTS linked_project_id UUID        REFERENCES projects(id) ON DELETE SET NULL;

COMMENT ON COLUMN discussions.stage             IS 'Pipeline stage: problem → solution → project_proposal → project_linked';
COMMENT ON COLUMN discussions.votes_count       IS 'Cached net vote tally; maintained by sync_discussion_votes_count trigger.';
COMMENT ON COLUMN discussions.linked_project_id IS 'Set when stage = project_linked; points to the project that emerged from this discussion.';

CREATE INDEX IF NOT EXISTS idx_discussions_stage          ON discussions(stage);
CREATE INDEX IF NOT EXISTS idx_discussions_linked_project ON discussions(linked_project_id) WHERE linked_project_id IS NOT NULL;

-- discussion_votes
CREATE TABLE IF NOT EXISTS discussion_votes (
  id            UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id UUID     NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
  user_id       UUID     NOT NULL REFERENCES profiles(id)   ON DELETE CASCADE,
  value         SMALLINT NOT NULL DEFAULT 1 CHECK (value IN (1, -1)),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (discussion_id, user_id)
);

COMMENT ON TABLE  discussion_votes IS 'Upvotes/downvotes on pipeline discussions. One vote per user per discussion.';
COMMENT ON COLUMN discussion_votes.value IS '1 = upvote, -1 = downvote';

ALTER TABLE discussion_votes ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='discussion_votes' AND policyname='discussion_votes_select_public') THEN
    EXECUTE 'CREATE POLICY "discussion_votes_select_public" ON discussion_votes FOR SELECT USING (TRUE)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='discussion_votes' AND policyname='discussion_votes_insert_own') THEN
    EXECUTE 'CREATE POLICY "discussion_votes_insert_own" ON discussion_votes FOR INSERT WITH CHECK (auth.uid() = user_id)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='discussion_votes' AND policyname='discussion_votes_update_own') THEN
    EXECUTE 'CREATE POLICY "discussion_votes_update_own" ON discussion_votes FOR UPDATE USING (auth.uid() = user_id)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='discussion_votes' AND policyname='discussion_votes_delete_own') THEN
    EXECUTE 'CREATE POLICY "discussion_votes_delete_own" ON discussion_votes FOR DELETE USING (auth.uid() = user_id)';
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_discussion_votes_discussion ON discussion_votes(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_votes_user       ON discussion_votes(user_id);

-- Vote-count sync trigger
CREATE OR REPLACE FUNCTION sync_discussion_votes_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE discussions
  SET    votes_count = (
    SELECT COALESCE(SUM(value), 0)
    FROM   discussion_votes
    WHERE  discussion_id = COALESCE(NEW.discussion_id, OLD.discussion_id)
  )
  WHERE id = COALESCE(NEW.discussion_id, OLD.discussion_id);
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_discussion_votes ON discussion_votes;
CREATE TRIGGER trg_sync_discussion_votes
  AFTER INSERT OR UPDATE OR DELETE ON discussion_votes
  FOR EACH ROW EXECUTE FUNCTION sync_discussion_votes_count();

-- ============================================================================
-- C) Expert badges & trust system
-- ============================================================================

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

COMMENT ON TABLE  user_expertise IS 'Expertise areas claimed or verified per user. Level escalates as endorsements accumulate.';
COMMENT ON COLUMN user_expertise.level        IS 'self_declared → community_verified → expert_verified → platform_verified';
COMMENT ON COLUMN user_expertise.is_primary   IS 'TRUE for the user primary expertise area.';
COMMENT ON COLUMN user_expertise.evidence_url IS 'Optional link to credential, publication, or other proof.';

ALTER TABLE user_expertise ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_expertise' AND policyname='user_expertise_select_public') THEN
    EXECUTE 'CREATE POLICY "user_expertise_select_public" ON user_expertise FOR SELECT USING (TRUE)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_expertise' AND policyname='user_expertise_insert_own') THEN
    EXECUTE 'CREATE POLICY "user_expertise_insert_own" ON user_expertise FOR INSERT WITH CHECK (auth.uid() = user_id)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_expertise' AND policyname='user_expertise_update_own') THEN
    EXECUTE 'CREATE POLICY "user_expertise_update_own" ON user_expertise FOR UPDATE USING (auth.uid() = user_id)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_expertise' AND policyname='user_expertise_delete_own') THEN
    EXECUTE 'CREATE POLICY "user_expertise_delete_own" ON user_expertise FOR DELETE USING (auth.uid() = user_id)';
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_user_expertise_user ON user_expertise(user_id);
CREATE INDEX IF NOT EXISTS idx_user_expertise_area ON user_expertise(area);

DROP TRIGGER IF EXISTS trg_user_expertise_updated_at ON user_expertise;
CREATE TRIGGER trg_user_expertise_updated_at
  BEFORE UPDATE ON user_expertise
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- expert_verifications
CREATE TABLE IF NOT EXISTS expert_verifications (
  id                  UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_expertise_id   UUID    NOT NULL REFERENCES user_expertise(id) ON DELETE CASCADE,
  verified_by         UUID    REFERENCES profiles(id) ON DELETE SET NULL,
  verification_type   TEXT    NOT NULL DEFAULT 'community'
    CHECK (verification_type IN ('community', 'admin', 'credential')),
  notes               TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  expert_verifications IS 'Verification events for user expertise entries. Each row raises the target user trust_score.';
COMMENT ON COLUMN expert_verifications.verified_by       IS 'NULL = platform/admin verification; otherwise the endorsing user.';
COMMENT ON COLUMN expert_verifications.verification_type IS 'community = peer endorsement; admin = staff approval; credential = verified credential.';

ALTER TABLE expert_verifications ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='expert_verifications' AND policyname='expert_verifications_select_public') THEN
    EXECUTE 'CREATE POLICY "expert_verifications_select_public" ON expert_verifications FOR SELECT USING (TRUE)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='expert_verifications' AND policyname='expert_verifications_insert_authenticated') THEN
    EXECUTE 'CREATE POLICY "expert_verifications_insert_authenticated"
      ON expert_verifications FOR INSERT
      WITH CHECK (auth.uid() = verified_by OR verified_by IS NULL)';
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_expert_verifications_expertise ON expert_verifications(user_expertise_id);
CREATE INDEX IF NOT EXISTS idx_expert_verifications_verifier  ON expert_verifications(verified_by) WHERE verified_by IS NOT NULL;

-- ============================================================================
-- D) Resource library within discussions
-- ============================================================================

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
COMMENT ON COLUMN discussion_resources.url           IS 'Public URL — external link or Supabase Storage download URL.';

ALTER TABLE discussion_resources ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='discussion_resources' AND policyname='discussion_resources_select_public') THEN
    EXECUTE 'CREATE POLICY "discussion_resources_select_public" ON discussion_resources FOR SELECT USING (TRUE)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='discussion_resources' AND policyname='discussion_resources_insert_own') THEN
    EXECUTE 'CREATE POLICY "discussion_resources_insert_own" ON discussion_resources FOR INSERT WITH CHECK (auth.uid() = uploaded_by)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='discussion_resources' AND policyname='discussion_resources_update_own') THEN
    EXECUTE 'CREATE POLICY "discussion_resources_update_own" ON discussion_resources FOR UPDATE USING (auth.uid() = uploaded_by)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='discussion_resources' AND policyname='discussion_resources_delete_own') THEN
    EXECUTE 'CREATE POLICY "discussion_resources_delete_own" ON discussion_resources FOR DELETE USING (auth.uid() = uploaded_by)';
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_discussion_resources_discussion ON discussion_resources(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_resources_uploader   ON discussion_resources(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_discussion_resources_type       ON discussion_resources(resource_type);
CREATE INDEX IF NOT EXISTS idx_discussion_resources_tags       ON discussion_resources USING GIN(tags);

DROP TRIGGER IF EXISTS trg_discussion_resources_updated_at ON discussion_resources;
CREATE TRIGGER trg_discussion_resources_updated_at
  BEFORE UPDATE ON discussion_resources
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- Update discussions_with_media view to expose pipeline columns
-- ============================================================================

CREATE OR REPLACE VIEW discussions_with_media AS
SELECT
  d.id,
  d.title,
  d.content,
  d.category,
  d.tags,
  d.author_id,
  d.stage,
  d.votes_count,
  d.linked_project_id,
  d.likes_count,
  d.replies_count,
  d.views_count,
  d.media_count,
  d.is_pinned,
  d.is_verified,
  d.is_archived,
  d.deleted_at,
  d.created_at,
  d.updated_at,
  p.full_name   AS author_name,
  p.avatar_url  AS author_avatar,
  COALESCE(
    JSON_AGG(
      JSON_BUILD_OBJECT(
        'id',               dm.id,
        'media_type',       dm.media_type,
        'file_url',         dm.file_url,
        'thumbnail_url',    dm.thumbnail_url,
        'file_name',        dm.file_name,
        'file_size',        dm.file_size,
        'width',            dm.width,
        'height',           dm.height,
        'duration_seconds', dm.duration_seconds,
        'display_order',    dm.display_order
      ) ORDER BY dm.display_order, dm.created_at
    ) FILTER (WHERE dm.id IS NOT NULL),
    '[]'::JSON
  ) AS media
FROM discussions d
JOIN profiles p ON d.author_id = p.id
LEFT JOIN discussion_media dm ON d.id = dm.discussion_id
WHERE d.deleted_at IS NULL
GROUP BY d.id, p.id, p.full_name, p.avatar_url;

COMMENT ON VIEW discussions_with_media IS 'Discussions with author info, Phase 1 pipeline columns (stage, votes_count, linked_project_id), and media attachments pre-aggregated as a JSON array.';

COMMIT;
