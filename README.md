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
- [x] **Phase 1 — Enhanced discussion categories** (Democracy, Climate, Economic, Education, Healthcare, Justice, Community, Technology)
- [x] **Phase 1 — "Turn this into a project" button** on discussion threads (pre-fills project form from discussion)
- [x] **Phase 1 — Seed discussions** (5–10 sample discussions per systemic-change category in `supabase/seed.sql`)
- [x] **Phase 1 — Problem → Solution → Project pipeline UI** (stage stepper, community voting, stage advancement for authors)
- [x] **Phase 1 — Resource Library** (attach links, documents, videos, images, datasets to any discussion; filter by type)
- [x] **Phase 1 — Expert Badges & Trust System** (declare expertise, community endorsements, earned badges, trust scores)
- [x] **Phase 1 — Enhanced category browsing** (filter between All / Systemic-Change / General categories; per-category stage filter)

### 🚧 In Progress
- [ ] Enhanced landing page with movement messaging
- [ ] Database schema for credits & investments
- [ ] Membership tiers (Free, Changemaker, Movement Builder, Founding Partner)
- [ ] Stripe integration for subscriptions
- [ ] Project verification system

### 📋 Roadmap

#### **Phase 1: Community Foundation** (4 weeks) ✅ *Complete*

**Goal:** Build the conversation layer

| Feature | Status |
|---------|--------|
| Discussions system | ✅ Done |
| Enhanced categories (systemic-change focused) | ✅ Done — 18 categories, filter by systemic/general |
| Problem → Solution → Project pipeline UI | ✅ Done — stage stepper, voting, author stage advancement |
| Resource Library in discussions | ✅ Done — attach links, docs, videos, images, datasets |
| Expert Badges & Trust System | ✅ Done — expertise declaration, community endorsements, badges |
| Seed discussions (5–10 per category) | ✅ Done |

**New systemic-change categories available:**
`democracy` · `climate_crisis` · `economic_inequality` · `healthcare_access` · `education_reform` · `housing_justice` · `criminal_justice` · `immigration_justice` · `mental_health_crisis` · `community_building` · `technology`

**Phase 1 — Key User Flows:**

1. **Category Browsing** → Filter categories by "Systemic Change" vs "General" → browse discussions per category → filter by pipeline stage (Problem / Solution / Proposal / Project)

2. **Pipeline Progression** → In a discussion's "Pipeline" tab, view the stage stepper, cast upvote/downvote, and (as the author) advance the discussion from Problem → Solution → Project Proposal → Create Project

3. **Resource Library** → In a discussion's "Resources" tab, view attached resources filtered by type, and add your own links, documents, videos, images, or datasets

4. **Expert Profile** → Tap the shield icon in the Community hub, declare your expertise areas (e.g., "Climate Policy", "Healthcare Access"), earn badges based on trust score, and endorse other users' expertise

#### **Phase 2: Movement Discovery** (3 weeks)
- Changemakers directory
- Skills marketplace
- Map view of community
- User profiles (impact-focused)
- Collaboration requests

#### **Phase 3: Project Foundation** (4 weeks)
- Enhanced project pages (problem/solution/impact)
- Community endorsements
- Progress tracking
- Link projects ↔ discussions

#### **Phase 4: Financial Tools** (4 weeks)
- Membership tiers & Stripe
- Credits system
- Investment flow
- Contribution tracking
- Equity tracking

#### **Phase 5: Skills Economy** (3 weeks)
- Skill offers/requests
- Contribution proposals
- Time tracking
- Credit/equity rewards
- Portfolio building

#### **Phase 6: Learning & Growth** (2 weeks)
- Learning content library
- Skill paths
- Templates & guides
- Webinar system

#### **Phase 7: Impact & Gamification** (2 weeks)
- Impact dashboard
- Badges & achievements
- Leaderboards (impact, not just $)
- Monthly impact reports
- Social sharing

#### **Phase 8: Polish & Launch** (3 weeks)
- Mobile responsive
- Legal pages
- Onboarding flow
- Email system
- Beta testing
- Soft launch

**Total: ~6 months** to full launch

---

## 🌱 Quick Wins (Month 1 — Phase 1)

1. ✅ Enhanced discussions with systemic-change categories
2. ✅ "Turn this into a project" button on all discussion threads
3. ✅ Seed script for 5–10 sample discussions per category
4. 🔜 Recruit 3–5 experts per category

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
