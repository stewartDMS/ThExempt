-- ============================================
-- DISCUSSION MEDIA - SAMPLE QUERIES
-- ============================================

-- 1. Get discussion with all media
SELECT * FROM discussions_with_media
WHERE id = 'your-discussion-uuid-here';

-- 2. Get all discussions that have images
SELECT DISTINCT d.*
FROM discussions d
JOIN discussion_media dm ON d.id = dm.discussion_id
WHERE dm.media_type = 'image'
ORDER BY d.created_at DESC;

-- 3. Get all discussions that have videos
SELECT DISTINCT d.*
FROM discussions d
JOIN discussion_media dm ON d.id = dm.discussion_id
WHERE dm.media_type = 'video'
ORDER BY d.created_at DESC;

-- 4. Get user's uploaded media
SELECT * FROM user_media_uploads
WHERE uploader_name = 'Stewart'
ORDER BY uploaded_at DESC;

-- 5. Get current user's uploaded media (RLS-aware)
SELECT dm.*, d.title AS discussion_title
FROM discussion_media dm
JOIN discussions d ON dm.discussion_id = d.id
WHERE dm.uploaded_by = auth.uid()
ORDER BY dm.uploaded_at DESC;

-- 6. Get discussion media stats
SELECT * FROM discussion_media_stats
ORDER BY total_media DESC;

-- 7. Search discussions with media
SELECT * FROM discussions_with_media
WHERE media != '[]'::json
AND (
    title ILIKE '%search_term%'
    OR content ILIKE '%search_term%'
)
ORDER BY created_at DESC;

-- 8. Get discussions with most media
SELECT
    d.id,
    d.title,
    d.media_count
FROM discussions d
WHERE d.media_count > 0
ORDER BY d.media_count DESC, d.created_at DESC
LIMIT 10;

-- 9. Get total storage used by user
SELECT
    uploaded_by,
    p.name,
    COUNT(*) AS file_count,
    SUM(file_size) AS total_bytes,
    ROUND(SUM(file_size) / 1024.0 / 1024.0, 2) AS total_mb
FROM discussion_media dm
JOIN profiles p ON dm.uploaded_by = p.id
GROUP BY uploaded_by, p.name
ORDER BY total_bytes DESC;

-- 10. Get recent media uploads (last 7 days)
SELECT
    dm.*,
    d.title AS discussion_title,
    p.name AS uploader_name
FROM discussion_media dm
JOIN discussions d ON dm.discussion_id = d.id
JOIN profiles p ON dm.uploaded_by = p.id
WHERE dm.uploaded_at >= NOW() - INTERVAL '7 days'
ORDER BY dm.uploaded_at DESC;

-- 11. Validate before upload (usage example)
SELECT validate_media_upload(
    'discussion-uuid'::uuid,
    'image',
    5242880 -- 5MB in bytes
);

-- 12. Reorder media (usage example)
SELECT reorder_media(
    ARRAY[
        'media-uuid-1'::uuid,
        'media-uuid-2'::uuid,
        'media-uuid-3'::uuid
    ],
    'discussion-uuid'::uuid
);
