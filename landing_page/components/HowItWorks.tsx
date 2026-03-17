'use client'

import { motion, useInView } from 'framer-motion'
import { useRef } from 'react'
import { UserCircle, Search, Zap } from 'lucide-react'

const steps = [
  {
    number: '01',
    icon: <UserCircle size={28} />,
    title: 'Create Profile',
    description:
      'Tell us about your skills, passions, and goals. Build a profile that showcases what you bring to the table.',
    gradient: 'from-blue-500 to-blue-700',
    color: 'blue',
  },
  {
    number: '02',
    icon: <Search size={28} />,
    title: 'Discover Projects',
    description:
      'Browse curated opportunities that match your expertise and ambitions. Find the ideas that excite you most.',
    gradient: 'from-purple-500 to-purple-700',
    color: 'purple',
  },
  {
    number: '03',
    icon: <Zap size={28} />,
    title: 'Build Together',
    description:
      'Start collaborating with your team, hit milestones, and ship something you are genuinely proud of.',
    gradient: 'from-pink-500 to-rose-600',
    color: 'pink',
  },
]

export default function HowItWorks() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: '-80px' })

  return (
    <section id="how-it-works" className="py-24 bg-gray-50 dark:bg-gray-900/50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <span className="inline-block px-4 py-1.5 mb-4 text-sm font-semibold text-blue-700 dark:text-blue-300 bg-blue-100 dark:bg-blue-950/50 rounded-full border border-blue-200 dark:border-blue-800/50">
            Simple Process
          </span>
          <h2 className="text-4xl sm:text-5xl font-bold text-gray-900 dark:text-white mb-4">
            From Zero to{' '}
            <span className="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
              Shipped
            </span>{' '}
            in 3 Steps
          </h2>
          <p className="text-xl text-gray-500 dark:text-gray-400 max-w-2xl mx-auto">
            Getting started is easy. Find your people, align on a vision, and start building.
          </p>
        </motion.div>

        {/* Steps */}
        <div ref={ref} className="relative">
          {/* Connecting dotted line (desktop) */}
          <div className="hidden lg:block absolute top-16 left-[calc(16.67%+2rem)] right-[calc(16.67%+2rem)] h-px">
            <div className="w-full h-full border-t-2 border-dashed border-gray-300 dark:border-gray-700" />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-12 lg:gap-8">
            {steps.map((step, index) => {
              const direction = index % 2 === 0 ? -1 : 1
              return (
                <motion.div
                  key={step.title}
                  initial={{ opacity: 0, x: direction * 40 }}
                  animate={isInView ? { opacity: 1, x: 0 } : {}}
                  transition={{ duration: 0.7, delay: index * 0.2, ease: 'easeOut' }}
                  className="relative flex flex-col items-center text-center group"
                >
                  {/* Number badge */}
                  <div className="relative mb-6">
                    <div
                      className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${step.gradient} flex items-center justify-center text-white shadow-lg group-hover:shadow-xl group-hover:-translate-y-1 transition-all duration-300`}
                    >
                      {step.icon}
                    </div>
                    <span
                      className={`absolute -top-2 -right-2 w-7 h-7 rounded-full bg-gradient-to-br ${step.gradient} flex items-center justify-center text-xs font-bold text-white shadow-md ring-2 ring-white dark:ring-gray-950`}
                    >
                      {index + 1}
                    </span>
                  </div>

                  {/* Content */}
                  <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-3">
                    {step.title}
                  </h3>
                  <p className="text-gray-500 dark:text-gray-400 leading-relaxed">
                    {step.description}
                  </p>
                </motion.div>
              )
            })}
          </div>
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
            className="inline-flex items-center gap-2 px-8 py-4 text-lg font-semibold text-white rounded-xl bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 hover:from-blue-600 hover:via-purple-600 hover:to-pink-600 shadow-xl shadow-blue-500/25 hover:shadow-2xl hover:shadow-purple-500/30 transition-all duration-300 hover:-translate-y-0.5"
          >
            Start Building Today
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
            </svg>
          </a>
        </motion.div>
      </div>
    </section>
  )
}
