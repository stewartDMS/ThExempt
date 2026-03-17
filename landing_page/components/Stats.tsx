'use client'

import { useEffect, useRef } from 'react'
import { motion, useInView, useMotionValue, useSpring } from 'framer-motion'

interface StatItem {
  value: number
  suffix: string
  label: string
  description: string
}

const stats: StatItem[] = [
  {
    value: 10000,
    suffix: '+',
    label: 'Projects Created',
    description: 'Real ideas turned into reality',
  },
  {
    value: 5000,
    suffix: '+',
    label: 'Creators',
    description: 'Ambitious builders worldwide',
  },
  {
    value: 50000,
    suffix: '+',
    label: 'Connections Made',
    description: 'Collaborations that shipped',
  },
]

function AnimatedCounter({ value, suffix }: { value: number; suffix: string }) {
  const ref = useRef<HTMLSpanElement>(null)
  const motionValue = useMotionValue(0)
  const springValue = useSpring(motionValue, { duration: 2000, bounce: 0 })
  const isInView = useInView(ref, { once: true, margin: '-50px' })

  useEffect(() => {
    if (isInView) {
      motionValue.set(value)
    }
  }, [isInView, motionValue, value])

  useEffect(() => {
    const unsubscribe = springValue.on('change', (latest) => {
      if (ref.current) {
        const formatted =
          latest >= 1000
            ? `${(latest / 1000).toFixed(latest >= 10000 ? 0 : 1)}K`
            : Math.round(latest).toString()
        ref.current.textContent = formatted + suffix
      }
    })
    return unsubscribe
  }, [springValue, suffix, value])

  const display =
    value >= 1000
      ? `${(value / 1000).toFixed(value >= 10000 ? 0 : 1)}K`
      : value.toString()

  return (
    <span ref={ref} className="tabular-nums">
      {display}
      {suffix}
    </span>
  )
}

export default function Stats() {
  const sectionRef = useRef(null)
  const isInView = useInView(sectionRef, { once: true, margin: '-100px' })

  return (
    <section
      ref={sectionRef}
      className="relative py-20 overflow-hidden bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600"
    >
      {/* Subtle pattern overlay */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute inset-0" style={{
          backgroundImage: 'radial-gradient(circle at 1px 1px, white 1px, transparent 0)',
          backgroundSize: '40px 40px',
        }} />
      </div>

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 md:gap-4">
          {stats.map((stat, index) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 30 }}
              animate={isInView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: index * 0.15, ease: 'easeOut' }}
              className="text-center text-white group"
            >
              <div className="inline-flex flex-col items-center">
                <div className="text-5xl sm:text-6xl font-extrabold tracking-tight mb-2 drop-shadow-sm">
                  <AnimatedCounter value={stat.value} suffix={stat.suffix} />
                </div>
                <div className="text-xl font-semibold mb-1 opacity-95">{stat.label}</div>
                <div className="text-sm font-medium opacity-70">{stat.description}</div>
              </div>

              {/* Divider (hidden on last) */}
              {index < stats.length - 1 && (
                <div className="hidden md:block absolute right-0 top-1/2 -translate-y-1/2 w-px h-16 bg-white/20" />
              )}
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
