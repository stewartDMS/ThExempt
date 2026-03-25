/**
 * Phase 1 — Expert badges & trust system
 *
 * Routes:
 *   GET    /api/users/:userId/expertise                          List expertise areas
 *   POST   /api/users/me/expertise                              Add expertise (self-declared)
 *   DELETE /api/users/me/expertise/:expertiseId                 Remove expertise
 *   POST   /api/users/:userId/expertise/:expertiseId/verify     Endorse another user's expertise
 *   GET    /api/users/:userId/badges                            List earned badges
 *
 * Trust score badge thresholds (awarded on profiles.badges array):
 *   Contributor        trust_score / reputation >= 100
 *   Expert             >= 500
 *   Master             >= 1000
 *   Verified Expert    has at least one expert_verified expertise entry
 *   Community Pillar   has given >= 10 community verifications
 *   Movement Builder   has linked a discussion to a project
 *   Resource Contributor has added >= 5 discussion resources
 */

'use strict';

const express = require('express');

/**
 * @param {import('@supabase/supabase-js').SupabaseClient} supabase
 * @param {Function} authenticateToken
 */
function createRouter(supabase, authenticateToken) {
  const router = express.Router();

  // ── Expertise areas ───────────────────────────────────────────────────────

  // GET /api/users/:userId/expertise
  router.get('/users/:userId/expertise', async (req, res) => {
    try {
      const { data, error } = await supabase
        .from('user_expertise')
        .select('*, expert_verifications(id, verification_type, verified_by, created_at)')
        .eq('user_id', req.params.userId)
        .order('is_primary', { ascending: false })
        .order('created_at', { ascending: true });

      if (error) throw error;
      res.json(data || []);
    } catch (error) {
      console.error('List user expertise error:', error);
      res.status(500).json({ error: 'Failed to fetch expertise' });
    }
  });

  // POST /api/users/me/expertise
  router.post('/users/me/expertise', authenticateToken, async (req, res) => {
    try {
      const { area, level = 'self_declared', evidence_url, is_primary = false } = req.body;

      if (!area) return res.status(400).json({ error: "'area' is required" });

      const validLevels = ['self_declared', 'community_verified', 'expert_verified', 'platform_verified'];
      if (!validLevels.includes(level)) {
        return res.status(400).json({ error: `'level' must be one of: ${validLevels.join(', ')}` });
      }

      // If marking this as primary, clear existing primary first
      if (is_primary) {
        await supabase
          .from('user_expertise')
          .update({ is_primary: false })
          .eq('user_id', req.user.id)
          .eq('is_primary', true);
      }

      const { data, error } = await supabase
        .from('user_expertise')
        .insert({ user_id: req.user.id, area, level, evidence_url: evidence_url || null, is_primary })
        .select()
        .single();

      if (error) throw error;
      res.status(201).json(data);
    } catch (error) {
      console.error('Add expertise error:', error);
      res.status(500).json({ error: 'Failed to add expertise' });
    }
  });

  // DELETE /api/users/me/expertise/:expertiseId
  router.delete('/users/me/expertise/:expertiseId', authenticateToken, async (req, res) => {
    try {
      const { error } = await supabase
        .from('user_expertise')
        .delete()
        .eq('id', req.params.expertiseId)
        .eq('user_id', req.user.id);

      if (error) throw error;
      res.status(204).send();
    } catch (error) {
      console.error('Delete expertise error:', error);
      res.status(500).json({ error: 'Failed to remove expertise' });
    }
  });

  // ── Verifications ─────────────────────────────────────────────────────────

  // POST /api/users/:userId/expertise/:expertiseId/verify
  router.post('/users/:userId/expertise/:expertiseId/verify', authenticateToken, async (req, res) => {
    try {
      const { expertiseId } = req.params;
      const { verification_type = 'community', notes } = req.body;

      const validTypes = ['community', 'admin', 'credential'];
      if (!validTypes.includes(verification_type)) {
        return res.status(400).json({ error: `'verification_type' must be one of: ${validTypes.join(', ')}` });
      }

      // Confirm the expertise entry exists and belongs to the target user
      const { data: expertise, error: expErr } = await supabase
        .from('user_expertise')
        .select('id, user_id, level')
        .eq('id', expertiseId)
        .eq('user_id', req.params.userId)
        .single();

      if (expErr || !expertise) return res.status(404).json({ error: 'Expertise entry not found' });

      // A user cannot endorse their own expertise
      if (expertise.user_id === req.user.id) {
        return res.status(400).json({ error: 'You cannot endorse your own expertise' });
      }

      const { data: verification, error: verErr } = await supabase
        .from('expert_verifications')
        .insert({
          user_expertise_id: expertiseId,
          verified_by: req.user.id,
          verification_type,
          notes: notes || null,
        })
        .select()
        .single();

      if (verErr) throw verErr;

      // Escalate the expertise level after community verification
      if (verification_type === 'community' && expertise.level === 'self_declared') {
        const { count } = await supabase
          .from('expert_verifications')
          .select('id', { count: 'exact', head: true })
          .eq('user_expertise_id', expertiseId)
          .eq('verification_type', 'community');

        if ((count || 0) >= 3) {
          await supabase
            .from('user_expertise')
            .update({ level: 'community_verified' })
            .eq('id', expertiseId);
        }
      }

      res.status(201).json(verification);
    } catch (error) {
      console.error('Verify expertise error:', error);
      res.status(500).json({ error: 'Failed to verify expertise' });
    }
  });

  // ── Badges ────────────────────────────────────────────────────────────────

  // GET /api/users/:userId/badges
  router.get('/users/:userId/badges', async (req, res) => {
    try {
      const { userId } = req.params;

      const { data: profile, error: profErr } = await supabase
        .from('profiles')
        .select('trust_score, badges, expertise_level')
        .eq('id', userId)
        .single();

      if (profErr || !profile) return res.status(404).json({ error: 'User not found' });

      // Count expert-level expertise entries
      const { count: expertCount } = await supabase
        .from('user_expertise')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)
        .in('level', ['expert_verified', 'platform_verified']);

      // Count community verifications given by this user
      const { count: verificationsGiven } = await supabase
        .from('expert_verifications')
        .select('id', { count: 'exact', head: true })
        .eq('verified_by', userId)
        .eq('verification_type', 'community');

      // Check if the user has ever linked a discussion to a project
      const { count: linkedDiscussions } = await supabase
        .from('discussions')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('stage', 'project_linked');

      // Count resources contributed
      const { count: resourceCount } = await supabase
        .from('discussion_resources')
        .select('id', { count: 'exact', head: true })
        .eq('uploaded_by', userId);

      const earned = new Set(profile.badges || []);
      const score  = profile.trust_score || 0;

      if (score >= 100)  earned.add('Contributor');
      if (score >= 500)  earned.add('Expert');
      if (score >= 1000) earned.add('Master');
      if ((expertCount  || 0) >= 1)  earned.add('Verified Expert');
      if ((verificationsGiven || 0) >= 10) earned.add('Community Pillar');
      if ((linkedDiscussions || 0) >= 1)  earned.add('Movement Builder');
      if ((resourceCount || 0) >= 5)      earned.add('Resource Contributor');

      const badgeList = [...earned];

      // Persist any newly earned badges back to the profile
      if (badgeList.length !== (profile.badges || []).length) {
        await supabase
          .from('profiles')
          .update({ badges: badgeList })
          .eq('id', userId);
      }

      res.json({ user_id: userId, badges: badgeList, trust_score: score });
    } catch (error) {
      console.error('Get badges error:', error);
      res.status(500).json({ error: 'Failed to fetch badges' });
    }
  });

  return router;
}

module.exports = createRouter;
