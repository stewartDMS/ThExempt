'use client'

import { useRef } from 'react'
import { motion, useInView } from 'framer-motion'

interface StatItem {
  value: string
  label: string
}

const stats: StatItem[] = [
  { value: '$2,543,290', label: 'INVESTED IN CHANGE' },
  { value: '10,234', label: 'CHANGEMAKERS BUILDING' },
  { value: '234', label: 'PROJECTS FUNDED' },
  { value: '87,432', label: 'HOURS CONTRIBUTED' },
  { value: '45 CITIES', label: 'ORGANIZING LOCALLY' },
  { value: '1,203', label: 'SYSTEMS REBUILT' },
]

export default function Stats() {
  const sectionRef = useRef(null)
  const isInView = useInView(sectionRef, { once: true, margin: '-100px' })

  return (
    <section
      ref={sectionRef}
      className="relative py-20 overflow-hidden bg-deepRed"
    >
      {/* Subtle dot pattern */}
      <div className="absolute inset-0 opacity-10 pointer-events-none">
        <div className="absolute inset-0" style={{
          backgroundImage: 'radial-gradient(circle at 1px 1px, white 1px, transparent 0)',
          backgroundSize: '40px 40px',
        }} />
      </div>

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-8">
          {stats.map((stat, index) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 30 }}
              animate={isInView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: index * 0.1, ease: 'easeOut' }}
              className="text-center text-white"
            >
              <div className="text-3xl sm:text-4xl font-black tracking-tight mb-2 drop-shadow-sm">
                {stat.value}
              </div>
              <div className="text-xs font-bold opacity-80 uppercase tracking-widest">{stat.label}</div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
