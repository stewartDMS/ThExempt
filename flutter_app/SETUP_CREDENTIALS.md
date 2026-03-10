# Setting Up Supabase Credentials

This guide explains how to configure Supabase credentials for local development.

## Quick Start (Recommended)

### 1. Copy the example file

```bash
cp .env.example .env
```

### 2. Edit `.env` with your credentials

Open `.env` and replace the placeholder values:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### 3. Find your credentials

Go to your [Supabase project dashboard](https://supabase.com/dashboard):

1. Select your project
2. Go to **Settings → API**
3. Copy **Project URL** → paste as `SUPABASE_URL`
4. Copy **anon public** key → paste as `SUPABASE_ANON_KEY`

### 4. Run the app

```bash
flutter run -d chrome
```

No extra flags needed — credentials are loaded from `.env` automatically!

---

## Alternative: `--dart-define` Flags

If you prefer not to use a `.env` file, you can still pass credentials at run time:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
```

The app checks the `.env` file first and falls back to `--dart-define` values when the file is absent or the key is missing.

---

## CI/CD

For CI/CD pipelines, use `--dart-define` with secrets stored in your pipeline environment:

```yaml
# GitHub Actions example
- name: Build Flutter Web
  run: |
    flutter build web \
      --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
      --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
```

Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` as secrets in **GitHub → Settings → Secrets and variables → Actions**.

---

## Security Notes

- `.env` is listed in `.gitignore` and will **never** be committed to the repository.
- `.env.example` is committed and contains only placeholder values — it is safe to share.
- The `SUPABASE_ANON_KEY` is a public key and is safe to use in a frontend application.
