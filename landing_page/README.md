# ThExempt Landing Page

> The platform for ambitious young people to discover purpose, build skills, and contribute to real business ideas.

## Getting Started

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to view the landing page.

## Tech Stack

| Tool | Purpose |
|------|---------|
| **Next.js 15** | React framework with App Router |
| **TypeScript** | Type-safe code |
| **Tailwind CSS** | Utility-first styling |
| **Framer Motion** | Animations & transitions |
| **Lucide React** | Icon library |

## Project Structure

```
landing_page/
├── app/
│   ├── globals.css       # Global styles, CSS variables, animations
│   ├── layout.tsx        # Root layout with SEO metadata
│   └── page.tsx          # Main page (composes all sections)
├── components/
│   ├── Navbar.tsx        # Sticky nav with hide-on-scroll + mobile menu
│   ├── Hero.tsx          # Animated hero with floating blobs
│   ├── Stats.tsx         # Animated counters (10K+, 5K+, 50K+)
│   ├── Features.tsx      # 6 feature cards with hover tilt
│   ├── HowItWorks.tsx    # 3-step process with connecting line
│   ├── LiveProjects.tsx  # Mock project cards (TODO: API)
│   ├── Testimonials.tsx  # Auto-rotating testimonial carousel
│   ├── CTA.tsx           # Animated gradient CTA section
│   └── Footer.tsx        # 4-column footer + newsletter
└── lib/
    └── utils.ts          # cn() helper + formatCount()
```

## Deployment

Deploy instantly on [Vercel](https://vercel.com):

```bash
npx vercel
```

Or connect your GitHub repo to Vercel for automatic deployments on every push.

## Customization

- **Colors**: Update `tailwind.config.ts` → `theme.extend.colors`
- **Content**: Edit component files directly — all copy is hardcoded and easy to find
- **API data**: Search for `// TODO: Replace with real API data` in `LiveProjects.tsx`
