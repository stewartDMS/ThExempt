'use client'

import { motion } from 'framer-motion'
import { ChevronDown } from 'lucide-react'

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.2, delayChildren: 0.1 },
  },
}

const itemVariants = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.7, ease: [0.25, 0.46, 0.45, 0.94] } },
}

export default function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center bg-gradient-to-br from-charcoal via-steelGray to-deepRed overflow-hidden">

      {/* Main content — pt clears the fixed navbar (h-16 mobile / h-20 desktop) */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="relative z-10 text-center px-6 max-w-5xl mx-auto pt-20 md:pt-24"
      >
        <motion.h1
          variants={itemVariants}
          className="text-3xl sm:text-4xl md:text-5xl font-black text-white mb-4 tracking-tight leading-tight uppercase"
        >
          WHERE CHANGE HAPPENS.
        </motion.h1>

        <motion.h2
          variants={itemVariants}
          className="text-2xl sm:text-3xl md:text-4xl font-black text-white mb-8 leading-tight uppercase"
        >
          EVERYDAY PEOPLE MAKE IT HAPPEN.
        </motion.h2>

        <motion.p
          variants={itemVariants}
          className="text-xl md:text-2xl text-white/90 mb-12 max-w-3xl mx-auto font-medium"
        >
          Politics is broken — it doesn&apos;t serve the people.
          <br />
          Around the world, ordinary people are building the change we need.
        </motion.p>

        <motion.div
          variants={itemVariants}
          className="flex flex-col sm:flex-row gap-4 justify-center"
        >
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.97 }}
            className="bg-white text-charcoal text-lg font-bold px-8 py-4 rounded-lg shadow-xl transition-transform"
          >
            JOIN THE MOVEMENT
          </motion.button>
          <motion.button
            whileHover={{ backgroundColor: 'rgba(255,255,255,0.1)' }}
            whileTap={{ scale: 0.97 }}
            className="border-2 border-white text-white text-lg font-bold px-8 py-4 rounded-lg transition-colors"
          >
            SEE PROJECTS IN ACTION
          </motion.button>
        </motion.div>

        <motion.div
          variants={itemVariants}
          className="mt-16 grid grid-cols-2 sm:grid-cols-3 gap-6 max-w-3xl mx-auto"
        >
          {[
            { value: '$2,543,290', label: 'INVESTED IN CHANGE' },
            { value: '10,234', label: 'CHANGEMAKERS BUILDING' },
            { value: '234', label: 'PROJECTS FUNDED' },
            { value: '87,432', label: 'HOURS CONTRIBUTED' },
            { value: '45 CITIES', label: 'ORGANIZING LOCALLY' },
            { value: '1,203', label: 'SYSTEMS REBUILT' },
          ].map((stat) => (
            <div key={stat.label} className="text-center">
              <div className="text-2xl sm:text-3xl font-black text-white tracking-tight">{stat.value}</div>
              <div className="text-xs font-bold text-white/50 tracking-widest uppercase mt-1">{stat.label}</div>
            </div>
          ))}
        </motion.div>
      </motion.div>

      {/* Scroll indicator */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.5, duration: 0.8 }}
        className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 text-white/50"
      >
        <span className="text-xs font-medium tracking-widest uppercase">Scroll</span>
        <motion.div
          animate={{ y: [0, 8, 0] }}
          transition={{ duration: 1.5, repeat: Infinity, ease: 'easeInOut' }}
        >
          <ChevronDown size={20} />
        </motion.div>
      </motion.div>
    </section>
  )
}
