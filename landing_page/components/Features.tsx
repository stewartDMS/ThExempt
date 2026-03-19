'use client'

import { useRef } from 'react'
import { motion, useInView } from 'framer-motion'
import { Target, MessageCircle, BarChart3, Video, Lock, Rocket } from 'lucide-react'

interface Feature {
  icon: React.ReactNode
  title: string
  description: string
  gradient: string
  iconBg: string
  borderHover: string
}

const features: Feature[] = [
  {
    icon: <Target size={24} />,
    title: 'Smart Matching',
    description: 'Our AI-powered algorithm connects you with collaborators who complement your skills and share your vision.',
    gradient: 'from-electricBlue to-brightCyan',
    iconBg: 'bg-electricBlue/15 text-electricBlue',
    borderHover: 'hover:border-electricBlue/50',
  },
  {
    icon: <MessageCircle size={24} />,
    title: 'Real-time Chat',
    description: 'Stay in sync with your team through instant messaging, threads, and integrated project discussions.',
    gradient: 'from-forestGreen to-brightCyan',
    iconBg: 'bg-forestGreen/15 text-forestGreen',
    borderHover: 'hover:border-forestGreen/50',
  },
  {
    icon: <BarChart3 size={24} />,
    title: 'Track Progress',
    description: 'Powerful project analytics and milestone tracking to keep everyone aligned and moving forward.',
    gradient: 'from-brightCyan to-electricBlue',
    iconBg: 'bg-brightCyan/15 text-brightCyan',
    borderHover: 'hover:border-brightCyan/50',
  },
  {
    icon: <Video size={24} />,
    title: 'Video Pitches',
    description: 'Record and share video pitches to attract the right collaborators who believe in your idea.',
    gradient: 'from-deepRed to-rebellionOrange',
    iconBg: 'bg-deepRed/15 text-deepRed',
    borderHover: 'hover:border-deepRed/50',
  },
  {
    icon: <Lock size={24} />,
    title: 'Secure Platform',
    description: 'End-to-end encryption and robust privacy controls ensure your ideas and IP stay protected.',
    gradient: 'from-steelGray to-charcoal',
    iconBg: 'bg-steelGray/30 text-white/70',
    borderHover: 'hover:border-steelGray/50',
  },
  {
    icon: <Rocket size={24} />,
    title: 'Launch Support',
    description: 'Expert mentors and resources guide you from idea validation all the way to your first launch.',
    gradient: 'from-rebellionOrange to-warmAmber',
    iconBg: 'bg-rebellionOrange/15 text-rebellionOrange',
    borderHover: 'hover:border-rebellionOrange/50',
  },
]

const containerVariants = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.1, delayChildren: 0.1 },
  },
}

const cardVariants = {
  hidden: { opacity: 0, y: 40 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: [0.25, 0.46, 0.45, 0.94] } },
}

export default function Features() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: '-80px' })

  return (
    <section id="features" className="py-24 bg-charcoal">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <span className="inline-block px-4 py-1.5 mb-4 text-sm font-semibold text-electricBlue bg-electricBlue/10 rounded-full border border-electricBlue/30">
            Everything You Need
          </span>
          <h2 className="text-4xl sm:text-5xl font-bold text-white mb-4">
            Built for{' '}
            <span className="bg-gradient-to-r from-electricBlue to-brightCyan bg-clip-text text-transparent">
              Ambitious Builders
            </span>
          </h2>
          <p className="text-xl text-white/60 max-w-2xl mx-auto">
            Every tool you need to go from idea to shipped product, with the right team by your side.
          </p>
        </motion.div>

        {/* Feature cards grid */}
        <motion.div
          ref={ref}
          variants={containerVariants}
          initial="hidden"
          animate={isInView ? 'visible' : 'hidden'}
          className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6"
        >
          {features.map((feature) => (
            <motion.div
              key={feature.title}
              variants={cardVariants}
              whileHover={{ y: -6, rotateX: 2, rotateY: 2 }}
              transition={{ type: 'spring', stiffness: 300, damping: 20 }}
              className={`group relative p-6 rounded-2xl bg-white/5 border border-steelGray/30 ${feature.borderHover} hover:shadow-xl hover:shadow-black/30 transition-all duration-300 cursor-default`}
              style={{ transformStyle: 'preserve-3d' }}
            >
              {/* Gradient overlay on hover */}
              <div className={`absolute inset-0 rounded-2xl bg-gradient-to-br ${feature.gradient} opacity-0 group-hover:opacity-[0.06] transition-opacity duration-300`} />

              {/* Icon */}
              <div className={`inline-flex items-center justify-center w-12 h-12 rounded-xl ${feature.iconBg} mb-5 transition-transform duration-300 group-hover:scale-110`}>
                {feature.icon}
              </div>

              {/* Content */}
              <h3 className="text-lg font-bold text-white mb-2">
                {feature.title}
              </h3>
              <p className="text-white/60 text-sm leading-relaxed">
                {feature.description}
              </p>

              {/* Arrow indicator */}
              <div className="mt-4 flex items-center text-sm font-medium text-white/30 group-hover:text-electricBlue transition-colors duration-300">
                <span>Learn more</span>
                <svg className="ml-1 w-4 h-4 group-hover:translate-x-1 transition-transform duration-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  )
}
