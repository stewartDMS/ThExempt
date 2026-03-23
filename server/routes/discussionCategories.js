/**
 * Phase 1 — Enhanced systemic discussion categories
 *
 * Routes:
 *   GET  /api/discussion-categories          List all active categories
 *   GET  /api/discussion-categories/:slug    Get a single category by slug
 *
 * Queries the discussion_categories table seeded by migration 001.
 */

'use strict';

const express = require('express');

/**
 * @param {import('@supabase/supabase-js').SupabaseClient} supabase
 */
function createRouter(supabase) {
  const router = express.Router();

  // GET /api/discussion-categories
  // Query params: systemic=true
  router.get('/', async (req, res) => {
    try {
      let query = supabase
        .from('discussion_categories')
        .select('*')
        .eq('is_active', true)
        .order('display_order', { ascending: true });

      if (req.query.systemic === 'true') {
        query = query.eq('is_systemic', true);
      }

      const { data, error } = await query;
      if (error) throw error;
      res.json(data);
    } catch (error) {
      console.error('List discussion categories error:', error);
      res.status(500).json({ error: 'Failed to fetch discussion categories' });
    }
  });

  // GET /api/discussion-categories/:slug
  router.get('/:slug', async (req, res) => {
    try {
      const { data, error } = await supabase
        .from('discussion_categories')
        .select('*')
        .eq('slug', req.params.slug)
        .eq('is_active', true)
        .single();

      if (error || !data) return res.status(404).json({ error: 'Category not found' });
      res.json(data);
    } catch (error) {
      console.error('Get discussion category error:', error);
      res.status(500).json({ error: 'Failed to fetch discussion category' });
    }
  });

  return router;
}

module.exports = createRouter;
