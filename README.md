# ThExempt

> **Where change happens. Everyday people make it happen.**

A movement-first platform where changemakers discuss broken systems, build real solutions, fund community projects, and earn wealth through meaningful contribution.

## 🌍 Vision

ThExempt is not just another crowdfunding platform. It's a social movement with financial tools that empower everyday people to:

- **Discuss** systemic problems and envision alternatives
- **Connect** with collaborators, mentors, and co-conspirators
- **Build** real projects that fix broken systems
- **Fund** community-centric solutions with membership credits
- **Earn** equity and skills through meaningful contributions

**Target Audience:** Fired-up changemakers aged 25-45 who are done waiting for institutions to fix what's broken.

---

## 🏗️ Repository Structure

```
ThExempt/
├── landing_page/        # Next.js landing page (marketing site)
├── flutter_app/         # Flutter app (main platform - discussions, projects, community)
├── server/              # Express backend (legacy - being replaced by Supabase)
├── supabase/            # Supabase backend (database, auth, edge functions)
└── database/            # Database migrations and schemas
```

---

## 🚀 Platform Architecture

### **Landing Page** (Next.js - Deployed on Vercel)
- Public-facing marketing site
- Explains the vision
- Drives signups
- **URL:** thexempt.com

### **Main App** (Flutter Web + Mobile)
- Authenticated user experience
- Discussions, projects, community features
- Investment & contribution flows
- **Tech:** Flutter + Supabase
- **URL:** app.thexempt.com

### **Backend** (Supabase)
- PostgreSQL database
- Row-level security (RLS)
- Realtime subscriptions
- Edge functions for webhooks (Stripe, equity platform)
- **Replacing:** Legacy Express server

---

## 🎯 Current Development Status

### ✅ Completed
- [x] Landing page (Next.js) deployed on Vercel
- [x] Flutter app authentication (Supabase)
- [x] Discussions system (categories, replies, likes)
- [x] Projects CRUD (create, read, update, delete)
- [x] User profiles
- [x] Basic UI components

### 🚧 In Progress
- [ ] Enhanced landing page with movement messaging
- [ ] Database schema for credits & investments
- [ ] Membership tiers (Free, Changemaker, Movement Builder, Founding Partner)
- [ ] Stripe integration for subscriptions
- [ ] Project verification system

### 📋 Roadmap

**Phase 1: Community Foundation** (4 weeks)
- Enhanced discussions (Problem → Solution → Project pipeline)
- Expert badges & trust system
- Resource library

**Phase 2: Movement Discovery** (3 weeks)
- Changemakers directory
- Skills marketplace
- Collaboration requests

**Phase 3: Financial Tools** (4 weeks)
- Membership tiers & Stripe
- Credits system
- Investment flow
- Equity tracking

**Phase 4: Skills Economy** (3 weeks)
- Skill offers/requests
- Contribution tracking
- Credit/equity rewards

Full roadmap: See `docs/ROADMAP.md`

---

## 💻 Tech Stack

### Landing Page
- **Next.js 15** - React framework
- **TypeScript** - Type safety
- **Tailwind CSS** - Styling
- **Framer Motion** - Animations
- **Vercel** - Hosting

### Main App
- **Flutter** - Cross-platform (Web, iOS, Android)
- **Dart** - Language
- **Supabase Flutter SDK** - Backend integration

### Backend
- **Supabase** - Backend-as-a-Service
  - PostgreSQL database
  - Authentication
  - Realtime
  - Storage
  - Edge Functions (Deno)

### Integrations
- **Stripe** - Payment processing & subscriptions
- **Equity Platform** (Republic.co or similar) - Legal equity management
- **SendGrid** - Transactional emails

---

## 🔧 Local Development

### Prerequisites
- Node.js 18+ (for landing page)
- Flutter 3.0+ (for main app)
- Supabase account

### Landing Page Setup

```bash
cd landing_page
npm install
npm run dev
# Open http://localhost:3000
```

### Flutter App Setup

```bash
cd flutter_app
flutter pub get
flutter run -d chrome
# Or: flutter run -d ios / flutter run -d android
```

### Environment Variables

Create `flutter_app/.env`:
```env
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-anon-key
```

---

## 🗄️ Database Schema

See [`supabase/schema.sql`](supabase/schema.sql) for the complete schema and
[`supabase/MIGRATION_GUIDE.md`](supabase/MIGRATION_GUIDE.md) for setup and
migration instructions.

**Tables covered:**
- `profiles` — User accounts, membership tiers, reputation, credits
- `discussions` — Community threads (problems, ideas, networking, …)
- `discussion_replies`, `discussion_likes`, `discussion_media` — Thread engagement
- `projects` — Fundable initiatives with milestones and team roles
- `project_media`, `project_milestones`, `project_roles`, `project_members` — Project details
- `project_updates`, `comments` — Project announcements and responses
- `live_events`, `event_rsvps`, `live_chat_messages`, `live_reactions` — Live events
- `skill_categories`, `skills`, `skill_offers`, `skill_requests` — Skills marketplace
- `follows`, `notifications` — Social graph and notifications
- `subscriptions`, `credit_transactions`, `investments` — Financial engine
- `contributions` — Work tracking and reward flow

---

## 🚀 Deployment

### Landing Page
Auto-deploys to Vercel on push to `main`:
```bash
git push origin main
```

### Flutter App
Coming soon: CI/CD for Flutter web deployment

---

## 📚 Documentation

- [Landing Page README](landing_page/README.md)
- [Flutter App README](flutter_app/README.md)
- [Product Roadmap](docs/ROADMAP.md) *(to be created)*
- [Database Schema](database/schema.sql) *(to be created)*

---

## 🤝 Contributing

This is a movement. Contributions welcome!

1. Fork the repo
2. Create a feature branch
3. Make your changes
4. Submit a Pull Request

---

## 📜 License

ISC

---

## 🌍 The Movement

**ThExempt is where everyday people change the world — and build wealth doing it.**

Not waiting for permission. Not asking for approval.
Just building the future we want to see.

Join us: [thexempt.com](https://thexempt.com)
