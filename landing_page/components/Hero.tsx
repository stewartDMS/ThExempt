'use client'

import { motion } from 'framer-motion'
import { ArrowRight, Play, ChevronDown } from 'lucide-react'

const floatingOrbs = [
  { color: 'from-blue-400/30 to-blue-600/30', size: 'w-72 h-72', top: '10%', left: '5%', delay: 0 },
  { color: 'from-purple-400/30 to-purple-600/30', size: 'w-96 h-96', top: '20%', right: '5%', delay: 1 },
  { color: 'from-pink-400/20 to-accent/20', size: 'w-64 h-64', bottom: '20%', left: '15%', delay: 2 },
  { color: 'from-cyan-400/20 to-blue-500/20', size: 'w-48 h-48', bottom: '30%', right: '20%', delay: 0.5 },
]

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
    <section className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden bg-gradient-to-br from-slate-50 via-blue-50/50 to-purple-50/50 dark:from-gray-950 dark:via-blue-950/20 dark:to-purple-950/20">
      {/* Animated background blobs */}
      {floatingOrbs.map((orb, i) => (
        <motion.div
          key={i}
          className={`absolute ${orb.size} rounded-full bg-gradient-to-br ${orb.color} blur-3xl pointer-events-none`}
          style={{
            top: orb.top,
            left: orb.left,
            right: (orb as { right?: string }).right,
            bottom: (orb as { bottom?: string }).bottom,
          }}
          animate={{
            y: [0, -20, 0],
            x: [0, 10, 0],
            scale: [1, 1.05, 1],
          }}
          transition={{
            duration: 6 + orb.delay,
            repeat: Infinity,
            ease: 'easeInOut',
            delay: orb.delay,
          }}
        />
      ))}

      {/* Grid pattern overlay */}
      <div className="absolute inset-0 bg-[url('/grid.svg')] bg-center opacity-[0.02] dark:opacity-[0.05] pointer-events-none" />

      {/* Main content */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="relative z-10 text-center px-4 sm:px-6 lg:px-8 max-w-5xl mx-auto pt-24 pb-16"
      >
        {/* Badge */}
        <motion.div variants={itemVariants} className="flex justify-center mb-6">
          <span className="inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium bg-blue-100 dark:bg-blue-950/60 text-blue-700 dark:text-blue-300 border border-blue-200 dark:border-blue-800/50">
            <span className="w-2 h-2 rounded-full bg-blue-500 animate-pulse" />
            For ambitious builders under 30
          </span>
        </motion.div>

        {/* Headline */}
        <motion.h1
          variants={itemVariants}
          className="text-5xl sm:text-6xl md:text-7xl font-extrabold tracking-tight leading-[1.1] mb-6"
        >
          <span className="text-gray-900 dark:text-white">Build Your </span>
          <br />
          <span className="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent bg-size-200% animate-gradient-shift">
            Next Big Idea
          </span>
          <br />
          <span className="text-gray-900 dark:text-white">Together</span>
        </motion.h1>

        {/* Subheadline */}
        <motion.p
          variants={itemVariants}
          className="text-xl sm:text-2xl text-gray-500 dark:text-gray-400 max-w-3xl mx-auto mb-10 leading-relaxed"
        >
          Connect with talented collaborators, share your vision, and build something extraordinary together.
          Discover purpose. Build skills. Ship real products.
        </motion.p>

        {/* CTA buttons */}
        <motion.div
          variants={itemVariants}
          className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-16"
        >
          <motion.a
            href="#get-started"
            whileHover={{ scale: 1.04, y: -2 }}
            whileTap={{ scale: 0.97 }}
            className="group inline-flex items-center gap-2 px-8 py-4 text-lg font-semibold text-white rounded-xl bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 hover:from-blue-600 hover:via-purple-600 hover:to-pink-600 shadow-xl shadow-blue-500/25 hover:shadow-2xl hover:shadow-purple-500/30 transition-all duration-300"
          >
            Get Started Free
            <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
          </motion.a>

          <motion.a
            href="#demo"
            whileHover={{ scale: 1.04, y: -2 }}
            whileTap={{ scale: 0.97 }}
            className="group inline-flex items-center gap-3 px-8 py-4 text-lg font-semibold text-gray-700 dark:text-gray-200 rounded-xl border-2 border-gray-200 dark:border-gray-700 hover:border-purple-400 dark:hover:border-purple-500 hover:bg-purple-50 dark:hover:bg-purple-950/30 transition-all duration-300"
          >
            <span className="w-9 h-9 flex items-center justify-center rounded-full bg-gradient-to-br from-blue-500 to-purple-500 shadow-md group-hover:shadow-lg transition-shadow">
              <Play size={14} className="text-white ml-0.5" />
            </span>
            Watch Demo
          </motion.a>
        </motion.div>

        {/* Social proof */}
        <motion.div
          variants={itemVariants}
          className="flex flex-col sm:flex-row items-center justify-center gap-6 text-sm text-gray-500 dark:text-gray-400"
        >
          <div className="flex -space-x-2">
            {['A', 'S', 'J', 'M', 'R'].map((initial, i) => (
              <div
                key={i}
                className="w-8 h-8 rounded-full border-2 border-white dark:border-gray-900 flex items-center justify-center text-xs font-bold text-white"
                style={{
                  background: `hsl(${i * 50 + 200}, 70%, 55%)`,
                  zIndex: 5 - i,
                }}
              >
                {initial}
              </div>
            ))}
          </div>
          <span>
            <strong className="text-gray-900 dark:text-white">5,000+</strong> creators already building
          </span>
          <span className="hidden sm:block w-px h-4 bg-gray-300 dark:bg-gray-700" />
          <span className="flex items-center gap-1">
            {'⭐'.repeat(5)}{' '}
            <strong className="text-gray-900 dark:text-white">4.9</strong> / 5 rating
          </span>
        </motion.div>
      </motion.div>

      {/* Scroll indicator */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.5, duration: 0.8 }}
        className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 text-gray-400 dark:text-gray-600"
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
