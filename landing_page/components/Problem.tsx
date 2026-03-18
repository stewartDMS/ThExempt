'use client'

import { motion } from 'framer-motion'

const problems = [
  {
    icon: '🏛️',
    title: "GOVERNANCE ISN'T WORKING",
    stat: 'Politicians serve donors, not people',
    description: '78% of Americans trust government "not much"',
  },
  {
    icon: '💰',
    title: 'THE ECONOMY WORKS FOR THE FEW',
    stat: 'Top 1% own 32% of wealth',
    description: 'Meanwhile you work 2 jobs to afford rent',
  },
  {
    icon: '🌍',
    title: 'SYSTEMS ARE FAILING US',
    stat: 'Climate, healthcare, housing, education',
    description: 'All broken. All fixable. If we do it together.',
  },
]

export default function Problem() {
  return (
    <section className="bg-charcoal py-24">
      <div className="container mx-auto px-6">
        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-5xl font-black text-white text-center mb-16 uppercase"
        >
          TIRED OF WAITING?
        </motion.h2>

        <div className="grid md:grid-cols-3 gap-8">
          {problems.map((problem, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: i * 0.15 }}
              className="bg-steelGray/50 p-8 rounded-lg border border-deepRed/30"
            >
              <div className="text-4xl mb-4">{problem.icon}</div>
              <h3 className="text-2xl font-bold text-white mb-3">{problem.title}</h3>
              <p className="text-white/70 text-lg mb-2">{problem.stat}</p>
              <p className="text-white/60">{problem.description}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
