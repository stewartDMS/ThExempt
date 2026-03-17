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
    stageColor: 'bg-emerald-100 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300',
    gradient: 'from-emerald-400/20 to-teal-500/20',
  },
  {
    name: 'MentorLoop',
    description:
      'Platform connecting first-gen college students with industry professionals for personalized career mentorship.',
    skills: ['Next.js', 'Python', 'Product Strategy'],
    teamSize: 4,
    stage: 'Beta',
    stageColor: 'bg-blue-100 dark:bg-blue-950/60 text-blue-700 dark:text-blue-300',
    gradient: 'from-blue-400/20 to-indigo-500/20',
  },
  {
    name: 'SkillForge',
    description:
      'AI-powered platform that creates personalized learning paths for aspiring entrepreneurs based on their goals.',
    skills: ['TypeScript', 'AI/ML', 'Content Strategy'],
    teamSize: 2,
    stage: 'Idea',
    stageColor: 'bg-purple-100 dark:bg-purple-950/60 text-purple-700 dark:text-purple-300',
    gradient: 'from-purple-400/20 to-pink-500/20',
  },
]

export default function LiveProjects() {
  return (
    <section className="py-24 bg-white dark:bg-gray-950">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <span className="inline-block px-4 py-1.5 mb-4 text-sm font-semibold text-emerald-700 dark:text-emerald-300 bg-emerald-100 dark:bg-emerald-950/50 rounded-full border border-emerald-200 dark:border-emerald-800/50">
            Live Projects
          </span>
          <h2 className="text-4xl sm:text-5xl font-bold text-gray-900 dark:text-white mb-4">
            See What&apos;s{' '}
            <span className="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
              Being Built
            </span>
          </h2>
          <p className="text-xl text-gray-500 dark:text-gray-400 max-w-2xl mx-auto">
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
              className="group relative p-6 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 hover:border-gray-200 dark:hover:border-gray-700 shadow-sm hover:shadow-xl hover:shadow-gray-200/60 dark:hover:shadow-gray-900/60 transition-all duration-300 cursor-pointer"
            >
              {/* Gradient background */}
              <div
                className={`absolute inset-0 rounded-2xl bg-gradient-to-br ${project.gradient} opacity-0 group-hover:opacity-100 transition-opacity duration-300`}
              />

              <div className="relative z-10">
                {/* Header row */}
                <div className="flex items-start justify-between mb-4">
                  <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-gray-100 to-gray-200 dark:from-gray-800 dark:to-gray-700 flex items-center justify-center">
                    <Layers size={18} className="text-gray-500 dark:text-gray-400" />
                  </div>
                  <span className={`px-3 py-1 rounded-full text-xs font-semibold ${project.stageColor}`}>
                    {project.stage}
                  </span>
                </div>

                {/* Name & description */}
                <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-2 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                  {project.name}
                </h3>
                <p className="text-sm text-gray-500 dark:text-gray-400 leading-relaxed mb-4 line-clamp-3">
                  {project.description}
                </p>

                {/* Skills */}
                <div className="flex flex-wrap gap-2 mb-4">
                  {project.skills.map((skill) => (
                    <span
                      key={skill}
                      className="px-2.5 py-1 text-xs font-medium text-gray-600 dark:text-gray-300 bg-gray-100 dark:bg-gray-800 rounded-lg"
                    >
                      {skill}
                    </span>
                  ))}
                </div>

                {/* Footer */}
                <div className="flex items-center justify-between pt-4 border-t border-gray-100 dark:border-gray-800">
                  <div className="flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400">
                    <Users size={14} />
                    <span>{project.teamSize} members</span>
                  </div>
                  <button className="text-sm font-medium text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 flex items-center gap-1 group-hover:gap-2 transition-all">
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
            className="inline-flex items-center gap-2 px-8 py-3.5 text-base font-semibold text-blue-600 dark:text-blue-400 rounded-xl border-2 border-blue-200 dark:border-blue-800 hover:bg-blue-50 dark:hover:bg-blue-950/30 hover:border-blue-400 dark:hover:border-blue-600 transition-all duration-300 hover:-translate-y-0.5 group"
          >
            Explore All Projects
            <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform" />
          </a>
        </motion.div>
      </div>
    </section>
  )
}
