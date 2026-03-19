# ThExempt Landing Page

> **Where change happens. Everyday people make it happen.**

Public-facing marketing site for ThExempt — a movement-first platform for changemakers.

## 🎨 Design System

### Colors (Bold & Purposeful)

- **Deep Red** `#D32F2F` - Urgent action, passion
- **Charcoal** `#212121` - Strength, seriousness
- **Electric Blue** `#1976D2` - Innovation, intelligence
- **Rebellion Orange** `#FF6F00` - Energy, disruption
- **Forest Green** `#2E7D32` - Growth, sustainability
- **Steel Gray** `#455A64` - Industrial, serious
- **Bright Cyan** `#00BCD4` - Progress, tech
- **Warm Amber** `#FFA000` - Optimism, warning

### Typography

- **Headers:** Ultra-bold sans-serif (Inter Black)
- **Body:** Inter Regular/Medium
- **Stats:** Roboto Mono (monospaced)

### Tone

- **Urgent** but not nihilistic
- **Confrontational** but inclusive
- **Hopeful** but realistic
- **Bold** not corporate

---

## 🚀 Getting Started

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

---

## 📁 Component Structure

```
components/
├── Hero.tsx            # Full-viewport hero with bold movement messaging
├── Problem.tsx         # 3-column "systems are broken" section (NEW)
├── HowItWorks.tsx      # 4-step changemaker journey
├── Features.tsx        # Platform feature highlights
├── LiveProjects.tsx    # Featured projects with impact metrics
├── Audience.tsx        # "Who this is for" section (NEW)
├── Stats.tsx           # Big impact numbers
├── Testimonials.tsx    # Real changemaker stories
├── CTA.tsx             # Final urgent call-to-action
└── Footer.tsx          # Minimal, utilitarian
```

---

## 🎯 Target Audience

- **Age:** 25-45
- **Mindset:** Frustrated with status quo, ready for action
- **Not:** Passive observers, corporate types, slacktivists
- **Energy:** Urgent, determined, rebellious but constructive

---

## 🚀 Deployment

Auto-deploys to Vercel on push to `main`.

**Manual deploy:**
```bash
npx vercel --prod
```

---

## 🎨 Customization

- **Colors:** `tailwind.config.ts`
- **Content:** Component files (all copy is hardcoded)
- **Animations:** Framer Motion in each component
