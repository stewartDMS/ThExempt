# Discussion Media Storage Structure

## Bucket: `discussion-media`

### Path Format

```
discussion-media/
└── {user_id}/
    ├── images/
    │   ├── {timestamp}_{original_filename}.jpg
    │   ├── {timestamp}_{original_filename}.png
    │   ├── {timestamp}_{original_filename}.gif
    │   └── {timestamp}_{original_filename}.webp
    ├── videos/
    │   ├── {timestamp}_{original_filename}.mp4
    │   ├── {timestamp}_{original_filename}.mov
    │   └── {timestamp}_{original_filename}.webm
    └── thumbnails/
        ├── {timestamp}_{original_filename}_thumb.jpg
        └── ...
```

### Example Paths

```
discussion-media/a1b2c3d4-e5f6-7890-abcd-ef1234567890/images/1710720000000_screenshot.png
discussion-media/a1b2c3d4-e5f6-7890-abcd-ef1234567890/videos/1710720100000_demo.mp4
discussion-media/a1b2c3d4-e5f6-7890-abcd-ef1234567890/thumbnails/1710720100000_demo_thumb.jpg
```

### File Naming Convention

- **Timestamp**: Unix milliseconds (e.g., `1710720000000`)
- **Original filename**: Sanitized, lowercase, spaces replaced with underscores
- **Thumbnail suffix**: `_thumb.jpg`

### File Size Limits

| Type   | Limit |
|--------|-------|
| Images | 10 MB |
| Videos | 100 MB |
| Per discussion | 5 files maximum |

### Supported Formats

- **Images**: JPEG, PNG, GIF, WebP
- **Videos**: MP4, MOV, WebM, AVI

### MIME Types

| Format | MIME Type |
|--------|-----------|
| JPEG | `image/jpeg` |
| PNG | `image/png` |
| GIF | `image/gif` |
| WebP | `image/webp` |
| MP4 | `video/mp4` |
| MOV | `video/quicktime` |
| WebM | `video/webm` |
| AVI | `video/x-msvideo` |

### Security

- Files are stored under `{user_id}/` prefix so storage RLS policies can enforce ownership
- Only authenticated users can upload
- Users can only delete/update their own files
- Public read access for all files (public bucket)
