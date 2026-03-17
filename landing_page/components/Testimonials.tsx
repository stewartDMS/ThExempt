'use client'

import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronLeft, ChevronRight, Star } from 'lucide-react'

interface Testimonial {
  name: string
  title: string
  company: string
  quote: string
  initials: string
  color: string
}

const testimonials: Testimonial[] = [
  {
    name: 'Alex M.',
    title: 'Founder',
    company: 'BuildLab',
    quote:
      'ThExempt completely changed how I find collaborators for my startup ideas. Within two weeks I had a full team and we were shipping our first feature. The quality of people here is unreal.',
    initials: 'AM',
    color: 'from-blue-500 to-blue-700',
  },
  {
    name: 'Sarah K.',
    title: 'CEO',
    company: 'Mento',
    quote:
      "Found my co-founder here. We've been building for 6 months and just raised our seed round! I genuinely don't think we'd be where we are without ThExempt connecting us at exactly the right time.",
    initials: 'SK',
    color: 'from-purple-500 to-purple-700',
  },
  {
    name: 'James T.',
    title: 'Product Designer',
    company: 'Sprintly',
    quote:
      "The best platform for ambitious builders. Period. I've tried every collaboration tool out there and nothing comes close. The community, the tools, the support — it's all world-class.",
    initials: 'JT',
    color: 'from-pink-500 to-rose-600',
  },
]

export default function Testimonials() {
  const [current, setCurrent] = useState(0)
  const [direction, setDirection] = useState(1)

  useEffect(() => {
    const timer = setInterval(() => {
      setDirection(1)
      setCurrent((prev) => (prev + 1) % testimonials.length)
    }, 5000)
    return () => clearInterval(timer)
  }, [])

  const go = (index: number) => {
    setDirection(index > current ? 1 : -1)
    setCurrent(index)
  }

  const prev = () => {
    setDirection(-1)
    setCurrent((c) => (c - 1 + testimonials.length) % testimonials.length)
  }

  const next = () => {
    setDirection(1)
    setCurrent((c) => (c + 1) % testimonials.length)
  }

  const slideVariants = {
    enter: (d: number) => ({ opacity: 0, x: d > 0 ? 60 : -60 }),
    center: { opacity: 1, x: 0, transition: { duration: 0.5, ease: 'easeOut' } },
    exit: (d: number) => ({ opacity: 0, x: d > 0 ? -60 : 60, transition: { duration: 0.3, ease: 'easeIn' } }),
  }

  return (
    <section className="py-24 bg-gray-50 dark:bg-gray-900/50 overflow-hidden">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <span className="inline-block px-4 py-1.5 mb-4 text-sm font-semibold text-pink-700 dark:text-pink-300 bg-pink-100 dark:bg-pink-950/50 rounded-full border border-pink-200 dark:border-pink-800/50">
            Stories
          </span>
          <h2 className="text-4xl sm:text-5xl font-bold text-gray-900 dark:text-white mb-4">
            Builders Love{' '}
            <span className="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
              ThExempt
            </span>
          </h2>
          <p className="text-xl text-gray-500 dark:text-gray-400 max-w-xl mx-auto">
            Real stories from real builders shipping real things
          </p>
        </motion.div>

        {/* Carousel */}
        <div className="relative">
          <AnimatePresence custom={direction} mode="wait">
            <motion.div
              key={current}
              custom={direction}
              variants={slideVariants}
              initial="enter"
              animate="center"
              exit="exit"
              className="bg-white dark:bg-gray-900 rounded-3xl p-8 sm:p-12 shadow-xl shadow-gray-200/60 dark:shadow-gray-900/60 border border-gray-100 dark:border-gray-800"
            >
              {/* Stars */}
              <div className="flex gap-1 mb-6">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} size={18} className="text-amber-400 fill-amber-400" />
                ))}
              </div>

              {/* Quote */}
              <blockquote className="text-xl sm:text-2xl font-medium text-gray-800 dark:text-gray-100 leading-relaxed mb-8">
                &ldquo;{testimonials[current].quote}&rdquo;
              </blockquote>

              {/* Author */}
              <div className="flex items-center gap-4">
                <div
                  className={`w-14 h-14 rounded-2xl bg-gradient-to-br ${testimonials[current].color} flex items-center justify-center text-white font-bold text-lg shadow-md`}
                >
                  {testimonials[current].initials}
                </div>
                <div>
                  <div className="font-bold text-gray-900 dark:text-white text-lg">
                    {testimonials[current].name}
                  </div>
                  <div className="text-gray-500 dark:text-gray-400 text-sm">
                    {testimonials[current].title} at {testimonials[current].company}
                  </div>
                </div>
              </div>
            </motion.div>
          </AnimatePresence>

          {/* Navigation buttons */}
          <button
            onClick={prev}
            className="absolute left-0 top-1/2 -translate-y-1/2 -translate-x-5 sm:-translate-x-6 w-10 h-10 sm:w-12 sm:h-12 rounded-full bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 shadow-md hover:shadow-lg flex items-center justify-center text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-all duration-200 hover:-translate-x-6 sm:hover:-translate-x-7"
            aria-label="Previous testimonial"
          >
            <ChevronLeft size={18} />
          </button>
          <button
            onClick={next}
            className="absolute right-0 top-1/2 -translate-y-1/2 translate-x-5 sm:translate-x-6 w-10 h-10 sm:w-12 sm:h-12 rounded-full bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 shadow-md hover:shadow-lg flex items-center justify-center text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-all duration-200 hover:translate-x-6 sm:hover:translate-x-7"
            aria-label="Next testimonial"
          >
            <ChevronRight size={18} />
          </button>
        </div>

        {/* Dots */}
        <div className="flex justify-center gap-2 mt-8">
          {testimonials.map((_, i) => (
            <button
              key={i}
              onClick={() => go(i)}
              className={`w-2.5 h-2.5 rounded-full transition-all duration-300 ${
                i === current
                  ? 'w-8 bg-gradient-to-r from-blue-500 to-purple-500'
                  : 'bg-gray-300 dark:bg-gray-700 hover:bg-gray-400 dark:hover:bg-gray-600'
              }`}
              aria-label={`Go to testimonial ${i + 1}`}
            />
          ))}
        </div>
      </div>
    </section>
  )
}
