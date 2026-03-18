'use client'

import { motion } from 'framer-motion'

const audiences = [
  {
    icon: '✊',
    title: 'ACTIVISTS',
    description: 'Done marching in circles. Ready to build systems that actually work.',
  },
  {
    icon: '🔧',
    title: 'BUILDERS',
    description: 'Coders, designers, lawyers, strategists — lending skills to causes that matter.',
  },
  {
    icon: '💡',
    title: 'VISIONARIES',
    description: 'People with ideas to fix broken systems and the drive to make them real.',
  },
  {
    icon: '💸',
    title: 'INVESTORS',
    description: 'Putting money behind solutions instead of waiting for the government to act.',
  },
]

export default function Audience() {
  return (
    <section className="bg-charcoal py-24">
      <div className="container mx-auto px-6">
        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-5xl font-black text-white text-center mb-4 uppercase"
        >
          NOT FOR EVERYONE.
        </motion.h2>
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="text-2xl text-white text-center mb-16"
        >
          FOR PEOPLE WHO GIVE A DAMN.
        </motion.p>

        <div className="grid md:grid-cols-4 gap-6">
          {audiences.map((audience, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: i * 0.1 }}
              className="bg-steelGray/30 p-8 rounded-lg"
            >
              <div className="text-3xl mb-4">{audience.icon}</div>
              <h3 className="text-xl font-bold text-white mb-3">{audience.title}</h3>
              <p className="text-white/70">{audience.description}</p>
            </motion.div>
          ))}
        </div>

        <motion.p
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.5 }}
          className="text-center text-rebellionOrange text-lg italic mt-12"
        >
          If you&apos;re waiting for permission, this isn&apos;t for you.
        </motion.p>
      </div>
    </section>
  )
}
