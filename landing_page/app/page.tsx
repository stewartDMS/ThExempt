import Navbar from '@/components/Navbar'
import Hero from '@/components/Hero'
import Problem from '@/components/Problem'
import Stats from '@/components/Stats'
import Features from '@/components/Features'
import HowItWorks from '@/components/HowItWorks'
import LiveProjects from '@/components/LiveProjects'
import Audience from '@/components/Audience'
import Testimonials from '@/components/Testimonials'
import CTA from '@/components/CTA'
import Footer from '@/components/Footer'

export default function Home() {
  return (
    <main className="min-h-screen bg-charcoal overflow-x-hidden">
      <Navbar />
      <Hero />
      <Problem />
      <Stats />
      <HowItWorks />
      <Features />
      <LiveProjects />
      <Audience />
      <Testimonials />
      <CTA />
      <Footer />
    </main>
  )
}
