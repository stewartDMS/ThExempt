/**
 * Phase 1 — Resource library within discussions
 *
 * Routes:
 *   GET    /api/discussions/:id/resources          List resources
 *   POST   /api/discussions/:id/resources          Add a resource
 *   PATCH  /api/discussions/:id/resources/:rId     Update a resource (owner only)
 *   DELETE /api/discussions/:id/resources/:rId     Delete a resource (owner only)
 *
 * File uploads are handled separately via Supabase Storage (bucket: discussion-resources).
 * This API stores and retrieves the metadata + public URL.
 */

'use strict';

const express = require('express');

const VALID_RESOURCE_TYPES = ['link', 'document', 'video', 'image', 'dataset'];

/**
 * @param {import('@supabase/supabase-js').SupabaseClient} supabase
 * @param {Function} authenticateToken
 */
function createRouter(supabase, authenticateToken) {
  const router = express.Router({ mergeParams: true });

  // GET /api/discussions/:id/resources
  router.get('/', async (req, res) => {
    try {
      const { id } = req.params;
      const { type, featured } = req.query;

      if (type && !VALID_RESOURCE_TYPES.includes(type)) {
        return res.status(400).json({ error: `'type' must be one of: ${VALID_RESOURCE_TYPES.join(', ')}` });
      }

      let query = supabase
        .from('discussion_resources')
        .select('*, profiles:uploaded_by(id, username, avatar_url)')
        .eq('discussion_id', id)
        .order('is_featured', { ascending: false })
        .order('created_at', { ascending: false });

      if (type)              query = query.eq('resource_type', type);
      if (featured === 'true') query = query.eq('is_featured', true);

      const { data, error } = await query;
      if (error) throw error;
      res.json(data || []);
    } catch (error) {
      console.error('List discussion resources error:', error);
      res.status(500).json({ error: 'Failed to fetch resources' });
    }
  });

  // POST /api/discussions/:id/resources
  router.post('/', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const {
        resource_type,
        title,
        description,
        url,
        file_name,
        file_size,
        mime_type,
        tags,
        is_featured = false,
      } = req.body;

      if (!resource_type || !VALID_RESOURCE_TYPES.includes(resource_type)) {
        return res.status(400).json({
          error: `'resource_type' is required and must be one of: ${VALID_RESOURCE_TYPES.join(', ')}`,
        });
      }
      if (!title) return res.status(400).json({ error: "'title' is required" });
      if (resource_type === 'link' && !url) {
        return res.status(400).json({ error: "'url' is required for resource_type 'link'" });
      }

      // Confirm discussion exists
      const { data: discussion, error: discErr } = await supabase
        .from('discussions')
        .select('id')
        .eq('id', id)
        .single();

      if (discErr || !discussion) return res.status(404).json({ error: 'Discussion not found' });

      const { data, error } = await supabase
        .from('discussion_resources')
        .insert({
          discussion_id: id,
          uploaded_by: req.user.id,
          resource_type,
          title,
          description: description || null,
          url: url || null,
          file_name: file_name || null,
          file_size: file_size || null,
          mime_type: mime_type || null,
          tags: tags || [],
          is_featured,
        })
        .select('*, profiles:uploaded_by(id, username, avatar_url)')
        .single();

      if (error) throw error;
      res.status(201).json(data);
    } catch (error) {
      console.error('Add discussion resource error:', error);
      res.status(500).json({ error: 'Failed to add resource' });
    }
  });

  // PATCH /api/discussions/:id/resources/:rId
  router.patch('/:rId', authenticateToken, async (req, res) => {
    try {
      const { id, rId } = req.params;
      const { title, description, tags, is_featured } = req.body;

      const updateFields = {};
      if (title       !== undefined) updateFields.title       = title;
      if (description !== undefined) updateFields.description = description;
      if (tags        !== undefined) updateFields.tags        = tags;
      if (is_featured !== undefined) updateFields.is_featured = is_featured;

      if (Object.keys(updateFields).length === 0) {
        return res.status(400).json({ error: 'No updatable fields provided' });
      }

      const { data, error } = await supabase
        .from('discussion_resources')
        .update(updateFields)
        .eq('id', rId)
        .eq('discussion_id', id)
        .eq('uploaded_by', req.user.id)
        .select()
        .single();

      if (error) throw error;
      if (!data) return res.status(404).json({ error: 'Resource not found or not owned by you' });
      res.json(data);
    } catch (error) {
      console.error('Update discussion resource error:', error);
      res.status(500).json({ error: 'Failed to update resource' });
    }
  });

  // DELETE /api/discussions/:id/resources/:rId
  router.delete('/:rId', authenticateToken, async (req, res) => {
    try {
      const { id, rId } = req.params;

      const { data: resource, error: fetchErr } = await supabase
        .from('discussion_resources')
        .select('id, uploaded_by, url, file_name')
        .eq('id', rId)
        .eq('discussion_id', id)
        .single();

      if (fetchErr || !resource) return res.status(404).json({ error: 'Resource not found' });
      if (resource.uploaded_by !== req.user.id) {
        return res.status(403).json({ error: 'You do not own this resource' });
      }

      const { error } = await supabase
        .from('discussion_resources')
        .delete()
        .eq('id', rId);

      if (error) throw error;
      res.status(204).send();
    } catch (error) {
      console.error('Delete discussion resource error:', error);
      res.status(500).json({ error: 'Failed to delete resource' });
    }
  });

  return router;
}

module.exports = createRouter;
