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
- [x] **Phase 2 — Changemakers directory** (browse by skill / availability / location)
- [x] **Phase 2 — Skills marketplace** (offer and request skills)
- [x] **Phase 2 — Community map** (location-based changemaker view)
- [x] **Phase 2 — Collaboration request workflow** (connect / join_project)
- [x] **Phase 3 — Structured project fields** (Problem Statement, Solution Approach, Impact Metrics — stored in DB, displayed in project Overview tab)
- [x] **Phase 3 — Community endorsements** (endorse/un-endorse any project; optional message; live count in Quick Stats)
- [x] **Phase 3 — Progress tracking** (DB-backed milestones with due dates; owner can add, complete, delete; progress update posts with type labels)
- [x] **Phase 3 — Project ↔ Discussion linking** (Discussions tab on project shows spawned + explicitly linked discussions; `project_discussion_links` M:M table)

### 🚧 In Progress
- [ ] Enhanced landing page with movement messaging
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

#### **Phase 2: Movement Discovery** (3 weeks) ✅ *Complete*

**Goal:** Connect changemakers and enable collaboration

| Feature | Status |
|---------|--------|
| Changemakers directory (discover & filter users) | ✅ Done — skill/availability/location filters, reputation sort |
| Skills marketplace (offers & requests) | ✅ Done — post skill offers, browse open skill requests |
| Community map / location view | ✅ Done — groups changemakers by location, search by city |
| User profiles with impact/activity focus | ✅ Done — impact stats, badges, project count, connect button |
| Collaboration request workflow | ✅ Done — send/accept/decline/withdraw requests |

**Phase 2 — New DB Objects:**

- `collaboration_requests` table — sender, recipient, optional project, type (`connect` | `join_project`), status pipeline (`pending → accepted | declined | withdrawn`), RLS policies
- `skill_offers` & `skill_requests` — RLS policies added (tables existed in base schema)

**Phase 2 — New API Methods:**

| Service | Method | Description |
|---------|--------|-------------|
| `ChangemakersService` | `getChangemakers(skillFilter, availabilityFilter, locationFilter, sort)` | Paginated user directory |
| `ChangemakersService` | `getUsersBySkills(skills)` | Find users by skill overlap |
| `ChangemakersService` | `getChangemakersWithLocation()` | All users with location (for map) |
| `ChangemakersService` | `getUserImpactStats(userId)` | Projects, discussions, badges counts |
| `CollaborationService` | `sendRequest(recipientId, requestType, projectId?, message?)` | Send collab request |
| `CollaborationService` | `acceptRequest(requestId)` | Accept incoming request |
| `CollaborationService` | `declineRequest(requestId)` | Decline incoming request |
| `CollaborationService` | `withdrawRequest(requestId)` | Withdraw sent request |
| `CollaborationService` | `getIncomingRequests()` | List pending incoming requests |
| `CollaborationService` | `getOutgoingRequests()` | List sent requests |
| `CollaborationService` | `getRequestStatus(otherUserId, projectId?)` | Check existing request status |
| `SkillsService` | `getSkillOffers(skillCategory?)` | Browse active skill offers |
| `SkillsService` | `createSkillOffer(title, description, skillCategories, ...)` | Post a skill offer |
| `SkillsService` | `getSkillRequests(skillCategory?)` | Browse open skill requests |
| `SkillsService` | `createSkillRequest(title, description, skillCategories, ...)` | Post a skill request |

**Phase 2 — New Screens:**

| Screen | File | Description |
|--------|------|-------------|
| Discover (tabbed) | `screens/feed/discovery_screen.dart` | 4 tabs: Projects · Changemakers · Skills · Map |
| Changemakers | `screens/discovery/changemakers_screen.dart` | Directory with skill/availability filter |
| Skills Marketplace | `screens/discovery/skills_marketplace_screen.dart` | Skill Offers & Requests tabs |
| Community Map | `screens/discovery/community_map_screen.dart` | Location-grouped view |

**Phase 2 — Key User Flows:**

1. **Discover Changemakers** → Open the "Discover" tab → tap "Changemakers" → search by skill (e.g., "Climate Policy") → filter by "Available" / "Open to Collab" → tap a card to view their profile → press "Connect" to send a collaboration request

2. **Skills Marketplace** → Discover tab → "Skills" → browse "Skill Offers" (people advertising their availability) or "Skill Requests" (projects seeking skills) → contact poster via their profile

3. **Community Map** → Discover tab → "Map" → see changemakers grouped by city → tap an avatar to view their profile

4. **Collaboration Request** → View any user profile → press "Connect" (app bar action) → request is sent → recipient sees it in their Notifications or can check via `CollaborationService.getIncomingRequests()`

#### **Phase 3: Project Foundation** (4 weeks) ✅ *Complete*
- Enhanced project pages with structured **Problem Statement**, **Solution Approach**, and **Impact Metrics** fields  
- **Community Endorsements** — any authenticated user can endorse a project with an optional message; cached `endorsements_count` shown in Quick Stats
- **Progress Tracking** — real DB-backed milestones (add, mark complete, delete); project owners can post progress updates with type labels (milestone/funding/team/media/general)
- **Bi-directional Project ↔ Discussion Linking** — Discussions tab on each project shows spawned discussions (via `linked_project_id`) plus explicitly linked discussions; `project_discussion_links` table provides the M:M join

**Phase 3 — New DB Objects:**
- `project_endorsements` table + `endorsements_count` column on `projects` + trigger to keep it in sync
- `project_discussion_links` table for explicit M:M project↔discussion relationships
- RLS policies for both new tables (public select, authenticated insert own, delete own)
- DB migration: `supabase/migrations/007_phase3_project_foundation.sql`

**Phase 3 — New Flutter Models:**
| File | Purpose |
|------|---------|
| `lib/models/project_endorsement_model.dart` | `ProjectEndorsement` — single endorsement row |
| `lib/models/project_update_model.dart` | `ProjectUpdate` + `ProjectUpdateType` enum |

**Phase 3 — New API Methods (`ProjectsService`):**
| Method | Description |
|--------|-------------|
| `getEndorsements(projectId)` | List all endorsements for a project |
| `hasUserEndorsed(projectId)` | Check if current user has already endorsed |
| `endorseProject(projectId, message?)` | Create endorsement row |
| `unendorseProject(projectId)` | Delete own endorsement |
| `getProjectUpdates(projectId)` | List progress updates |
| `addProjectUpdate(projectId, title, content, type)` | Post a new update |
| `deleteProjectUpdate(updateId)` | Soft-delete an update |
| `getLinkedDiscussions(projectId)` | Fetch all discussions linked to a project |
| `linkDiscussion(projectId, discussionId, linkType)` | Create explicit link |
| `unlinkDiscussion(projectId, discussionId)` | Remove link |
| `getProjectMilestones(projectId)` | Fetch real milestones from DB |
| `addMilestone(projectId, title, description?, dueDate?)` | Create milestone |
| `completeMilestone(milestoneId)` | Mark complete |
| `reopenMilestone(milestoneId)` | Reopen completed milestone |
| `deleteMilestone(milestoneId)` | Remove milestone |
| `createProject(…, problemStatement?, solutionApproach?, impactMetrics?)` | Extended to accept Phase 3 fields |
| `updateProject(…, problemStatement?, solutionApproach?, impactMetrics?)` | Extended to accept Phase 3 fields |

**Phase 3 — New Screens / Tabs:**
| File | Purpose |
|------|---------|
| `widgets/project_endorsements_tab.dart` | Endorsement count, toggle button, list of endorsers |
| `widgets/project_updates_tab.dart` | Progress update feed; owners can post new updates |
| `widgets/project_linked_discussions_tab.dart` | Discussions linked to this project |

**Phase 3 — Key User Flows:**

1. **Endorse a project** → Project Detail → "Endorsements" tab → tap "Endorse this project" → optionally add a message → endorsement is recorded and count increments immediately

2. **Post a progress update** (owner) → Project Detail → "Updates" tab → FAB "Post Update" → choose type (milestone/funding/team/media/general) → enter title & content → update appears in feed

3. **View linked discussions** → Project Detail → "Discussions" tab → see all discussions that were the source of or are related to this project

4. **Add a milestone** (owner) → Project Detail → "Milestones" tab → FAB "Add Milestone" → enter title, description, optional due date → milestone appears in DB-backed timeline; tap ⋮ to mark complete or delete

5. **Create project with structured fields** → "Create Project" form now includes optional "Problem Statement" and "Solution Approach" text fields → displayed as dedicated cards in the Overview tab

**Phase 3 — `DiscussionsService` additions:**
| Method | Description |
|--------|-------------|
| `getDiscussionsForProject(projectId)` | Fetch discussions with `linked_project_id = projectId` |
| `linkDiscussionToProject(discussionId, projectId)` | Set `linked_project_id` and advance stage to `project_linked` |

#### **Phase 4: Financial Tools** (4 weeks) ✅ *Complete*
- **Membership Tiers** — Free, Supporter ($9.99/mo), Changemaker ($24.99/mo) tiers seeded in DB; `MembershipScreen` shows current plan and upgrade CTAs (Stripe pending)
- **Credits System** — `credit_balances` + `credit_transactions` tables; `WalletScreen` shows balance and full transaction history with type icons
- **Investment Flow** — users can invest credits in any project; `project_investments` table with per-user upsert; `projects.total_invested` / `investor_count` kept in sync by DB trigger
- **Contribution Tracking** — any authenticated user can record credits/skills/time/other contributions via the new "Contributors" tab
- **Equity Tracking** — project owners can grant equity percentages to contributors; "Equity" tab shows distribution with total percentage guard

**Phase 4 — New DB Tables (migration 008):**
- `membership_tiers` — plan catalogue (name, slug, pricing, features, badge color)
- `user_memberships` — one active membership per user; status in (`active`, `cancelled`, `expired`)
- `credit_balances` — running credit total per user (balance ≥ 0)
- `credit_transactions` — immutable ledger of all credit events (earn/spend/purchase/refund/invest/receive_investment)
- `project_investments` — one investment record per (project, user); triggers sync `projects.total_invested` + `investor_count`
- `project_contributions` — many contribution records per project (credits/skills/time/other)
- `project_equity` — unique equity grant per (project, user); percentage validated 0.01–100

**Phase 4 — New Flutter Models:**
`MembershipTier`, `UserMembership`, `CreditBalance`, `CreditTransaction`, `ProjectInvestment`, `ProjectContribution`, `ProjectEquity`

**Phase 4 — New Service (`FinancialService`):**
| Method | Description |
|--------|-------------|
| `getMembershipTiers()` | All active tiers ordered by sort_order |
| `getUserMembership(userId)` | Active membership with tier join |
| `getCreditBalance(userId)` | User's current credit balance |
| `getCreditTransactions(userId)` | Last 50 transactions desc |
| `getProjectInvestments(projectId)` | All investors with profile join |
| `getUserInvestment(projectId)` | Current user's own investment |
| `investInProject(projectId, amount)` | Upsert investment (idempotent) |
| `getProjectContributions(projectId)` | All contributions with profile join |
| `addContribution(projectId, type, desc)` | Insert new contribution |
| `getProjectEquity(projectId)` | All equity grants with profile join |

**Phase 4 — New Screens / Tabs:**
| Screen | Path | Notes |
|--------|------|-------|
| `WalletScreen` | `screens/wallet/wallet_screen.dart` | Balance card + transaction history |
| `MembershipScreen` | `screens/membership/membership_screen.dart` | Tier cards with upgrade CTAs |
| `ProjectInvestmentTab` | `screens/projects/widgets/project_investment_tab.dart` | Stats + invest dialog |
| `ProjectContributorsTab` | `screens/projects/widgets/project_contributors_tab.dart` | Contribution list + add dialog |
| `ProjectEquityTab` | `screens/projects/widgets/project_equity_tab.dart` | Equity distribution + grant dialog |

**Phase 4 — Key User Flows:**

1. **Check wallet** → Profile → "My Wallet" → see credit balance and full transaction history; tap "Buy Credits" → Stripe coming soon SnackBar

2. **Upgrade membership** → Profile → "Membership" → browse Free/Supporter/Changemaker plans → tap "Upgrade" → Stripe coming soon SnackBar

3. **Invest in a project** → Project Detail → "Invest" tab → tap "Invest Credits" → enter amount (1–999) + optional message → credits are upserted; stats update immediately

4. **Log a contribution** → Project Detail → "Contributors" tab → tap "Add Contribution" → pick type (credits/skills/time/other), enter description and optional amount

5. **Grant equity** (project owner) → Project Detail → "Equity" tab → tap "Grant Equity" → enter recipient user ID, percentage, and description; total equity guard warns if would exceed 100%

> **Note:** Stripe payment integration is scaffolded. All payment buttons show "Stripe integration coming soon" until production keys are configured.


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
