-- ============================================================================
-- Migration 007: Phase 3 — Project Foundation
-- ============================================================================
-- Adds:
--   • project_endorsements  — community backing / endorsement of projects
--   • project_discussion_links — explicit M:M links between projects and
--                                discussions (complements discussions.linked_project_id)
--
-- Also adds columns to projects:
--   • endorsements_count (cached, maintained by trigger)
--
-- Phase 3 features implemented:
--   1. Community endorsements (back / endorse a project; visible counts)
--   2. Explicit project ↔ discussion linking (bi-directional M:M)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Add endorsements_count column to projects (if not present)
-- ----------------------------------------------------------------------------
ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS endorsements_count INTEGER NOT NULL DEFAULT 0
    CHECK (endorsements_count >= 0);

COMMENT ON COLUMN projects.endorsements_count IS 'Cached count of community endorsements; maintained by trigger.';

-- ----------------------------------------------------------------------------
-- 2. project_endorsements
--    One row per (user, project) pair — unique constraint prevents duplicate
--    endorsements. Soft-deletes not needed: a deleted row = un-endorse.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS project_endorsements (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id  UUID        NOT NULL REFERENCES projects(id)  ON DELETE CASCADE,
  user_id     UUID        NOT NULL REFERENCES profiles(id)  ON DELETE CASCADE,

  -- Optional short message / reason for endorsing
  message     TEXT,

  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_endorsement UNIQUE (project_id, user_id)
);

COMMENT ON TABLE project_endorsements IS
  'One row per user-project endorsement. Deleted to un-endorse. Trigger keeps projects.endorsements_count in sync.';

-- ----------------------------------------------------------------------------
-- 3. project_discussion_links
--    Explicit M:M relationship between projects and discussions.
--    The existing discussions.linked_project_id foreign key covers the
--    "discussion spawned a project" case; this table covers any additional
--    cross-references (e.g. a project owner linking related discussions).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS project_discussion_links (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id    UUID        NOT NULL REFERENCES projects(id)    ON DELETE CASCADE,
  discussion_id UUID        NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,

  -- Who created the link and why
  linked_by     UUID        NOT NULL REFERENCES profiles(id)    ON DELETE CASCADE,
  link_type     TEXT        NOT NULL DEFAULT 'related'
    CHECK (link_type IN ('source', 'related', 'update')),

  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_project_discussion UNIQUE (project_id, discussion_id)
);

COMMENT ON TABLE project_discussion_links IS
  'Explicit links between projects and discussions. link_type: source = discussion that spawned the project; related = tangentially related discussion; update = discussion that references project progress.';

-- ----------------------------------------------------------------------------
-- 4. Indexes
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_endorsements_project  ON project_endorsements(project_id);
CREATE INDEX IF NOT EXISTS idx_endorsements_user     ON project_endorsements(user_id);
CREATE INDEX IF NOT EXISTS idx_pdlinks_project       ON project_discussion_links(project_id);
CREATE INDEX IF NOT EXISTS idx_pdlinks_discussion    ON project_discussion_links(discussion_id);

-- ----------------------------------------------------------------------------
-- 5. Trigger: keep projects.endorsements_count in sync
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sync_project_endorsements_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE projects
       SET endorsements_count = endorsements_count + 1
     WHERE id = NEW.project_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE projects
       SET endorsements_count = GREATEST(endorsements_count - 1, 0)
     WHERE id = OLD.project_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_endorsement_count ON project_endorsements;
CREATE TRIGGER trg_endorsement_count
  AFTER INSERT OR DELETE ON project_endorsements
  FOR EACH ROW EXECUTE FUNCTION sync_project_endorsements_count();

-- ----------------------------------------------------------------------------
-- 6. Row-Level Security
-- ----------------------------------------------------------------------------
ALTER TABLE project_endorsements    ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_discussion_links ENABLE ROW LEVEL SECURITY;

-- project_endorsements
CREATE POLICY "endorsements_select_public"
  ON project_endorsements FOR SELECT USING (TRUE);

CREATE POLICY "endorsements_insert_own"
  ON project_endorsements FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "endorsements_delete_own"
  ON project_endorsements FOR DELETE
  USING (auth.uid() = user_id);

-- project_discussion_links
CREATE POLICY "pdlinks_select_public"
  ON project_discussion_links FOR SELECT USING (TRUE);

CREATE POLICY "pdlinks_insert_owner"
  ON project_discussion_links FOR INSERT
  WITH CHECK (
    auth.uid() = linked_by AND (
      -- Only project owner or discussion author may create a link
      EXISTS (SELECT 1 FROM projects    p WHERE p.id = project_id    AND p.owner_id = auth.uid())
      OR
      EXISTS (SELECT 1 FROM discussions d WHERE d.id = discussion_id AND d.user_id  = auth.uid())
    )
  );

CREATE POLICY "pdlinks_delete_owner"
  ON project_discussion_links FOR DELETE
  USING (auth.uid() = linked_by);
