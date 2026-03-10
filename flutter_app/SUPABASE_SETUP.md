# Supabase Setup Guide

This Flutter app uses [Supabase](https://supabase.com) directly for authentication, database access, and file storage — no custom backend server required.

## Prerequisites

1. A Supabase project (create one at [supabase.com](https://supabase.com))
2. Flutter SDK installed

## Environment Variables

The app requires two environment variables:

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL (e.g. `https://xxxx.supabase.co`) |
| `SUPABASE_ANON_KEY` | Your Supabase project's anonymous/public key |

Find these in your Supabase project under **Settings → API**.

## Running Locally

Pass the variables via `--dart-define` flags:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
```

## Building for Production

### Web
```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
```

### Android
```bash
flutter build apk \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
```

### iOS
```bash
flutter build ios \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
```

## Cloud Deployment

When deploying to cloud hosting (Firebase Hosting, Netlify, Vercel, etc.), set the `--dart-define` values at build time in your CI/CD pipeline.

### Example GitHub Actions workflow
```yaml
- name: Build Flutter Web
  run: |
    flutter build web \
      --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
      --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
```

Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` as secrets in your GitHub repository settings.

## Required Supabase Database Tables

Ensure the following tables exist in your Supabase project (run the SQL schema from the project root):

- `profiles` — user profiles (id, name, email, bio, avatar_url, …)
- `projects` — projects (id, owner_id, title, description, required_skills, …)
- `project_roles` — roles within projects
- `project_members` — accepted team members
- `role_applications` — applications for project roles
- `applications` — general project applications
- `discussions` — community discussion threads
- `discussion_replies` — replies to discussions
- `discussion_likes` — likes on discussions
- `discussion_reply_likes` — likes on replies
- `live_events` — scheduled and live events
- `event_rsvps` — RSVPs for events
- `event_chat_messages` — chat during live events
- `event_reactions` — emoji reactions during live events
- `skill_categories` — skill taxonomy (name, parent_category, icon, description)

## Required Supabase Storage Buckets

- `avatars` — user profile pictures (public)
- `project-videos` — project demo videos (public)
- `project-thumbnails` — video thumbnails (public)

## Row Level Security (RLS)

Enable RLS on all tables and add appropriate policies. Example policies:

```sql
-- Users can read all profiles
CREATE POLICY "Profiles are publicly readable"
  ON profiles FOR SELECT USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);
```

Refer to the [Supabase RLS documentation](https://supabase.com/docs/guides/auth/row-level-security) for more details.
