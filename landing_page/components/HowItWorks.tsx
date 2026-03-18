'use client'

import { motion, useInView } from 'framer-motion'
import { useRef } from 'react'

const steps = [
  {
    number: '1',
    icon: '💬',
    title: "DISCUSS WHAT'S BROKEN",
    description: "Join conversations about the systems that aren't working. Bring research, lived experience, expertise.",
    example: "→ See: 'Why housing is unaffordable' (234 replies, 12 experts)",
    gradient: 'from-electricBlue to-brightCyan',
  },
  {
    number: '2',
    icon: '💡',
    title: 'BUILD REAL SOLUTIONS',
    description: "Turn discussions into projects. Community-owned. Transparent. Actually solving the problem.",
    example: "→ Project: 'Community Land Trust' — Making housing affordable forever",
    gradient: 'from-rebellionOrange to-warmAmber',
  },
  {
    number: '3',
    icon: '💰',
    title: 'FUND WHAT MATTERS',
    description: 'Back projects with your membership. Earn equity as they succeed. Build wealth while fixing systems.',
    example: '→ $19/mo = 20 credits to invest. Already backed 234 projects',
    gradient: 'from-forestGreen to-brightCyan',
  },
  {
    number: '4',
    icon: '🤝',
    title: 'CONTRIBUTE YOUR SKILLS',
    description: "Offer what you're good at. Build your portfolio. Get paid in credits and equity.",
    example: '→ Legal help, design, code, strategy. Earn while you learn',
    gradient: 'from-deepRed to-rebellionOrange',
  },
]

export default function HowItWorks() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: '-80px' })

  return (
    <section id="how-it-works" className="py-24 bg-charcoal">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl sm:text-5xl font-black text-white mb-4 uppercase">
            How It Works
          </h2>
          <p className="text-xl text-white/60 max-w-2xl mx-auto">
            Four steps from frustrated to funded — and actually making change.
          </p>
        </motion.div>

        {/* Steps */}
        <div ref={ref} className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          {steps.map((step, index) => (
            <motion.div
              key={step.title}
              initial={{ opacity: 0, y: 40 }}
              animate={isInView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.7, delay: index * 0.15, ease: 'easeOut' }}
              className="relative flex flex-col items-center text-center group"
            >
              {/* Number + icon */}
              <div className={`w-20 h-20 rounded-2xl bg-gradient-to-br ${step.gradient} flex items-center justify-center text-3xl shadow-lg mb-6 group-hover:-translate-y-1 transition-transform duration-300`}>
                {step.icon}
              </div>
              <span className="absolute top-0 right-[calc(50%-2.5rem)] w-7 h-7 rounded-full bg-steelGray flex items-center justify-center text-xs font-black text-white ring-2 ring-charcoal">
                {step.number}
              </span>

              <h3 className="text-lg font-black text-white mb-3 uppercase">
                {step.title}
              </h3>
              <p className="text-white/60 leading-relaxed mb-4">
                {step.description}
              </p>
              <p className="text-white/40 text-sm italic">
                {step.example}
              </p>
            </motion.div>
          ))}
        </div>

        {/* Bottom CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.4 }}
          className="mt-16 text-center"
        >
          <a
            href="#get-started"
            className="inline-flex items-center gap-2 px-8 py-4 text-lg font-bold text-charcoal rounded-lg bg-white hover:bg-white/90 shadow-xl hover:-translate-y-0.5 transition-all duration-300"
          >
            Start Making Change
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
            </svg>
          </a>
        </motion.div>
      </div>
    </section>
  )
}
