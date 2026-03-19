'use client'

import { motion } from 'framer-motion'
import { ArrowRight, CheckCircle } from 'lucide-react'

const shapes = [
  { size: 'w-32 h-32', top: '10%', left: '5%', delay: 0, rotate: 12 },
  { size: 'w-20 h-20', top: '60%', left: '8%', delay: 1, rotate: -15 },
  { size: 'w-24 h-24', top: '15%', right: '8%', delay: 0.5, rotate: 20 },
  { size: 'w-40 h-40', bottom: '10%', right: '5%', delay: 1.5, rotate: -8 },
  { size: 'w-16 h-16', top: '45%', right: '15%', delay: 2, rotate: 30 },
]

export default function CTA() {
  return (
    <section className="relative py-28 overflow-hidden">
      {/* Animated gradient background */}
      <div className="absolute inset-0 bg-gradient-to-br from-deepRed via-charcoal to-electricBlue bg-size-200% animate-gradient-shift" />

      {/* Overlay for depth */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent" />

      {/* Floating shapes */}
      {shapes.map((shape, i) => (
        <motion.div
          key={i}
          className={`absolute ${shape.size} rounded-2xl border-2 border-white/10 bg-white/5`}
          style={{
            top: shape.top,
            left: (shape as { left?: string }).left,
            right: (shape as { right?: string }).right,
            bottom: (shape as { bottom?: string }).bottom,
            rotate: shape.rotate,
          }}
          animate={{
            y: [0, -15, 0],
            rotate: [shape.rotate, shape.rotate + 5, shape.rotate],
            opacity: [0.4, 0.7, 0.4],
          }}
          transition={{
            duration: 5 + shape.delay,
            repeat: Infinity,
            ease: 'easeInOut',
            delay: shape.delay,
          }}
        />
      ))}

      {/* Content */}
      <div className="relative z-10 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7 }}
        >
          {/* Badge */}
          <span className="inline-flex items-center gap-2 px-4 py-2 mb-8 rounded-full text-sm font-medium bg-white/20 text-white border border-white/30 backdrop-blur-sm">
            <span className="w-2 h-2 rounded-full bg-white animate-pulse" />
            Join 5,000+ builders already on the platform
          </span>

          {/* Headline */}
          <h2 className="text-4xl sm:text-5xl md:text-6xl font-extrabold text-white mb-6 leading-tight">
            Ready to Build
            <br />
            Something Great?
          </h2>

          {/* Subtext */}
          <p className="text-xl text-white/80 mb-10 max-w-2xl mx-auto leading-relaxed">
            Join thousands of creators building the next generation of startups.
            Your idea, your team, your future — starts here.
          </p>

          {/* CTA button */}
          <motion.a
            href="#get-started"
            whileHover={{ scale: 1.05, y: -3 }}
            whileTap={{ scale: 0.97 }}
            className="group inline-flex items-center gap-2 px-10 py-5 text-lg font-bold text-charcoal bg-white rounded-2xl shadow-2xl hover:shadow-white/30 transition-all duration-300"
          >
            Start Your Project
            <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
          </motion.a>

          {/* Trust badges */}
          <div className="mt-8 flex flex-col sm:flex-row items-center justify-center gap-4 sm:gap-8 text-white/70 text-sm">
            <span className="flex items-center gap-2">
              <CheckCircle size={16} className="text-white/90" />
              Free Forever
            </span>
            <span className="hidden sm:block w-1 h-1 rounded-full bg-white/40" />
            <span className="flex items-center gap-2">
              <CheckCircle size={16} className="text-white/90" />
              No Credit Card Required
            </span>
            <span className="hidden sm:block w-1 h-1 rounded-full bg-white/40" />
            <span className="flex items-center gap-2">
              <CheckCircle size={16} className="text-white/90" />
              Cancel Anytime
            </span>
          </div>
        </motion.div>
      </div>
    </section>
  )
}
