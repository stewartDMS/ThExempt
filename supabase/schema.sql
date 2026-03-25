-- ============================================================================
-- ThExempt Platform — Unified Production Schema
-- ============================================================================
-- Single canonical source of truth for all database tables, relationships,
-- security policies, triggers, indexes, and reference data.
--
-- Cross-referenced with README.md to cover every project module:
--   Community discussions, projects & funding, credits/investments,
--   skills marketplace, live events & chat, social graph, notifications,
--   membership tiers, and contribution tracking.
--
-- Phase 1 additions (Community Foundation):
--   §2   Discussion Tables      — now includes discussion_categories,
--                                  pipeline columns on discussions,
--                                  discussion_votes, discussion_resources
--   §3   Skills Marketplace     — now includes user_expertise,
--                                  expert_verifications
--
-- Organisation:
--   §0   Extensions & Helpers
--   §1   Core Tables            — profiles, projects, contributions
--   §2   Discussion Tables      — discussion_categories, discussions,
--                                  replies, likes, media,
--                                  discussion_votes, discussion_resources
--   §3   Skills Marketplace     — skill_categories, skills, offers, requests,
--                                  user_expertise, expert_verifications
--   §4   Project Details        — media, milestones, roles, applications, members
--   §5   Live Events & Chat     — live_events, rsvps, chat, reactions
--   §6   Social Graph           — follows, notifications
--   §7   Financial Engine       — subscriptions, credit_transactions, investments
--   §8   Content & Updates      — project_updates, comments
--   §9   Indexes
--   §10  Triggers
--   §11  Row-Level Security
--   §12  Views
--   §13  Reference Data         — skill_categories seed, discussion_categories seed
-- ============================================================================


-- ============================================================================
-- §0  Extensions & Helpers
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- trigram similarity for full-text search

-- Shared updated_at trigger function (used by every mutable table)
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


-- ============================================================================
-- §1  Core Tables
-- ============================================================================

-- ----------------------------------------------------------------------------
-- profiles
-- Public user profile extending Supabase auth.users. Central entity tied to
-- membership tiers, credits, and reputation.
-- ----------------------------------------------------------------------------
CREATE TABLE profiles (
  id                  UUID          PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username            TEXT          UNIQUE NOT NULL,
  full_name           TEXT,
  bio                 TEXT,
  avatar_url          TEXT,
  website_url         TEXT,
  location            TEXT,
  social_links        JSONB         NOT NULL DEFAULT '{}',

  -- Membership
  membership_tier     TEXT          NOT NULL DEFAULT 'free'
    CHECK (membership_tier IN ('free', 'changemaker', 'movement_builder', 'founding_partner')),
  stripe_customer_id  TEXT          UNIQUE,

  -- Reputation
  trust_score         INTEGER       NOT NULL DEFAULT 0 CHECK (trust_score BETWEEN 0 AND 100),
  expertise_areas     TEXT[]        NOT NULL DEFAULT '{}',
  primary_expertise   TEXT,
  expertise_level     TEXT          NOT NULL DEFAULT 'intermediate'
    CHECK (expertise_level IN ('beginner', 'intermediate', 'expert')),
  badges              TEXT[]        NOT NULL DEFAULT '{}',

  -- Cached stats (maintained by triggers)
  total_credits       INTEGER       NOT NULL DEFAULT 0 CHECK (total_credits >= 0),
  total_invested      INTEGER       NOT NULL DEFAULT 0 CHECK (total_invested >= 0),
  projects_backed     INTEGER       NOT NULL DEFAULT 0 CHECK (projects_backed >= 0),
  contributions_count INTEGER       NOT NULL DEFAULT 0 CHECK (contributions_count >= 0),

  -- Soft delete
  deleted_at          TIMESTAMPTZ,

  created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  profiles IS 'Public user profiles extending auth.users. Holds membership tier, credits balance, reputation, and aggregated activity stats.';
COMMENT ON COLUMN profiles.membership_tier  IS 'Subscription tier: free | changemaker | movement_builder | founding_partner';
COMMENT ON COLUMN profiles.trust_score      IS 'Reputation score 0–100, updated by platform activity and moderation.';
COMMENT ON COLUMN profiles.total_credits    IS 'Cached running credit balance (updated by credit_transactions trigger).';
COMMENT ON COLUMN profiles.deleted_at       IS 'Soft-delete timestamp. Non-null means account is deactivated.';


-- ----------------------------------------------------------------------------
-- projects
-- Fundable community-driven initiatives: the core investable unit.
-- ----------------------------------------------------------------------------
CREATE TABLE projects (
  id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id            UUID          NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Content
  title               TEXT          NOT NULL,
  tagline             TEXT,
  description         TEXT          NOT NULL,
  problem_statement   TEXT,
  solution_approach   TEXT,
  impact_metrics      JSONB         NOT NULL DEFAULT '{}',
  category            TEXT          NOT NULL,
  tags                TEXT[]        NOT NULL DEFAULT '{}',
  cover_image_url     TEXT,

  -- Funding
  funding_goal        INTEGER       NOT NULL DEFAULT 0 CHECK (funding_goal >= 0),
  funding_raised      INTEGER       NOT NULL DEFAULT 0 CHECK (funding_raised >= 0),
  funding_deadline    TIMESTAMPTZ,
  equity_offered      NUMERIC(5,2)  NOT NULL DEFAULT 0 CHECK (equity_offered BETWEEN 0 AND 100),
  min_investment      INTEGER       NOT NULL DEFAULT 10 CHECK (min_investment > 0),

  -- Team capacity
  total_roles_needed  INTEGER       NOT NULL DEFAULT 0,
  roles_filled        INTEGER       NOT NULL DEFAULT 0,

  -- Status & moderation
  status              TEXT          NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'funded', 'in_progress', 'completed', 'cancelled')),
  is_verified         BOOLEAN       NOT NULL DEFAULT FALSE,
  is_featured         BOOLEAN       NOT NULL DEFAULT FALSE,

  -- Engagement counters (maintained by triggers)
  backers_count       INTEGER       NOT NULL DEFAULT 0 CHECK (backers_count >= 0),
  views_count         INTEGER       NOT NULL DEFAULT 0 CHECK (views_count >= 0),
  likes_count         INTEGER       NOT NULL DEFAULT 0 CHECK (likes_count >= 0),

  -- Soft delete
  deleted_at          TIMESTAMPTZ,

  created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  published_at        TIMESTAMPTZ,
  funded_at           TIMESTAMPTZ,
  completed_at        TIMESTAMPTZ
);

COMMENT ON TABLE  projects IS 'Fundable community projects. Users invest credits to earn equity; contributors earn credits and equity for work.';
COMMENT ON COLUMN projects.equity_offered  IS 'Total percentage of project equity offered to all backers combined (0–100).';
COMMENT ON COLUMN projects.impact_metrics  IS 'Free-form JSONB for tracking social/environmental impact metrics.';
COMMENT ON COLUMN projects.deleted_at      IS 'Soft-delete timestamp.';


-- ----------------------------------------------------------------------------
-- contributions
-- Work logged against projects; reviewed for credit/equity rewards.
-- ----------------------------------------------------------------------------
CREATE TABLE contributions (
  id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  contributor_id    UUID          NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id        UUID          NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

  -- Work logged
  title             TEXT          NOT NULL,
  description       TEXT          NOT NULL,
  hours_worked      NUMERIC(6,1),
  contribution_type TEXT          NOT NULL DEFAULT 'general'
    CHECK (contribution_type IN ('code', 'design', 'research', 'writing', 'community', 'general')),

  -- Rewards
  credits_earned    INTEGER       NOT NULL DEFAULT 0 CHECK (credits_earned >= 0),
  equity_earned     NUMERIC(5,2)  NOT NULL DEFAULT 0 CHECK (equity_earned >= 0),

  -- Review workflow
  status            TEXT          NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by       UUID          REFERENCES profiles(id),
  reviewed_at       TIMESTAMPTZ,
  review_notes      TEXT,

  created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE contributions IS 'Work contributions to projects. Approved contributions trigger credit/equity rewards to the contributor.';


-- ============================================================================
-- §2  Discussion Tables
-- ============================================================================

-- ----------------------------------------------------------------------------
-- discussion_categories  (Phase 1 — Community Foundation)
-- Canonical taxonomy of discussion categories.
-- Drives UI routing, API filters, and the Problem → Solution → Project pipeline.
-- ----------------------------------------------------------------------------
CREATE TABLE discussion_categories (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  slug          TEXT    UNIQUE NOT NULL,
  label         TEXT    NOT NULL,
  description   TEXT    NOT NULL DEFAULT '',
  emoji         TEXT    NOT NULL DEFAULT '',
  color_hex     TEXT    NOT NULL DEFAULT '#666666',

  -- is_systemic = TRUE for high-priority categories (climate, inequality, etc.)
  is_systemic   BOOLEAN NOT NULL DEFAULT FALSE,

  display_order INTEGER NOT NULL DEFAULT 0,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,

  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  discussion_categories IS 'Canonical taxonomy of discussion categories. Slugs are used in discussions.category for validation and filtering.';
COMMENT ON COLUMN discussion_categories.slug        IS 'Machine-readable key used in discussions.category and API filters (e.g. climate_crisis).';
COMMENT ON COLUMN discussion_categories.is_systemic IS 'TRUE for high-priority systemic issue categories (climate_crisis, economic_inequality, etc.).';

-- ----------------------------------------------------------------------------
-- discussions
-- Community discussion threads (problems, ideas, events, networking, etc.).
-- Central to the Problem → Solution → Project pipeline.
-- ----------------------------------------------------------------------------
CREATE TABLE discussions (
  id            UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID      NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Content
  category      TEXT      NOT NULL
    CHECK (category IN (
      -- Original categories
      'world_problems', 'ideas', 'learning', 'live_events', 'networking', 'feedback', 'general',
      -- Phase 1 systemic categories
      'climate_crisis', 'economic_inequality', 'healthcare_access', 'education_reform',
      'housing_justice', 'criminal_justice', 'immigration_justice', 'mental_health_crisis'
    )),
  title         TEXT      NOT NULL,
  content       TEXT      NOT NULL,
  tags          TEXT[]    NOT NULL DEFAULT '{}',

  -- Problem → Solution → Project pipeline  (Phase 1 — Community Foundation)
  stage             TEXT        NOT NULL DEFAULT 'problem'
    CHECK (stage IN ('problem', 'solution', 'project_proposal', 'project_linked')),
  votes_count       INTEGER     NOT NULL DEFAULT 0 CHECK (votes_count >= 0),
  linked_project_id UUID        REFERENCES projects(id) ON DELETE SET NULL,

  -- Moderation
  is_pinned     BOOLEAN   NOT NULL DEFAULT FALSE,
  is_verified   BOOLEAN   NOT NULL DEFAULT FALSE,
  is_archived   BOOLEAN   NOT NULL DEFAULT FALSE,

  -- Engagement counters (maintained by triggers)
  likes_count   INTEGER   NOT NULL DEFAULT 0 CHECK (likes_count >= 0),
  replies_count INTEGER   NOT NULL DEFAULT 0 CHECK (replies_count >= 0),
  views_count   INTEGER   NOT NULL DEFAULT 0 CHECK (views_count >= 0),
  media_count   INTEGER   NOT NULL DEFAULT 0 CHECK (media_count >= 0),

  -- Soft delete
  deleted_at    TIMESTAMPTZ,

  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  discussions IS 'Community discussion threads. Categories drive the Problem→Solution→Project pipeline.';
COMMENT ON COLUMN discussions.category          IS 'Thread category — original: world_problems | ideas | learning | live_events | networking | feedback | general; Phase 1 systemic: climate_crisis | economic_inequality | healthcare_access | education_reform | housing_justice | criminal_justice | immigration_justice | mental_health_crisis';
COMMENT ON COLUMN discussions.stage             IS 'Pipeline stage: problem → solution → project_proposal → project_linked';
COMMENT ON COLUMN discussions.votes_count       IS 'Cached net vote tally (upvotes − downvotes); maintained by sync_discussion_votes_count trigger.';
COMMENT ON COLUMN discussions.linked_project_id IS 'Set when stage = project_linked; points to the project that emerged from this discussion.';


-- ----------------------------------------------------------------------------
-- discussion_replies
-- Threaded replies to discussions; supports nested (parent) replies.
-- ----------------------------------------------------------------------------
CREATE TABLE discussion_replies (
  id              UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id   UUID      NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
  user_id       UUID      NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  parent_reply_id UUID      REFERENCES discussion_replies(id) ON DELETE CASCADE,

  -- Content
  content         TEXT      NOT NULL,

  -- Engagement
  likes_count     INTEGER   NOT NULL DEFAULT 0 CHECK (likes_count >= 0),

  -- Moderation
  is_solution     BOOLEAN   NOT NULL DEFAULT FALSE,
  is_verified     BOOLEAN   NOT NULL DEFAULT FALSE,

  -- Soft delete
  deleted_at      TIMESTAMPTZ,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE discussion_replies IS 'Threaded replies to discussions. Nested replies supported via parent_reply_id.';


-- ----------------------------------------------------------------------------
-- discussion_likes
-- Likes for discussions OR individual replies (mutually exclusive target).
-- ----------------------------------------------------------------------------
CREATE TABLE discussion_likes (
  id            UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID  NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  discussion_id UUID  REFERENCES discussions(id) ON DELETE CASCADE,
  reply_id      UUID  REFERENCES discussion_replies(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Exactly one target per like
  CONSTRAINT discussion_likes_single_target CHECK (
    (discussion_id IS NOT NULL AND reply_id IS NULL) OR
    (discussion_id IS NULL     AND reply_id IS NOT NULL)
  ),

  -- One like per user per item
  UNIQUE NULLS NOT DISTINCT (user_id, discussion_id, reply_id)
);

COMMENT ON TABLE discussion_likes IS 'User likes on discussions or replies. Mutual exclusivity enforced by CHECK; duplicate prevention by UNIQUE.';


-- ----------------------------------------------------------------------------
-- discussion_media
-- Images and videos attached to discussions (stored in Supabase Storage).
-- Max 5 files per discussion: images ≤ 10 MB, videos ≤ 100 MB.
-- ----------------------------------------------------------------------------
CREATE TABLE discussion_media (
  id               UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id    UUID    NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
  uploaded_by      UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  media_type       TEXT    NOT NULL CHECK (media_type IN ('image', 'video')),
  file_url         TEXT    NOT NULL,
  thumbnail_url    TEXT,
  file_name        TEXT    NOT NULL,
  file_size        BIGINT  NOT NULL CHECK (file_size > 0),
  mime_type        TEXT,
  width            INTEGER,
  height           INTEGER,
  duration_seconds INTEGER,
  display_order    INTEGER NOT NULL DEFAULT 0,

  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  discussion_media IS 'Media attachments (images/videos) for discussions. Stored in Supabase Storage under discussion-media/{user_id}/.';
COMMENT ON COLUMN discussion_media.uploaded_by IS 'Owner of the file; used for storage RLS ownership checks.';


-- ----------------------------------------------------------------------------
-- discussion_votes  (Phase 1 — Problem → Solution → Project pipeline)
-- Upvotes / downvotes on discussion threads. One vote per user per discussion.
-- The sync_discussion_votes_count trigger keeps discussions.votes_count current.
-- ----------------------------------------------------------------------------
CREATE TABLE discussion_votes (
  id            UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id UUID     NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
  user_id       UUID     NOT NULL REFERENCES profiles(id)   ON DELETE CASCADE,

  -- 1 = upvote, -1 = downvote
  value         SMALLINT NOT NULL DEFAULT 1 CHECK (value IN (1, -1)),

  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (discussion_id, user_id)
);

COMMENT ON TABLE  discussion_votes IS 'Upvotes/downvotes on pipeline discussions. One vote per user per discussion; value IN (1, -1).';
COMMENT ON COLUMN discussion_votes.value IS '1 = upvote, -1 = downvote';


-- ----------------------------------------------------------------------------
-- discussion_resources  (Phase 1 — Resource Library)
-- Links, documents, videos, and datasets attached to a discussion thread.
-- Files are stored in Supabase Storage bucket: discussion-resources/{user_id}/
-- ----------------------------------------------------------------------------
CREATE TABLE discussion_resources (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id   UUID    NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
  uploaded_by     UUID    NOT NULL REFERENCES profiles(id)   ON DELETE CASCADE,

  -- Type of resource
  resource_type   TEXT    NOT NULL DEFAULT 'link'
    CHECK (resource_type IN ('link', 'document', 'video', 'image', 'dataset')),

  -- Content
  title           TEXT    NOT NULL,
  description     TEXT,
  url             TEXT,          -- external link OR Supabase Storage public URL
  file_name       TEXT,
  file_size       BIGINT  CHECK (file_size IS NULL OR file_size > 0),
  mime_type       TEXT,

  -- Discovery
  tags            TEXT[]  NOT NULL DEFAULT '{}',
  is_featured     BOOLEAN NOT NULL DEFAULT FALSE,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  discussion_resources IS 'Resources (links, docs, videos, datasets) attached to a discussion thread. Files stored in Supabase Storage under discussion-resources/{user_id}/.';
COMMENT ON COLUMN discussion_resources.resource_type IS 'link | document | video | image | dataset';
COMMENT ON COLUMN discussion_resources.url           IS 'Public URL — either an external link or a Supabase Storage download URL.';


-- ============================================================================
-- §3  Skills Marketplace
-- ============================================================================

-- ----------------------------------------------------------------------------
-- skill_categories
-- Canonical taxonomy of skills on the platform. Seeded in §13.
-- ----------------------------------------------------------------------------
CREATE TABLE skill_categories (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT    UNIQUE NOT NULL,
  parent_category TEXT    NOT NULL,
  description     TEXT,
  icon            TEXT,
  color           TEXT,
  display_order   INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE skill_categories IS 'Reference taxonomy of skills used across user profiles, skill_offers, and skill_requests. Seeded with 80+ categories.';


-- ----------------------------------------------------------------------------
-- skills
-- Skills declared by individual users; linked to skill_categories.
-- ----------------------------------------------------------------------------
CREATE TABLE skills (
  id                UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  skill_category_id UUID    REFERENCES skill_categories(id) ON DELETE SET NULL,

  skill_name        TEXT    NOT NULL,
  proficiency       TEXT    NOT NULL DEFAULT 'intermediate'
    CHECK (proficiency IN ('beginner', 'intermediate', 'expert')),
  years_experience  INTEGER CHECK (years_experience >= 0),
  is_verified       BOOLEAN NOT NULL DEFAULT FALSE,

  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, skill_name)
);

COMMENT ON TABLE skills IS 'User-declared skills with optional link to the canonical skill_categories taxonomy.';


-- ----------------------------------------------------------------------------
-- skill_offers
-- Users advertising their availability to contribute skills to projects.
-- ----------------------------------------------------------------------------
CREATE TABLE skill_offers (
  id                       UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                  UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  title                    TEXT    NOT NULL,
  description              TEXT    NOT NULL,
  skill_categories         TEXT[]  NOT NULL DEFAULT '{}',

  -- Compensation preferences
  rate_credits_per_hour    INTEGER CHECK (rate_credits_per_hour >= 0),
  equity_preferred         BOOLEAN NOT NULL DEFAULT FALSE,

  -- Availability
  available_hours_per_week INTEGER CHECK (available_hours_per_week >= 0),
  is_active                BOOLEAN NOT NULL DEFAULT TRUE,

  -- Soft delete
  deleted_at               TIMESTAMPTZ,

  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE skill_offers IS 'Skill availability listings posted by users, enabling the skills marketplace/directory.';


-- ----------------------------------------------------------------------------
-- skill_requests
-- Projects advertising skill gaps they need filled.
-- ----------------------------------------------------------------------------
CREATE TABLE skill_requests (
  id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id     UUID         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id       UUID         REFERENCES projects(id) ON DELETE CASCADE,

  title            TEXT         NOT NULL,
  description      TEXT         NOT NULL,
  skill_categories TEXT[]       NOT NULL DEFAULT '{}',

  -- Compensation offered
  budget_credits   INTEGER      CHECK (budget_credits >= 0),
  equity_offered   NUMERIC(5,2) CHECK (equity_offered >= 0),

  -- Status
  status           TEXT         NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'in_progress', 'completed', 'cancelled')),

  -- Soft delete
  deleted_at       TIMESTAMPTZ,

  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE skill_requests IS 'Skill gap requests posted by project owners. Matched against skill_offers to connect teams.';


-- ----------------------------------------------------------------------------
-- user_expertise  (Phase 1 — Expert Badges & Trust System)
-- Expertise areas claimed or verified for each user.
-- Feeds the trust_score calculation and badge award logic on profiles.
-- ----------------------------------------------------------------------------
CREATE TABLE user_expertise (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- The expertise domain (e.g. 'climate_policy', 'public_health', 'fintech')
  area          TEXT    NOT NULL,

  -- Verification level: escalates as endorsements are received
  level         TEXT    NOT NULL DEFAULT 'self_declared'
    CHECK (level IN ('self_declared', 'community_verified', 'expert_verified', 'platform_verified')),

  evidence_url  TEXT,    -- link to credential, publication, portfolio, etc.
  is_primary    BOOLEAN NOT NULL DEFAULT FALSE,

  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, area)
);

COMMENT ON TABLE  user_expertise IS 'Expertise areas claimed or verified per user. Level escalates as endorsements accumulate.';
COMMENT ON COLUMN user_expertise.level        IS 'self_declared → community_verified → expert_verified → platform_verified';
COMMENT ON COLUMN user_expertise.is_primary   IS 'TRUE for the user''s main expertise area (only one should be TRUE per user).';
COMMENT ON COLUMN user_expertise.evidence_url IS 'Optional link to credential, publication, or other proof.';


-- ----------------------------------------------------------------------------
-- expert_verifications  (Phase 1 — Expert Badges & Trust System)
-- Endorsement / verification events for a user_expertise entry.
-- Multiple verifications raise the target user''s trust_score via trigger.
-- ----------------------------------------------------------------------------
CREATE TABLE expert_verifications (
  id                  UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_expertise_id   UUID    NOT NULL REFERENCES user_expertise(id) ON DELETE CASCADE,

  -- NULL verified_by = platform/admin action
  verified_by         UUID    REFERENCES profiles(id) ON DELETE SET NULL,

  verification_type   TEXT    NOT NULL DEFAULT 'community'
    CHECK (verification_type IN ('community', 'admin', 'credential')),

  notes               TEXT,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  expert_verifications IS 'Verification events for user expertise entries. Each row raises the target user''s trust_score.';
COMMENT ON COLUMN expert_verifications.verified_by       IS 'NULL = platform/admin verification; otherwise the endorsing user.';
COMMENT ON COLUMN expert_verifications.verification_type IS 'community = peer endorsement; admin = staff approval; credential = verified credential.';


-- ============================================================================
-- §4  Project Details
-- ============================================================================

-- ----------------------------------------------------------------------------
-- project_media
-- Images and videos attached to a project page.
-- ----------------------------------------------------------------------------
CREATE TABLE project_media (
  id               UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id       UUID    NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  uploaded_by      UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  media_type       TEXT    NOT NULL CHECK (media_type IN ('image', 'video')),
  file_url         TEXT    NOT NULL,
  thumbnail_url    TEXT,
  file_name        TEXT    NOT NULL,
  file_size        BIGINT  NOT NULL CHECK (file_size > 0),
  mime_type        TEXT,
  width            INTEGER,
  height           INTEGER,
  duration_seconds INTEGER,
  display_order    INTEGER NOT NULL DEFAULT 0,

  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE project_media IS 'Media attachments (images/videos) for project pages, uploaded by the project owner or team members.';


-- ----------------------------------------------------------------------------
-- project_milestones
-- Ordered milestone phases for a project roadmap.
-- ----------------------------------------------------------------------------
CREATE TABLE project_milestones (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id    UUID    NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

  title         TEXT    NOT NULL,
  description   TEXT,
  due_date      TIMESTAMPTZ,
  completed_at  TIMESTAMPTZ,
  display_order INTEGER NOT NULL DEFAULT 0,

  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE project_milestones IS 'Milestone phases for project roadmaps. Backers can track progress against committed milestones.';


-- ----------------------------------------------------------------------------
-- project_roles
-- Roles/positions available on a project for contributors to apply for.
-- ----------------------------------------------------------------------------
CREATE TABLE project_roles (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id      UUID    NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

  role_category   TEXT    NOT NULL,
  role_title      TEXT    NOT NULL,
  description     TEXT,
  skills_required TEXT[]  NOT NULL DEFAULT '{}',
  compensation    JSONB   NOT NULL DEFAULT '{}',  -- {credits_per_hour, equity_percentage}

  is_filled       BOOLEAN NOT NULL DEFAULT FALSE,
  filled_by       UUID    REFERENCES profiles(id) ON DELETE SET NULL,
  display_order   INTEGER NOT NULL DEFAULT 0,

  -- Soft delete
  deleted_at      TIMESTAMPTZ,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE project_roles IS 'Available roles on a project. Filling a role creates a project_members entry.';


-- ----------------------------------------------------------------------------
-- role_applications
-- Applications from users to fill project roles.
-- ----------------------------------------------------------------------------
CREATE TABLE role_applications (
  id           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id   UUID    NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  role_id      UUID    NOT NULL REFERENCES project_roles(id) ON DELETE CASCADE,
  user_id      UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  message      TEXT    NOT NULL,
  match_score  INTEGER NOT NULL DEFAULT 0 CHECK (match_score BETWEEN 0 AND 100),
  status       TEXT    NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'rejected', 'withdrawn')),

  reviewed_at  TIMESTAMPTZ,
  reviewer_id  UUID    REFERENCES profiles(id),

  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (role_id, user_id)
);

COMMENT ON TABLE role_applications IS 'User applications for project roles. Accepted applications create project_members entries.';


-- ----------------------------------------------------------------------------
-- project_members
-- Confirmed team members of a project.
-- ----------------------------------------------------------------------------
CREATE TABLE project_members (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id  UUID    NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id     UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role_id     UUID    REFERENCES project_roles(id) ON DELETE SET NULL,
  role_title  TEXT    NOT NULL,

  joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  left_at     TIMESTAMPTZ,

  UNIQUE (project_id, user_id)
);

COMMENT ON TABLE project_members IS 'Active and past project team members. Created when a role_application is accepted or directly by the project owner.';


-- ============================================================================
-- §5  Live Events & Chat
-- ============================================================================

-- ----------------------------------------------------------------------------
-- live_events
-- Scheduled or live community events (panels, workshops, Q&As, etc.).
-- ----------------------------------------------------------------------------
CREATE TABLE live_events (
  id                UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id           UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id        UUID    REFERENCES projects(id) ON DELETE SET NULL,

  title             TEXT    NOT NULL,
  description       TEXT,
  category          TEXT    NOT NULL,
  event_type        TEXT    NOT NULL
    CHECK (event_type IN ('panel', 'workshop', 'ama', 'townhall', 'demo', 'social', 'other')),

  -- Scheduling
  scheduled_start   TIMESTAMPTZ,
  scheduled_end     TIMESTAMPTZ,
  timezone          TEXT    NOT NULL DEFAULT 'UTC',

  -- Live state
  is_live           BOOLEAN NOT NULL DEFAULT FALSE,
  started_at        TIMESTAMPTZ,
  ended_at          TIMESTAMPTZ,

  -- Stream/meeting links
  stream_url        TEXT,
  recording_url     TEXT,
  meeting_link      TEXT,

  -- Settings
  max_attendees     INTEGER NOT NULL DEFAULT 100 CHECK (max_attendees > 0),
  allow_chat        BOOLEAN NOT NULL DEFAULT TRUE,
  allow_reactions   BOOLEAN NOT NULL DEFAULT TRUE,
  require_approval  BOOLEAN NOT NULL DEFAULT FALSE,

  -- Engagement counters
  viewers_count     INTEGER NOT NULL DEFAULT 0 CHECK (viewers_count >= 0),
  peak_viewers      INTEGER NOT NULL DEFAULT 0 CHECK (peak_viewers >= 0),
  total_views       INTEGER NOT NULL DEFAULT 0 CHECK (total_views >= 0),
  rsvp_count        INTEGER NOT NULL DEFAULT 0 CHECK (rsvp_count >= 0),

  -- Soft delete
  deleted_at        TIMESTAMPTZ,

  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE live_events IS 'Community events (live or scheduled). Supports real-time chat and emoji reactions during sessions.';


-- ----------------------------------------------------------------------------
-- event_rsvps
-- User RSVPs for live events; used for attendance tracking and approval gating.
-- ----------------------------------------------------------------------------
CREATE TABLE event_rsvps (
  id         UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id   UUID  NOT NULL REFERENCES live_events(id) ON DELETE CASCADE,
  user_id    UUID  NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  status     TEXT  NOT NULL DEFAULT 'attending'
    CHECK (status IN ('attending', 'maybe', 'declined')),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (event_id, user_id)
);

COMMENT ON TABLE event_rsvps IS 'User RSVPs for live events. Status tracks attending/maybe/declined.';


-- ----------------------------------------------------------------------------
-- live_chat_messages
-- Real-time chat messages sent during a live event session.
-- ----------------------------------------------------------------------------
CREATE TABLE live_chat_messages (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id    UUID    NOT NULL REFERENCES live_events(id) ON DELETE CASCADE,
  user_id     UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  message     TEXT    NOT NULL,
  is_pinned   BOOLEAN NOT NULL DEFAULT FALSE,

  -- Soft delete (moderation)
  deleted_at  TIMESTAMPTZ,

  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE live_chat_messages IS 'Real-time chat for live events. Soft-deleted for moderation; supports message pinning.';


-- ----------------------------------------------------------------------------
-- live_reactions
-- Emoji/reaction bursts sent during live events.
-- ----------------------------------------------------------------------------
CREATE TABLE live_reactions (
  id            UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id      UUID  NOT NULL REFERENCES live_events(id) ON DELETE CASCADE,
  user_id       UUID  NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  reaction_type TEXT  NOT NULL,  -- e.g. '👏', '🔥', '❤️'

  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE live_reactions IS 'Emoji reactions during live events. High-frequency; consider partitioning by event_id if volume grows.';


-- ============================================================================
-- §6  Social Graph
-- ============================================================================

-- ----------------------------------------------------------------------------
-- follows
-- Directed follow relationship between users.
-- ----------------------------------------------------------------------------
CREATE TABLE follows (
  id           UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id  UUID  NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID  NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (follower_id, following_id),
  CONSTRAINT follows_no_self_follow CHECK (follower_id <> following_id)
);

COMMENT ON TABLE follows IS 'Directed user follow graph. follower_id follows following_id.';


-- ----------------------------------------------------------------------------
-- notifications
-- In-app notification feed for user actions.
-- ----------------------------------------------------------------------------
CREATE TABLE notifications (
  id                UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  actor_id          UUID    REFERENCES profiles(id) ON DELETE SET NULL,

  notification_type TEXT    NOT NULL
    CHECK (notification_type IN (
      'like', 'reply', 'follow', 'investment', 'contribution_approved',
      'role_application', 'role_accepted', 'project_update', 'system'
    )),

  -- Polymorphic target
  target_type       TEXT,   -- 'discussion' | 'project' | 'contribution' | 'live_event' | …
  target_id         UUID,

  title             TEXT    NOT NULL,
  body              TEXT,
  is_read           BOOLEAN NOT NULL DEFAULT FALSE,
  metadata          JSONB   NOT NULL DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  notifications IS 'In-app notification feed. actor_id performed an action that user_id cares about.';
COMMENT ON COLUMN notifications.target_type IS 'Polymorphic table name the target_id refers to.';


-- ============================================================================
-- §7  Financial Engine
-- ============================================================================

-- ----------------------------------------------------------------------------
-- subscriptions
-- Stripe subscription records for paid membership tiers.
-- Kept in sync via Stripe webhook edge function.
-- ----------------------------------------------------------------------------
CREATE TABLE subscriptions (
  id                     UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                UUID  NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  stripe_subscription_id TEXT  UNIQUE NOT NULL,
  stripe_price_id        TEXT  NOT NULL,
  stripe_product_id      TEXT,

  tier                   TEXT  NOT NULL
    CHECK (tier IN ('changemaker', 'movement_builder', 'founding_partner')),
  status                 TEXT  NOT NULL
    CHECK (status IN ('active', 'canceled', 'past_due', 'trialing', 'incomplete')),

  current_period_start   TIMESTAMPTZ NOT NULL,
  current_period_end     TIMESTAMPTZ NOT NULL,
  cancel_at              TIMESTAMPTZ,
  canceled_at            TIMESTAMPTZ,
  trial_start            TIMESTAMPTZ,
  trial_end              TIMESTAMPTZ,
  metadata               JSONB NOT NULL DEFAULT '{}',

  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE subscriptions IS 'Stripe subscription records. Status is kept in sync by the Stripe webhook edge function.';


-- ----------------------------------------------------------------------------
-- credit_transactions
-- Immutable ledger of every credit movement (double-entry: balance_after tracks
-- the running total per user).
-- ----------------------------------------------------------------------------
CREATE TABLE credit_transactions (
  id               UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  amount           INTEGER NOT NULL,         -- positive = earned/added; negative = spent
  balance_after    INTEGER NOT NULL,         -- running balance snapshot after this transaction

  transaction_type TEXT    NOT NULL
    CHECK (transaction_type IN (
      'subscription_credit',
      'investment_debit',
      'contribution_reward',
      'equity_sale',
      'refund',
      'admin_adjustment'
    )),

  source_id        UUID,                     -- FK to originating record (investments.id, etc.)
  source_type      TEXT,                     -- 'investment' | 'contribution' | 'subscription' | …
  description      TEXT    NOT NULL,
  metadata         JSONB   NOT NULL DEFAULT '{}',

  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  credit_transactions IS 'Immutable credit ledger. Every debit/credit is a row; balance_after snapshots the running total.';
COMMENT ON COLUMN credit_transactions.amount IS 'Positive = earned/added; negative = spent/debited.';


-- ----------------------------------------------------------------------------
-- investments
-- Credits invested in a project, converting to an equity stake.
-- ----------------------------------------------------------------------------
CREATE TABLE investments (
  id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  investor_id         UUID         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id          UUID         NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

  credits_invested    INTEGER      NOT NULL CHECK (credits_invested > 0),
  equity_percentage   NUMERIC(5,2) NOT NULL CHECK (equity_percentage > 0),

  status              TEXT         NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'exited', 'cancelled')),

  -- Valuation tracking (updated by equity platform integration)
  equity_value_usd    NUMERIC(12,2) NOT NULL DEFAULT 0,
  last_valuation_date TIMESTAMPTZ,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE investments IS 'Credit investments in projects. equity_percentage records the investor''s ownership share.';


-- ============================================================================
-- §8  Content & Updates
-- ============================================================================

-- ----------------------------------------------------------------------------
-- project_updates
-- Announcements and progress updates posted by project owners.
-- ----------------------------------------------------------------------------
CREATE TABLE project_updates (
  id           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id   UUID    NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id    UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  title        TEXT    NOT NULL,
  content      TEXT    NOT NULL,
  update_type  TEXT    NOT NULL DEFAULT 'general'
    CHECK (update_type IN ('milestone', 'funding', 'team', 'media', 'general')),

  is_pinned    BOOLEAN NOT NULL DEFAULT FALSE,
  likes_count  INTEGER NOT NULL DEFAULT 0 CHECK (likes_count >= 0),

  -- Soft delete
  deleted_at   TIMESTAMPTZ,

  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE project_updates IS 'Project owner announcements visible to backers and the public. Types: milestone, funding, team, media, general.';


-- ----------------------------------------------------------------------------
-- comments
-- Threaded comments on project_updates.
-- ----------------------------------------------------------------------------
CREATE TABLE comments (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  update_id   UUID    NOT NULL REFERENCES project_updates(id) ON DELETE CASCADE,
  user_id   UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  parent_id   UUID    REFERENCES comments(id) ON DELETE CASCADE,

  content     TEXT    NOT NULL,
  likes_count INTEGER NOT NULL DEFAULT 0 CHECK (likes_count >= 0),

  -- Soft delete
  deleted_at  TIMESTAMPTZ,

  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE comments IS 'Threaded comments on project updates.';


-- ============================================================================
-- §9  Indexes
-- ============================================================================

-- profiles
CREATE INDEX idx_profiles_username          ON profiles(username);
CREATE INDEX idx_profiles_membership_tier   ON profiles(membership_tier);
CREATE INDEX idx_profiles_primary_expertise ON profiles(primary_expertise) WHERE primary_expertise IS NOT NULL;
CREATE INDEX idx_profiles_deleted           ON profiles(deleted_at) WHERE deleted_at IS NOT NULL;

-- projects
CREATE INDEX idx_projects_owner    ON projects(owner_id);
CREATE INDEX idx_projects_status   ON projects(status);
CREATE INDEX idx_projects_category ON projects(category);
CREATE INDEX idx_projects_funding  ON projects(funding_raised DESC);
CREATE INDEX idx_projects_created  ON projects(created_at DESC);
CREATE INDEX idx_projects_deleted  ON projects(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX idx_projects_tags     ON projects USING GIN(tags);

-- contributions
CREATE INDEX idx_contributions_contributor ON contributions(contributor_id);
CREATE INDEX idx_contributions_project     ON contributions(project_id);
CREATE INDEX idx_contributions_status      ON contributions(status);

-- discussions
CREATE INDEX idx_discussions_user     ON discussions(user_id);
CREATE INDEX idx_discussions_category ON discussions(category);
CREATE INDEX idx_discussions_created  ON discussions(created_at DESC);
CREATE INDEX idx_discussions_trending ON discussions(likes_count DESC, replies_count DESC);
CREATE INDEX idx_discussions_deleted  ON discussions(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX idx_discussions_tags     ON discussions USING GIN(tags);

-- discussion_replies
CREATE INDEX idx_replies_discussion ON discussion_replies(discussion_id);
CREATE INDEX idx_replies_parent     ON discussion_replies(parent_reply_id) WHERE parent_reply_id IS NOT NULL;
CREATE INDEX idx_replies_user        ON discussion_replies(user_id);

-- discussion_likes
CREATE INDEX idx_discussion_likes_user       ON discussion_likes(user_id);
CREATE INDEX idx_discussion_likes_discussion ON discussion_likes(discussion_id) WHERE discussion_id IS NOT NULL;
CREATE INDEX idx_discussion_likes_reply      ON discussion_likes(reply_id)      WHERE reply_id      IS NOT NULL;

-- discussion_media
CREATE INDEX idx_discussion_media_discussion ON discussion_media(discussion_id);
CREATE INDEX idx_discussion_media_uploader   ON discussion_media(uploaded_by);

-- discussion_votes  (Phase 1)
CREATE INDEX idx_discussion_votes_discussion ON discussion_votes(discussion_id);
CREATE INDEX idx_discussion_votes_user       ON discussion_votes(user_id);

-- discussion_resources  (Phase 1)
CREATE INDEX idx_discussion_resources_discussion ON discussion_resources(discussion_id);
CREATE INDEX idx_discussion_resources_uploader   ON discussion_resources(uploaded_by);
CREATE INDEX idx_discussion_resources_type       ON discussion_resources(resource_type);
CREATE INDEX idx_discussion_resources_tags       ON discussion_resources USING GIN(tags);

-- discussion_categories  (Phase 1)
CREATE INDEX idx_discussion_categories_slug     ON discussion_categories(slug);
CREATE INDEX idx_discussion_categories_systemic ON discussion_categories(is_systemic) WHERE is_systemic = TRUE;

-- discussions  pipeline columns  (Phase 1)
CREATE INDEX idx_discussions_stage          ON discussions(stage);
CREATE INDEX idx_discussions_linked_project ON discussions(linked_project_id) WHERE linked_project_id IS NOT NULL;

-- skill_categories
CREATE INDEX idx_skill_categories_parent ON skill_categories(parent_category);

-- skills
CREATE INDEX idx_skills_user     ON skills(user_id);
CREATE INDEX idx_skills_category ON skills(skill_category_id) WHERE skill_category_id IS NOT NULL;

-- skill_offers
CREATE INDEX idx_skill_offers_user   ON skill_offers(user_id);
CREATE INDEX idx_skill_offers_active ON skill_offers(is_active) WHERE is_active = TRUE;

-- skill_requests
CREATE INDEX idx_skill_requests_requester ON skill_requests(requester_id);
CREATE INDEX idx_skill_requests_project   ON skill_requests(project_id) WHERE project_id IS NOT NULL;
CREATE INDEX idx_skill_requests_status    ON skill_requests(status);

-- user_expertise  (Phase 1)
CREATE INDEX idx_user_expertise_user ON user_expertise(user_id);
CREATE INDEX idx_user_expertise_area ON user_expertise(area);

-- expert_verifications  (Phase 1)
CREATE INDEX idx_expert_verifications_expertise ON expert_verifications(user_expertise_id);
CREATE INDEX idx_expert_verifications_verifier  ON expert_verifications(verified_by) WHERE verified_by IS NOT NULL;

-- project_media
CREATE INDEX idx_project_media_project  ON project_media(project_id);
CREATE INDEX idx_project_media_uploader ON project_media(uploaded_by);

-- project_milestones
CREATE INDEX idx_milestones_project ON project_milestones(project_id);

-- project_roles
CREATE INDEX idx_project_roles_project ON project_roles(project_id);
CREATE INDEX idx_project_roles_filled  ON project_roles(is_filled);

-- role_applications
CREATE INDEX idx_role_applications_project ON role_applications(project_id);
CREATE INDEX idx_role_applications_user    ON role_applications(user_id);
CREATE INDEX idx_role_applications_status  ON role_applications(status);

-- project_members
CREATE INDEX idx_project_members_project ON project_members(project_id);
CREATE INDEX idx_project_members_user    ON project_members(user_id);

-- live_events
CREATE INDEX idx_live_events_host      ON live_events(host_id);
CREATE INDEX idx_live_events_is_live   ON live_events(is_live) WHERE is_live = TRUE;
CREATE INDEX idx_live_events_scheduled ON live_events(scheduled_start);
CREATE INDEX idx_live_events_category  ON live_events(category);

-- event_rsvps
CREATE INDEX idx_event_rsvps_event ON event_rsvps(event_id);
CREATE INDEX idx_event_rsvps_user  ON event_rsvps(user_id);

-- live_chat_messages
CREATE INDEX idx_live_chat_event   ON live_chat_messages(event_id);
CREATE INDEX idx_live_chat_created ON live_chat_messages(created_at DESC);

-- live_reactions
CREATE INDEX idx_live_reactions_event ON live_reactions(event_id);

-- follows
CREATE INDEX idx_follows_follower  ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);

-- notifications
CREATE INDEX idx_notifications_user    ON notifications(user_id);
CREATE INDEX idx_notifications_unread  ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- subscriptions
CREATE INDEX idx_subscriptions_user   ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);

-- credit_transactions
CREATE INDEX idx_credits_user    ON credit_transactions(user_id);
CREATE INDEX idx_credits_created ON credit_transactions(created_at DESC);
CREATE INDEX idx_credits_type    ON credit_transactions(transaction_type);

-- investments
CREATE INDEX idx_investments_investor ON investments(investor_id);
CREATE INDEX idx_investments_project  ON investments(project_id);
CREATE INDEX idx_investments_status   ON investments(status);

-- project_updates
CREATE INDEX idx_project_updates_project ON project_updates(project_id);
CREATE INDEX idx_project_updates_user  ON project_updates(user_id);

-- comments
CREATE INDEX idx_comments_update ON comments(update_id);
CREATE INDEX idx_comments_user ON comments(user_id);
CREATE INDEX idx_comments_parent ON comments(parent_id) WHERE parent_id IS NOT NULL;


-- ============================================================================
-- §10  Triggers
-- ============================================================================

-- updated_at triggers for every mutable table
CREATE TRIGGER trg_profiles_updated_at          BEFORE UPDATE ON profiles           FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_projects_updated_at          BEFORE UPDATE ON projects           FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_contributions_updated_at     BEFORE UPDATE ON contributions      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_discussions_updated_at       BEFORE UPDATE ON discussions        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_discussion_replies_updated   BEFORE UPDATE ON discussion_replies FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_discussion_media_updated     BEFORE UPDATE ON discussion_media   FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_skills_updated_at            BEFORE UPDATE ON skills             FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_skill_offers_updated_at      BEFORE UPDATE ON skill_offers       FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_skill_requests_updated_at    BEFORE UPDATE ON skill_requests     FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_project_media_updated        BEFORE UPDATE ON project_media      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_milestones_updated_at        BEFORE UPDATE ON project_milestones FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_project_roles_updated_at     BEFORE UPDATE ON project_roles      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_role_applications_updated    BEFORE UPDATE ON role_applications  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_live_events_updated_at       BEFORE UPDATE ON live_events        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_event_rsvps_updated_at       BEFORE UPDATE ON event_rsvps        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_subscriptions_updated_at     BEFORE UPDATE ON subscriptions      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_investments_updated_at       BEFORE UPDATE ON investments        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_project_updates_updated_at   BEFORE UPDATE ON project_updates    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_comments_updated_at          BEFORE UPDATE ON comments           FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Phase 1 — updated_at triggers for new tables
CREATE TRIGGER trg_discussion_categories_updated_at BEFORE UPDATE ON discussion_categories FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_discussion_resources_updated_at  BEFORE UPDATE ON discussion_resources  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_user_expertise_updated_at        BEFORE UPDATE ON user_expertise        FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ─── Discussion like counters ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_increment_discussion_likes()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.discussion_id IS NOT NULL THEN
    UPDATE discussions      SET likes_count = likes_count + 1 WHERE id = NEW.discussion_id;
  ELSE
    UPDATE discussion_replies SET likes_count = likes_count + 1 WHERE id = NEW.reply_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION fn_decrement_discussion_likes()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.discussion_id IS NOT NULL THEN
    UPDATE discussions      SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.discussion_id;
  ELSE
    UPDATE discussion_replies SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.reply_id;
  END IF;
  RETURN OLD;
END;
$$;

CREATE TRIGGER trg_increment_discussion_likes
  AFTER INSERT ON discussion_likes FOR EACH ROW EXECUTE FUNCTION fn_increment_discussion_likes();

CREATE TRIGGER trg_decrement_discussion_likes
  AFTER DELETE ON discussion_likes FOR EACH ROW EXECUTE FUNCTION fn_decrement_discussion_likes();

-- ─── Discussion vote counter  (Phase 1 — pipeline) ─────────────────────────

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

CREATE TRIGGER trg_sync_discussion_votes
  AFTER INSERT OR UPDATE OR DELETE ON discussion_votes
  FOR EACH ROW EXECUTE FUNCTION sync_discussion_votes_count();

-- ─── Discussion reply counters ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_increment_replies_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE discussions SET replies_count = replies_count + 1 WHERE id = NEW.discussion_id;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION fn_decrement_replies_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE discussions SET replies_count = GREATEST(replies_count - 1, 0) WHERE id = OLD.discussion_id;
  RETURN OLD;
END;
$$;

CREATE TRIGGER trg_increment_replies
  AFTER INSERT ON discussion_replies FOR EACH ROW EXECUTE FUNCTION fn_increment_replies_count();

CREATE TRIGGER trg_decrement_replies
  AFTER DELETE ON discussion_replies FOR EACH ROW EXECUTE FUNCTION fn_decrement_replies_count();

-- ─── Discussion media count ────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_update_discussion_media_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE discussions SET media_count = media_count + 1 WHERE id = NEW.discussion_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE discussions SET media_count = GREATEST(media_count - 1, 0) WHERE id = OLD.discussion_id;
    RETURN OLD;
  END IF;
END;
$$;

CREATE TRIGGER trg_discussion_media_count
  AFTER INSERT OR DELETE ON discussion_media FOR EACH ROW EXECUTE FUNCTION fn_update_discussion_media_count();

-- ─── Investment stats ──────────────────────────────────────────────────────
-- Updates projects.funding_raised / backers_count and
-- profiles.total_invested / projects_backed when an investment is created.

CREATE OR REPLACE FUNCTION fn_update_investment_stats()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE projects
    SET funding_raised = funding_raised + NEW.credits_invested,
        backers_count  = backers_count  + 1
    WHERE id = NEW.project_id;

    UPDATE profiles
    SET total_invested  = total_invested  + NEW.credits_invested,
        projects_backed = projects_backed + 1
    WHERE id = NEW.investor_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_investment_stats
  AFTER INSERT ON investments FOR EACH ROW EXECUTE FUNCTION fn_update_investment_stats();

-- ─── Event RSVP counter ────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_update_event_rsvp_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE live_events SET rsvp_count = rsvp_count + 1 WHERE id = NEW.event_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE live_events SET rsvp_count = GREATEST(rsvp_count - 1, 0) WHERE id = OLD.event_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_event_rsvp_count
  AFTER INSERT OR DELETE ON event_rsvps FOR EACH ROW EXECUTE FUNCTION fn_update_event_rsvp_count();

-- ─── Media upload validation ───────────────────────────────────────────────
-- Validates per-discussion media limits before insert.

CREATE OR REPLACE FUNCTION fn_validate_media_upload()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_count INTEGER;
  v_max_size BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM discussion_media WHERE discussion_id = NEW.discussion_id;
  IF v_count >= 5 THEN
    RAISE EXCEPTION 'A discussion may have at most 5 media attachments.';
  END IF;

  v_max_size := CASE WHEN NEW.media_type = 'image' THEN 10485760 ELSE 104857600 END;
  IF NEW.file_size > v_max_size THEN
    RAISE EXCEPTION 'File size exceeds the limit for % (% MB max).',
      NEW.media_type,
      CASE WHEN NEW.media_type = 'image' THEN 10 ELSE 100 END;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_media_upload
  BEFORE INSERT ON discussion_media FOR EACH ROW EXECUTE FUNCTION fn_validate_media_upload();

-- ─── Auto-create profile on auth signup ───────────────────────────────────
-- Creates a default profile row whenever a new user signs up via Supabase Auth.

CREATE OR REPLACE FUNCTION fn_handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'username',
      SPLIT_PART(NEW.email, '@', 1)
    ),
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      ''
    ),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION fn_handle_new_user();


-- ============================================================================
-- §11  Row-Level Security
-- ============================================================================

-- Enable RLS on every table
ALTER TABLE profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects            ENABLE ROW LEVEL SECURITY;
ALTER TABLE contributions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_replies  ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_likes    ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_media    ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_categories    ENABLE ROW LEVEL SECURITY;
ALTER TABLE skills              ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_offers        ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_requests      ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_media       ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_milestones  ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_roles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_applications   ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_members     ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_events         ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_rsvps         ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_chat_messages  ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_reactions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows             ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications       ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE investments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_updates     ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments            ENABLE ROW LEVEL SECURITY;

-- Phase 1 tables
ALTER TABLE discussion_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_votes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_resources  ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_expertise        ENABLE ROW LEVEL SECURITY;
ALTER TABLE expert_verifications  ENABLE ROW LEVEL SECURITY;

-- ─── profiles ──────────────────────────────────────────────────────────────
CREATE POLICY "profiles_select_public"
  ON profiles FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "profiles_insert_own"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "profiles_delete_own"
  ON profiles FOR DELETE USING (auth.uid() = id);

-- ─── projects ──────────────────────────────────────────────────────────────
-- Drafts are only visible to the owner; other statuses are public.
CREATE POLICY "projects_select_public"
  ON projects FOR SELECT
  USING (deleted_at IS NULL AND (status <> 'draft' OR owner_id = auth.uid()));
CREATE POLICY "projects_insert_own"
  ON projects FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "projects_update_own"
  ON projects FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "projects_delete_own"
  ON projects FOR DELETE USING (auth.uid() = owner_id);

-- ─── contributions ─────────────────────────────────────────────────────────
CREATE POLICY "contributions_select"
  ON contributions FOR SELECT
  USING (
    auth.uid() = contributor_id
    OR auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id)
  );
CREATE POLICY "contributions_insert_own"
  ON contributions FOR INSERT WITH CHECK (auth.uid() = contributor_id);
CREATE POLICY "contributions_update"
  ON contributions FOR UPDATE
  USING (
    auth.uid() = contributor_id
    OR auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id)
  );

-- ─── discussions ───────────────────────────────────────────────────────────
CREATE POLICY "discussions_select_public"
  ON discussions FOR SELECT
  USING (deleted_at IS NULL AND is_archived = FALSE);
CREATE POLICY "discussions_insert_authenticated"
  ON discussions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "discussions_update_own"
  ON discussions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "discussions_delete_own"
  ON discussions FOR DELETE USING (auth.uid() = user_id);

-- ─── discussion_replies ────────────────────────────────────────────────────
CREATE POLICY "replies_select_public"
  ON discussion_replies FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "replies_insert_authenticated"
  ON discussion_replies FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "replies_update_own"
  ON discussion_replies FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "replies_delete_own"
  ON discussion_replies FOR DELETE USING (auth.uid() = user_id);

-- ─── discussion_likes ──────────────────────────────────────────────────────
CREATE POLICY "discussion_likes_select_public"
  ON discussion_likes FOR SELECT USING (TRUE);
CREATE POLICY "discussion_likes_insert_own"
  ON discussion_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "discussion_likes_delete_own"
  ON discussion_likes FOR DELETE USING (auth.uid() = user_id);

-- ─── discussion_media ──────────────────────────────────────────────────────
CREATE POLICY "discussion_media_select_public"
  ON discussion_media FOR SELECT USING (TRUE);
CREATE POLICY "discussion_media_insert_authenticated"
  ON discussion_media FOR INSERT WITH CHECK (auth.uid() = uploaded_by);
CREATE POLICY "discussion_media_update_own"
  ON discussion_media FOR UPDATE USING (auth.uid() = uploaded_by);
CREATE POLICY "discussion_media_delete_own"
  ON discussion_media FOR DELETE USING (auth.uid() = uploaded_by);

-- ─── discussion_categories  (Phase 1) ──────────────────────────────────────
-- Reference data: publicly readable, write-protected.
CREATE POLICY "discussion_categories_select_public"
  ON discussion_categories FOR SELECT USING (is_active = TRUE);

-- ─── discussion_votes  (Phase 1) ──────────────────────────────────────────
CREATE POLICY "discussion_votes_select_public"
  ON discussion_votes FOR SELECT USING (TRUE);
CREATE POLICY "discussion_votes_insert_own"
  ON discussion_votes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "discussion_votes_update_own"
  ON discussion_votes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "discussion_votes_delete_own"
  ON discussion_votes FOR DELETE USING (auth.uid() = user_id);

-- ─── discussion_resources  (Phase 1) ──────────────────────────────────────
CREATE POLICY "discussion_resources_select_public"
  ON discussion_resources FOR SELECT USING (TRUE);
CREATE POLICY "discussion_resources_insert_own"
  ON discussion_resources FOR INSERT WITH CHECK (auth.uid() = uploaded_by);
CREATE POLICY "discussion_resources_update_own"
  ON discussion_resources FOR UPDATE USING (auth.uid() = uploaded_by);
CREATE POLICY "discussion_resources_delete_own"
  ON discussion_resources FOR DELETE USING (auth.uid() = uploaded_by);

-- ─── skill_categories ─────────────────────────────────────────────────────
-- Reference data: read-only for all authenticated and anonymous users.
CREATE POLICY "skill_categories_select_public"
  ON skill_categories FOR SELECT USING (TRUE);

-- ─── skills ───────────────────────────────────────────────────────────────
CREATE POLICY "skills_select_public"
  ON skills FOR SELECT USING (TRUE);
CREATE POLICY "skills_insert_own"
  ON skills FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "skills_update_own"
  ON skills FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "skills_delete_own"
  ON skills FOR DELETE USING (auth.uid() = user_id);

-- ─── skill_offers ─────────────────────────────────────────────────────────
-- Active offers are public; owners see their own (including inactive/deleted).
CREATE POLICY "skill_offers_select_public"
  ON skill_offers FOR SELECT
  USING (deleted_at IS NULL AND is_active = TRUE);
CREATE POLICY "skill_offers_select_own"
  ON skill_offers FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "skill_offers_insert_own"
  ON skill_offers FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "skill_offers_update_own"
  ON skill_offers FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "skill_offers_delete_own"
  ON skill_offers FOR DELETE USING (auth.uid() = user_id);

-- ─── skill_requests ───────────────────────────────────────────────────────
CREATE POLICY "skill_requests_select_public"
  ON skill_requests FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "skill_requests_insert_own"
  ON skill_requests FOR INSERT WITH CHECK (auth.uid() = requester_id);
CREATE POLICY "skill_requests_update_own"
  ON skill_requests FOR UPDATE USING (auth.uid() = requester_id);
CREATE POLICY "skill_requests_delete_own"
  ON skill_requests FOR DELETE USING (auth.uid() = requester_id);

-- ─── user_expertise  (Phase 1) ────────────────────────────────────────────
CREATE POLICY "user_expertise_select_public"
  ON user_expertise FOR SELECT USING (TRUE);
CREATE POLICY "user_expertise_insert_own"
  ON user_expertise FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_expertise_update_own"
  ON user_expertise FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "user_expertise_delete_own"
  ON user_expertise FOR DELETE USING (auth.uid() = user_id);

-- ─── expert_verifications  (Phase 1) ──────────────────────────────────────
CREATE POLICY "expert_verifications_select_public"
  ON expert_verifications FOR SELECT USING (TRUE);
-- Any authenticated user can endorse another user's expertise (community verifications).
-- Admin/credential verifications are applied server-side with the service role key.
CREATE POLICY "expert_verifications_insert_authenticated"
  ON expert_verifications FOR INSERT
  WITH CHECK (auth.uid() = verified_by OR verified_by IS NULL);

-- ─── project_media ────────────────────────────────────────────────────────
CREATE POLICY "project_media_select_public"
  ON project_media FOR SELECT USING (TRUE);
CREATE POLICY "project_media_insert_team"
  ON project_media FOR INSERT
  WITH CHECK (
    auth.uid() = uploaded_by
    AND (
      auth.uid() IN (SELECT owner_id FROM projects    WHERE id = project_media.project_id)
      OR auth.uid() IN (SELECT user_id  FROM project_members WHERE project_id = project_media.project_id)
    )
  );
CREATE POLICY "project_media_delete_uploader_or_owner"
  ON project_media FOR DELETE
  USING (
    auth.uid() = uploaded_by
    OR auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id)
  );

-- ─── project_milestones ───────────────────────────────────────────────────
CREATE POLICY "milestones_select_public"
  ON project_milestones FOR SELECT USING (TRUE);
CREATE POLICY "milestones_insert_owner"
  ON project_milestones FOR INSERT
  WITH CHECK (auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id));
CREATE POLICY "milestones_update_owner"
  ON project_milestones FOR UPDATE
  USING (auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id));
CREATE POLICY "milestones_delete_owner"
  ON project_milestones FOR DELETE
  USING (auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id));

-- ─── project_roles ────────────────────────────────────────────────────────
CREATE POLICY "project_roles_select_public"
  ON project_roles FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "project_roles_insert_owner"
  ON project_roles FOR INSERT
  WITH CHECK (auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id));
CREATE POLICY "project_roles_update_owner"
  ON project_roles FOR UPDATE
  USING (auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id));
CREATE POLICY "project_roles_delete_owner"
  ON project_roles FOR DELETE
  USING (auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id));

-- ─── role_applications ────────────────────────────────────────────────────
CREATE POLICY "role_applications_select"
  ON role_applications FOR SELECT
  USING (
    auth.uid() = user_id
    OR auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id)
  );
CREATE POLICY "role_applications_insert_own"
  ON role_applications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "role_applications_update"
  ON role_applications FOR UPDATE
  USING (
    auth.uid() = user_id
    OR auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id)
  );
CREATE POLICY "role_applications_delete_own"
  ON role_applications FOR DELETE USING (auth.uid() = user_id);

-- ─── project_members ──────────────────────────────────────────────────────
CREATE POLICY "project_members_select_public"
  ON project_members FOR SELECT USING (TRUE);
CREATE POLICY "project_members_insert_owner"
  ON project_members FOR INSERT
  WITH CHECK (auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id));
CREATE POLICY "project_members_delete_owner_or_self"
  ON project_members FOR DELETE
  USING (
    auth.uid() = user_id
    OR auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id)
  );

-- ─── live_events ──────────────────────────────────────────────────────────
CREATE POLICY "live_events_select_public"
  ON live_events FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "live_events_insert_authenticated"
  ON live_events FOR INSERT WITH CHECK (auth.uid() = host_id);
CREATE POLICY "live_events_update_host"
  ON live_events FOR UPDATE USING (auth.uid() = host_id);
CREATE POLICY "live_events_delete_host"
  ON live_events FOR DELETE USING (auth.uid() = host_id);

-- ─── event_rsvps ──────────────────────────────────────────────────────────
CREATE POLICY "event_rsvps_select_public"
  ON event_rsvps FOR SELECT USING (TRUE);
CREATE POLICY "event_rsvps_insert_own"
  ON event_rsvps FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "event_rsvps_update_own"
  ON event_rsvps FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "event_rsvps_delete_own"
  ON event_rsvps FOR DELETE USING (auth.uid() = user_id);

-- ─── live_chat_messages ───────────────────────────────────────────────────
CREATE POLICY "live_chat_select_public"
  ON live_chat_messages FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "live_chat_insert_authenticated"
  ON live_chat_messages FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "live_chat_delete_own_or_host"
  ON live_chat_messages FOR DELETE
  USING (
    auth.uid() = user_id
    OR auth.uid() IN (SELECT host_id FROM live_events WHERE id = event_id)
  );

-- ─── live_reactions ───────────────────────────────────────────────────────
CREATE POLICY "live_reactions_select_public"
  ON live_reactions FOR SELECT USING (TRUE);
CREATE POLICY "live_reactions_insert_authenticated"
  ON live_reactions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ─── follows ──────────────────────────────────────────────────────────────
CREATE POLICY "follows_select_public"
  ON follows FOR SELECT USING (TRUE);
CREATE POLICY "follows_insert_own"
  ON follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "follows_delete_own"
  ON follows FOR DELETE USING (auth.uid() = follower_id);

-- ─── notifications ────────────────────────────────────────────────────────
CREATE POLICY "notifications_select_own"
  ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notifications_update_own"
  ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- ─── subscriptions ────────────────────────────────────────────────────────
-- Managed by the Stripe webhook edge function (service role); users can read own.
CREATE POLICY "subscriptions_select_own"
  ON subscriptions FOR SELECT USING (auth.uid() = user_id);

-- ─── credit_transactions ──────────────────────────────────────────────────
-- Immutable: insert only via service-role functions; users can read own.
CREATE POLICY "credit_transactions_select_own"
  ON credit_transactions FOR SELECT USING (auth.uid() = user_id);

-- ─── investments ──────────────────────────────────────────────────────────
CREATE POLICY "investments_select_investor"
  ON investments FOR SELECT USING (auth.uid() = investor_id);
CREATE POLICY "investments_select_project_owner"
  ON investments FOR SELECT
  USING (auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id));
CREATE POLICY "investments_insert_own"
  ON investments FOR INSERT WITH CHECK (auth.uid() = investor_id);

-- ─── project_updates ──────────────────────────────────────────────────────
CREATE POLICY "project_updates_select_public"
  ON project_updates FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "project_updates_insert_owner"
  ON project_updates FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id)
  );
CREATE POLICY "project_updates_update_owner"
  ON project_updates FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "project_updates_delete_owner"
  ON project_updates FOR DELETE USING (auth.uid() = user_id);

-- ─── comments ─────────────────────────────────────────────────────────────
CREATE POLICY "comments_select_public"
  ON comments FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "comments_insert_authenticated"
  ON comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "comments_update_own"
  ON comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "comments_delete_own"
  ON comments FOR DELETE USING (auth.uid() = user_id);


-- ============================================================================
-- §12  Views
-- ============================================================================

-- User investment portfolio
CREATE OR REPLACE VIEW user_portfolio AS
SELECT
  i.investor_id                      AS user_id,
  COUNT(DISTINCT i.project_id)       AS projects_backed,
  SUM(i.credits_invested)            AS total_credits_invested,
  SUM(i.equity_percentage)           AS total_equity_percentage,
  SUM(i.equity_value_usd)            AS total_equity_value_usd
FROM investments i
WHERE i.status = 'active'
GROUP BY i.investor_id;

COMMENT ON VIEW user_portfolio IS 'Aggregated investment portfolio per user (active investments only).';


-- Project funding progress
CREATE OR REPLACE VIEW project_funding_summary AS
SELECT
  p.id                  AS project_id,
  p.title,
  p.funding_goal,
  p.funding_raised,
  p.backers_count,
  ROUND(
    (p.funding_raised::NUMERIC / NULLIF(p.funding_goal, 0)) * 100,
    2
  )                     AS funding_percentage,
  p.funding_deadline,
  p.status,
  p.equity_offered
FROM projects p
WHERE p.deleted_at IS NULL;

COMMENT ON VIEW project_funding_summary IS 'Funding progress per project, including percentage raised.';


-- Trending discussions (past 7 days, ranked by engagement)
CREATE OR REPLACE VIEW trending_discussions AS
SELECT
  d.id,
  d.title,
  d.category,
  d.user_id,
  d.likes_count,
  d.replies_count,
  d.views_count,
  d.media_count,
  (d.likes_count * 2 + d.replies_count * 3 + d.views_count) AS trending_score,
  d.created_at,
  p.full_name   AS author_name,
  p.avatar_url  AS author_avatar
FROM discussions d
JOIN profiles p ON d.user_id = p.id
WHERE d.created_at > NOW() - INTERVAL '7 days'
  AND d.deleted_at  IS NULL
  AND d.is_archived = FALSE
ORDER BY trending_score DESC;

COMMENT ON VIEW trending_discussions IS 'Hot discussions in the last 7 days ranked by weighted engagement score.';


-- Discussions with media attachments pre-aggregated
CREATE OR REPLACE VIEW discussions_with_media AS
SELECT
  d.id,
  d.title,
  d.content,
  d.category,
  d.tags,
  d.user_id,
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
JOIN profiles p ON d.user_id = p.id
LEFT JOIN discussion_media dm ON d.id = dm.discussion_id
WHERE d.deleted_at IS NULL
GROUP BY d.id, p.id, p.full_name, p.avatar_url;

COMMENT ON VIEW discussions_with_media IS 'Discussions with author info, Phase 1 pipeline columns (stage, votes_count, linked_project_id), and media attachments pre-aggregated as a JSON array.';


-- ============================================================================
-- §13  Reference Data — Skill Categories
-- ============================================================================

INSERT INTO skill_categories (name, parent_category, description, icon, color, display_order) VALUES
  -- TECHNICAL
  ('Frontend Development',   'Technical', 'React, Vue, Angular, HTML/CSS',                 '💻', '#3B82F6',  1),
  ('Backend Development',    'Technical', 'Node.js, Python, Java, PHP',                    '⚙️', '#3B82F6',  2),
  ('Mobile Development',     'Technical', 'Flutter, React Native, iOS, Android',           '📱', '#3B82F6',  3),
  ('DevOps & Cloud',         'Technical', 'AWS, Docker, Kubernetes, CI/CD',                '☁️', '#3B82F6',  4),
  ('Data Science & AI',      'Technical', 'Machine Learning, Analytics, Python',           '🤖', '#3B82F6',  5),
  ('Database Management',    'Technical', 'SQL, PostgreSQL, MongoDB, Redis',               '🗄️', '#3B82F6',  6),
  ('Blockchain & Web3',      'Technical', 'Solidity, Smart Contracts, Crypto',             '⛓️', '#3B82F6',  7),
  ('QA & Testing',           'Technical', 'Automated Testing, Quality Assurance',          '🧪', '#3B82F6',  8),
  ('UI/UX Design',           'Technical', 'User Interface, User Experience Design',        '🎨', '#3B82F6',  9),
  ('Cybersecurity',          'Technical', 'Security, Penetration Testing, Compliance',     '🔒', '#3B82F6', 10),

  -- BUSINESS
  ('Business Strategy',      'Business',  'Strategic Planning, Business Models',           '📊', '#10B981',  1),
  ('Financial Planning',     'Business',  'Budgeting, Forecasting, Financial Modeling',    '💰', '#10B981',  2),
  ('Fundraising',            'Business',  'VC Relations, Investor Pitching, Grants',       '💸', '#10B981',  3),
  ('Accounting',             'Business',  'Bookkeeping, Financial Reporting, Tax',         '🧮', '#10B981',  4),
  ('Budget Management',      'Business',  'Cost Control, Financial Planning',              '💵', '#10B981',  5),
  ('Investor Relations',     'Business',  'Stakeholder Communication, Reporting',          '🤝', '#10B981',  6),
  ('Grant Writing',          'Business',  'Proposal Writing, Non-Profit Funding',          '✍️', '#10B981',  7),
  ('Business Development',   'Business',  'Partnerships, Sales, Growth',                   '📈', '#10B981',  8),
  ('Entrepreneurship',       'Business',  'Startup Building, Innovation',                  '🚀', '#10B981',  9),

  -- MARKETING
  ('Digital Marketing',       'Marketing', 'Online Marketing Strategy, Campaigns',         '📢', '#F59E0B',  1),
  ('Content Marketing',       'Marketing', 'Content Strategy, Blogging, Thought Leadership','📝','#F59E0B',  2),
  ('Social Media Marketing',  'Marketing', 'Facebook, Instagram, Twitter, LinkedIn',       '📱', '#F59E0B',  3),
  ('SEO & SEM',               'Marketing', 'Search Engine Optimization, Google Ads',       '🔍', '#F59E0B',  4),
  ('Email Marketing',         'Marketing', 'Campaigns, Automation, Newsletters',           '📧', '#F59E0B',  5),
  ('Growth Hacking',          'Marketing', 'Rapid Experimentation, Viral Growth',          '🚀', '#F59E0B',  6),
  ('PR & Communications',     'Marketing', 'Public Relations, Media, Press',               '📰', '#F59E0B',  7),
  ('Brand Strategy',          'Marketing', 'Branding, Positioning, Identity',              '🎯', '#F59E0B',  8),
  ('Copywriting',             'Marketing', 'Sales Copy, Ad Copy, Messaging',               '✏️', '#F59E0B',  9),
  ('Community Management',    'Marketing', 'Online Communities, Engagement',               '👥', '#F59E0B', 10),
  ('Influencer Marketing',    'Marketing', 'Partnerships, Sponsorships',                   '⭐', '#F59E0B', 11),
  ('Marketing Analytics',     'Marketing', 'Data Analysis, KPIs, ROI Tracking',            '📊', '#F59E0B', 12),

  -- OPERATIONS
  ('Project Management',      'Operations', 'Planning, Execution, Agile, Scrum',          '📋', '#8B5CF6',  1),
  ('Product Management',      'Operations', 'Product Strategy, Roadmaps, Features',       '📦', '#8B5CF6',  2),
  ('Operations Management',   'Operations', 'Process Optimization, Efficiency',           '⚙️', '#8B5CF6',  3),
  ('Supply Chain Management', 'Operations', 'Logistics, Procurement, Distribution',       '🚚', '#8B5CF6',  4),
  ('Process Optimization',    'Operations', 'Lean, Six Sigma, Efficiency',                '📈', '#8B5CF6',  5),
  ('Agile/Scrum Master',      'Operations', 'Agile Methodologies, Sprint Planning',       '🏃', '#8B5CF6',  6),
  ('Customer Success',        'Operations', 'Client Relations, Retention, Support',       '😊', '#8B5CF6',  7),
  ('HR & Recruiting',         'Operations', 'Hiring, Talent Acquisition, Culture',        '👔', '#8B5CF6',  8),
  ('Event Planning',          'Operations', 'Conferences, Meetups, Coordination',         '🎉', '#8B5CF6',  9),

  -- CREATIVE
  ('Graphic Design',          'Creative', 'Visual Design, Branding, Print',               '🎨', '#EC4899',  1),
  ('Video Production',        'Creative', 'Filming, Editing, Post-Production',            '🎥', '#EC4899',  2),
  ('Animation',               'Creative', '2D/3D Animation, Motion Graphics',             '🎬', '#EC4899',  3),
  ('Photography',             'Creative', 'Product, Portrait, Event Photography',         '📷', '#EC4899',  4),
  ('Illustration',            'Creative', 'Digital Art, Drawing, Character Design',       '🖌️', '#EC4899',  5),
  ('3D Modeling',             'Creative', '3D Design, Rendering, CAD',                    '🧊', '#EC4899',  6),
  ('Audio Production',        'Creative', 'Podcast, Music, Sound Design',                 '🎵', '#EC4899',  7),
  ('Content Writing',         'Creative', 'Articles, Blogs, Web Content',                 '✍️', '#EC4899',  8),
  ('Technical Writing',       'Creative', 'Documentation, Guides, Manuals',               '📖', '#EC4899',  9),
  ('Voice Acting',            'Creative', 'Narration, Character Voices',                  '🎙️', '#EC4899', 10),

  -- LEGAL
  ('Business Law',            'Legal', 'Corporate Law, Business Regulations',             '⚖️', '#6366F1',  1),
  ('Contract Negotiation',    'Legal', 'Agreements, Terms, Legal Review',                 '📜', '#6366F1',  2),
  ('Intellectual Property',   'Legal', 'Patents, Trademarks, Copyrights',                 '©️', '#6366F1',  3),
  ('Regulatory Compliance',   'Legal', 'Industry Regulations, Standards',                 '✅', '#6366F1',  4),
  ('Privacy & GDPR',          'Legal', 'Data Protection, Privacy Laws',                   '🔐', '#6366F1',  5),
  ('Employment Law',          'Legal', 'HR Legal, Labor Laws',                            '👔', '#6366F1',  6),

  -- DOMAIN
  ('Healthcare',                'Domain', 'Medical, HealthTech, Clinical',                '🏥', '#EF4444',  1),
  ('Education & EdTech',        'Domain', 'Teaching, Learning, Curriculum',               '📚', '#EF4444',  2),
  ('Finance & FinTech',         'Domain', 'Banking, Payments, Financial Services',        '💳', '#EF4444',  3),
  ('Climate & Sustainability',  'Domain', 'Environmental, Green Tech, ESG',               '🌱', '#EF4444',  4),
  ('Non-Profit & Social Impact','Domain', 'Charity, Community, NGO',                      '❤️', '#EF4444',  5),
  ('Real Estate & PropTech',    'Domain', 'Property, Construction, Housing',              '🏠', '#EF4444',  6),
  ('Agriculture & AgTech',      'Domain', 'Farming, Food Systems, Rural',                 '🌾', '#EF4444',  7),
  ('Government & Civic Tech',   'Domain', 'Public Sector, Policy, Governance',           '🏛️', '#EF4444',  8),
  ('Retail & E-Commerce',       'Domain', 'Online Shopping, Stores, Logistics',           '🛒', '#EF4444',  9),
  ('Travel & Hospitality',      'Domain', 'Tourism, Hotels, Transportation',              '✈️', '#EF4444', 10),
  ('Sports & Fitness',          'Domain', 'Athletics, Wellness, Training',                '⚽', '#EF4444', 11),
  ('Entertainment & Media',     'Domain', 'Film, Music, Gaming, Streaming',               '🎮', '#EF4444', 12),

  -- SOFT SKILLS
  ('Leadership',            'Soft Skills', 'Team Leadership, Management, Vision',         '👑', '#06B6D4',  1),
  ('Mentorship',            'Soft Skills', 'Coaching, Guidance, Training',                '🎓', '#06B6D4',  2),
  ('Public Speaking',       'Soft Skills', 'Presentations, Talks, Speaking',              '🎤', '#06B6D4',  3),
  ('Networking',            'Soft Skills', 'Relationship Building, Connections',          '🤝', '#06B6D4',  4),
  ('Sales',                 'Soft Skills', 'Selling, Negotiation, Closing',               '💼', '#06B6D4',  5),
  ('Customer Service',      'Soft Skills', 'Support, Client Relations',                   '📞', '#06B6D4',  6),
  ('Teaching & Training',   'Soft Skills', 'Education, Workshops, Facilitation',          '👨‍🏫', '#06B6D4',  7),
  ('Research',              'Soft Skills', 'Analysis, Investigation, Studies',            '🔬', '#06B6D4',  8),
  ('Consulting',            'Soft Skills', 'Advisory, Expert Guidance',                   '💡', '#06B6D4',  9),
  ('Community Organizing',  'Soft Skills', 'Grassroots Organizing, Advocacy, Mobilization','✊', '#06B6D4', 10)
ON CONFLICT (name) DO NOTHING;


-- ─── discussion_categories seed  (Phase 1 — Community Foundation) ─────────
INSERT INTO discussion_categories
  (slug, label, description, emoji, color_hex, is_systemic, display_order)
VALUES
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
