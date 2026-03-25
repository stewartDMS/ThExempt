/**
 * Phase 1 — Problem → Solution → Project pipeline
 *
 * Routes:
 *   PUT    /api/discussions/:id/stage         Set pipeline stage (owner only)
 *   GET    /api/discussions/:id/votes         Get vote totals
 *   POST   /api/discussions/:id/votes         Cast or update a vote
 *   DELETE /api/discussions/:id/votes         Retract a vote
 *   PUT    /api/discussions/:id/link-project  Link discussion to a project
 */

'use strict';

const express = require('express');

const VALID_STAGES = ['problem', 'solution', 'project_proposal', 'project_linked'];

/**
 * @param {import('@supabase/supabase-js').SupabaseClient} supabase
 * @param {Function} authenticateToken
 */
function createRouter(supabase, authenticateToken) {
  const router = express.Router({ mergeParams: true });

  // ── Stage management ──────────────────────────────────────────────────────

  // PUT /api/discussions/:id/stage
  router.put('/stage', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const { stage } = req.body;

      if (!stage || !VALID_STAGES.includes(stage)) {
        return res.status(400).json({
          error: `'stage' must be one of: ${VALID_STAGES.join(', ')}`,
        });
      }

      const { data: discussion, error: fetchErr } = await supabase
        .from('discussions')
        .select('user_id')
        .eq('id', id)
        .single();

      if (fetchErr || !discussion) return res.status(404).json({ error: 'Discussion not found' });
      if (discussion.user_id !== req.user.id) {
        return res.status(403).json({ error: 'Only the discussion author can change the pipeline stage' });
      }

      const { data, error } = await supabase
        .from('discussions')
        .update({ stage })
        .eq('id', id)
        .select('id, stage, updated_at')
        .single();

      if (error) throw error;
      res.json(data);
    } catch (error) {
      console.error('Update discussion stage error:', error);
      res.status(500).json({ error: 'Failed to update discussion stage' });
    }
  });

  // ── Voting ────────────────────────────────────────────────────────────────

  // GET /api/discussions/:id/votes
  router.get('/votes', async (req, res) => {
    try {
      const { id } = req.params;

      const { data: discussion, error: discErr } = await supabase
        .from('discussions')
        .select('votes_count')
        .eq('id', id)
        .single();

      if (discErr || !discussion) return res.status(404).json({ error: 'Discussion not found' });

      const { data: breakdown, error: brkErr } = await supabase
        .from('discussion_votes')
        .select('value')
        .eq('discussion_id', id);

      if (brkErr) throw brkErr;

      const upvotes   = (breakdown || []).filter((v) => v.value === 1).length;
      const downvotes = (breakdown || []).filter((v) => v.value === -1).length;

      // If the caller is authenticated, include their own vote
      let userVote = null;
      const authHeader = req.headers['authorization'];
      const token = authHeader && authHeader.split(' ')[1];
      if (token) {
        const { data: { user } } = await supabase.auth.getUser(token);
        if (user) {
          const { data: ownVote } = await supabase
            .from('discussion_votes')
            .select('value')
            .eq('discussion_id', id)
            .eq('user_id', user.id)
            .single();
          userVote = ownVote?.value ?? null;
        }
      }

      res.json({
        discussion_id: id,
        votes_count: discussion.votes_count,
        upvotes,
        downvotes,
        user_vote: userVote,
      });
    } catch (error) {
      console.error('Get discussion votes error:', error);
      res.status(500).json({ error: 'Failed to fetch votes' });
    }
  });

  // POST /api/discussions/:id/votes
  router.post('/votes', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const { value } = req.body;

      if (value !== 1 && value !== -1) {
        return res.status(400).json({ error: "'value' must be 1 (upvote) or -1 (downvote)" });
      }

      const { data, error } = await supabase
        .from('discussion_votes')
        .upsert(
          { discussion_id: id, user_id: req.user.id, value },
          { onConflict: 'discussion_id,user_id' }
        )
        .select('id, discussion_id, user_id, value, created_at')
        .single();

      if (error) throw error;
      res.status(201).json(data);
    } catch (error) {
      console.error('Cast discussion vote error:', error);
      res.status(500).json({ error: 'Failed to cast vote' });
    }
  });

  // DELETE /api/discussions/:id/votes
  router.delete('/votes', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;

      const { error } = await supabase
        .from('discussion_votes')
        .delete()
        .eq('discussion_id', id)
        .eq('user_id', req.user.id);

      if (error) throw error;
      res.status(204).send();
    } catch (error) {
      console.error('Delete discussion vote error:', error);
      res.status(500).json({ error: 'Failed to retract vote' });
    }
  });

  // ── Project linkage ───────────────────────────────────────────────────────

  // PUT /api/discussions/:id/link-project
  router.put('/link-project', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const { project_id } = req.body;

      if (!project_id) {
        return res.status(400).json({ error: "'project_id' is required" });
      }

      const { data: discussion, error: discErr } = await supabase
        .from('discussions')
        .select('user_id')
        .eq('id', id)
        .single();

      if (discErr || !discussion) return res.status(404).json({ error: 'Discussion not found' });
      if (discussion.user_id !== req.user.id) {
        return res.status(403).json({ error: 'Only the discussion author can link a project' });
      }

      const { data: project, error: projErr } = await supabase
        .from('projects')
        .select('id')
        .eq('id', project_id)
        .single();

      if (projErr || !project) return res.status(404).json({ error: 'Project not found' });

      const { data, error } = await supabase
        .from('discussions')
        .update({ stage: 'project_linked', linked_project_id: project_id })
        .eq('id', id)
        .select('id, stage, linked_project_id, updated_at')
        .single();

      if (error) throw error;
      res.json(data);
    } catch (error) {
      console.error('Link discussion to project error:', error);
      res.status(500).json({ error: 'Failed to link project' });
    }
  });

  return router;
}

module.exports = createRouter;
