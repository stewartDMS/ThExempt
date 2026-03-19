'use client'

import { motion } from 'framer-motion'
import { Users, ArrowRight, Layers } from 'lucide-react'

interface Project {
  name: string
  description: string
  skills: string[]
  teamSize: number
  stage: string
  stageColor: string
  gradient: string
}

// TODO: Replace with real API data
const mockProjects: Project[] = [
  {
    name: 'EcoTrack',
    description:
      'A mobile app that gamifies sustainable living by tracking your carbon footprint and rewarding eco-friendly choices.',
    skills: ['React Native', 'Node.js', 'UX Design'],
    teamSize: 3,
    stage: 'MVP',
    stageColor: 'bg-forestGreen/20 text-forestGreen',
    gradient: 'from-forestGreen/20 to-brightCyan/20',
  },
  {
    name: 'MentorLoop',
    description:
      'Platform connecting first-gen college students with industry professionals for personalized career mentorship.',
    skills: ['Next.js', 'Python', 'Product Strategy'],
    teamSize: 4,
    stage: 'Beta',
    stageColor: 'bg-electricBlue/20 text-electricBlue',
    gradient: 'from-electricBlue/20 to-brightCyan/20',
  },
  {
    name: 'SkillForge',
    description:
      'AI-powered platform that creates personalized learning paths for aspiring entrepreneurs based on their goals.',
    skills: ['TypeScript', 'AI/ML', 'Content Strategy'],
    teamSize: 2,
    stage: 'Idea',
    stageColor: 'bg-brightCyan/20 text-brightCyan',
    gradient: 'from-brightCyan/20 to-electricBlue/20',
  },
]

export default function LiveProjects() {
  return (
    <section className="py-24 bg-charcoal/95">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <span className="inline-block px-4 py-1.5 mb-4 text-sm font-semibold text-forestGreen bg-forestGreen/10 rounded-full border border-forestGreen/30">
            Live Projects
          </span>
          <h2 className="text-4xl sm:text-5xl font-bold text-white mb-4">
            See What&apos;s{' '}
            <span className="bg-gradient-to-r from-electricBlue to-brightCyan bg-clip-text text-transparent">
              Being Built
            </span>
          </h2>
          <p className="text-xl text-white/60 max-w-2xl mx-auto">
            Real projects by real creators, shipping every day
          </p>
        </motion.div>

        {/* Project cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-12">
          {mockProjects.map((project, index) => (
            <motion.div
              key={project.name}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.15 }}
              whileHover={{ y: -6 }}
              className="group relative p-6 rounded-2xl bg-white/5 border border-steelGray/30 hover:border-steelGray/60 hover:shadow-xl hover:shadow-black/30 transition-all duration-300 cursor-pointer"
            >
              {/* Gradient background */}
              <div
                className={`absolute inset-0 rounded-2xl bg-gradient-to-br ${project.gradient} opacity-0 group-hover:opacity-100 transition-opacity duration-300`}
              />

              <div className="relative z-10">
                {/* Header row */}
                <div className="flex items-start justify-between mb-4">
                  <div className="w-10 h-10 rounded-xl bg-steelGray/30 flex items-center justify-center">
                    <Layers size={18} className="text-white/50" />
                  </div>
                  <span className={`px-3 py-1 rounded-full text-xs font-semibold ${project.stageColor}`}>
                    {project.stage}
                  </span>
                </div>

                {/* Name & description */}
                <h3 className="text-lg font-bold text-white mb-2 group-hover:text-electricBlue transition-colors">
                  {project.name}
                </h3>
                <p className="text-sm text-white/60 leading-relaxed mb-4 line-clamp-3">
                  {project.description}
                </p>

                {/* Skills */}
                <div className="flex flex-wrap gap-2 mb-4">
                  {project.skills.map((skill) => (
                    <span
                      key={skill}
                      className="px-2.5 py-1 text-xs font-medium text-white/70 bg-steelGray/30 rounded-lg"
                    >
                      {skill}
                    </span>
                  ))}
                </div>

                {/* Footer */}
                <div className="flex items-center justify-between pt-4 border-t border-steelGray/30">
                  <div className="flex items-center gap-1.5 text-sm text-white/50">
                    <Users size={14} />
                    <span>{project.teamSize} members</span>
                  </div>
                  <button className="text-sm font-medium text-electricBlue hover:text-brightCyan flex items-center gap-1 group-hover:gap-2 transition-all">
                    View project
                    <ArrowRight size={14} />
                  </button>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center"
        >
          <a
            href="#projects"
            className="inline-flex items-center gap-2 px-8 py-3.5 text-base font-semibold text-electricBlue rounded-xl border-2 border-electricBlue/40 hover:bg-electricBlue/10 hover:border-electricBlue transition-all duration-300 hover:-translate-y-0.5 group"
          >
            Explore All Projects
            <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform" />
          </a>
        </motion.div>
      </div>
    </section>
  )
}
