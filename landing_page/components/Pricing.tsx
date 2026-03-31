'use client'

import { motion, useInView } from 'framer-motion'
import { useRef } from 'react'
import { cn } from '@/lib/utils'
import { SIGN_UP_URL } from '@/lib/app-links'

const tiers = [
  {
    emoji: '🌱',
    name: 'Free Contributor',
    price: '$0',
    period: null,
    credits: '0 credits',
    tagline: 'Join the conversation. See what\'s possible.',
    highlight: false,
    badge: null,
    gradient: 'from-steelGray to-steelGray/60',
    borderClass: 'border-steelGray/30',
    ctaClass: 'bg-white/10 text-white hover:bg-white/20 border border-white/20',
    features: [
      'Browse all project discussions',
      'Follow projects you care about',
      'Join community conversations',
      'View platform activity & impact',
      'Access public resources',
    ],
  },
  {
    emoji: '💪',
    name: 'Changemaker',
    price: '$19',
    period: '/mo',
    credits: '20 credits/mo',
    tagline: 'Back projects. Build skills. Start changing systems.',
    highlight: true,
    badge: 'Most Popular',
    gradient: 'from-electricBlue to-brightCyan',
    borderClass: 'border-electricBlue/60',
    ctaClass: 'bg-electricBlue text-white hover:bg-electricBlue/90 shadow-lg shadow-electricBlue/30',
    features: [
      'Everything in Free',
      '20 credits to invest monthly',
      'Back projects & earn equity',
      'Access skill-building workshops',
      'Member-only community access',
      'Track your portfolio impact',
    ],
  },
  {
    emoji: '🚀',
    name: 'Movement Builder',
    price: '$49',
    period: '/mo',
    credits: '55 credits/mo',
    tagline: 'Lead projects. Mentor others. Build wealth while building change.',
    highlight: false,
    badge: null,
    gradient: 'from-rebellionOrange to-warmAmber',
    borderClass: 'border-rebellionOrange/40',
    ctaClass: 'bg-rebellionOrange text-white hover:bg-rebellionOrange/90 shadow-lg shadow-rebellionOrange/20',
    features: [
      'Everything in Changemaker',
      '55 credits to invest monthly',
      'Launch & lead your own projects',
      'Mentor other changemakers',
      'Priority project visibility',
      'Advanced analytics dashboard',
      'Early access to new features',
    ],
  },
  {
    emoji: '🌟',
    name: 'Founding Partner',
    price: '$149',
    period: '/mo',
    credits: '200 credits/mo',
    tagline: 'Shape the platform. Fund the movement. Maximum impact.',
    highlight: false,
    badge: 'Max Impact',
    gradient: 'from-deepRed to-rebellionOrange',
    borderClass: 'border-deepRed/50',
    ctaClass: 'bg-deepRed text-white hover:bg-deepRed/90 shadow-lg shadow-deepRed/20',
    features: [
      'Everything in Movement Builder',
      '200 credits to invest monthly',
      'Shape platform roadmap & policy',
      'Founding Partner recognition',
      'Direct access to core team',
      'Founding equity allocation',
      'Invitation-only strategy sessions',
      'Maximum investment exposure',
    ],
  },
]

export default function Pricing() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: '-80px' })

  return (
    <section id="pricing" className="py-24 bg-charcoal/95">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl sm:text-5xl font-black text-white mb-4 uppercase">
            Choose Your Level of Change
          </h2>
          <p className="text-xl text-white/60 max-w-2xl mx-auto">
            Every tier is a commitment — to the platform, the movement, and the future we&apos;re building together.
          </p>
        </motion.div>

        {/* Cards */}
        <div ref={ref} className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 items-stretch">
          {tiers.map((tier, index) => (
            <motion.div
              key={tier.name}
              initial={{ opacity: 0, y: 40 }}
              animate={isInView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: index * 0.12, ease: 'easeOut' }}
              className={cn(
                'relative flex flex-col rounded-2xl border bg-white/5 backdrop-blur-sm p-6 transition-transform duration-300 hover:-translate-y-1',
                tier.borderClass,
                tier.highlight && 'ring-2 ring-electricBlue shadow-xl shadow-electricBlue/10'
              )}
            >
              {/* Badge */}
              {tier.badge && (
                <span
                  className={`absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1 rounded-full text-xs font-black uppercase tracking-widest text-white bg-gradient-to-r ${tier.gradient} shadow-md`}
                >
                  {tier.badge}
                </span>
              )}

              {/* Icon + Name + Price */}
              <div className="mb-6">
                <div
                  className={`w-14 h-14 rounded-2xl bg-gradient-to-br ${tier.gradient} flex items-center justify-center text-2xl shadow-md mb-4`}
                >
                  {tier.emoji}
                </div>
                <h3 className="text-lg font-black text-white uppercase tracking-wide mb-1">
                  {tier.name}
                </h3>
                <div className="flex items-end gap-1 mb-1">
                  <span className="text-4xl font-black text-white">{tier.price}</span>
                  {tier.period && (
                    <span className="text-white/50 font-medium pb-1">{tier.period}</span>
                  )}
                </div>
                <p className="text-sm font-semibold text-white/40 uppercase tracking-widest">
                  {tier.credits}
                </p>
              </div>

              {/* Tagline */}
              <p className="text-white/70 text-sm leading-relaxed mb-6 border-t border-white/10 pt-5">
                {tier.tagline}
              </p>

              {/* Feature list */}
              <ul className="flex-1 space-y-2 mb-8">
                {tier.features.map((feature) => (
                  <li key={feature} className="flex items-start gap-2 text-sm text-white/60">
                    <span className="mt-0.5 text-white/30">✓</span>
                    {feature}
                  </li>
                ))}
              </ul>

              {/* CTA */}
              <a
                href={SIGN_UP_URL}
                className={`block w-full py-3 rounded-lg text-sm font-bold text-center transition-all duration-200 ${tier.ctaClass}`}
              >
                {tier.price === '$0' ? 'Get Started Free' : 'Join Now'}
              </a>
            </motion.div>
          ))}
        </div>

        {/* Footer note */}
        <motion.p
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.5 }}
          className="text-center text-white/30 text-sm mt-10"
        >
          All paid plans include a 30-day money-back guarantee. No contracts. Cancel anytime.
        </motion.p>
      </div>
    </section>
  )
}
