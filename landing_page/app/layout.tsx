import type { Metadata, Viewport } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
})

export const metadata: Metadata = {
  title: 'ThExempt — Build Your Next Big Idea Together',
  description:
    'ThExempt is the platform for ambitious young people to discover purpose, build skills, and contribute to real business ideas. Connect with talented collaborators and ship something extraordinary.',
  keywords: [
    'startup',
    'collaboration',
    'young entrepreneurs',
    'co-founder',
    'build together',
    'ThExempt',
    'innovation',
    'projects',
  ],
  authors: [{ name: 'ThExempt Team' }],
  creator: 'ThExempt',
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://thexempt.com',
    siteName: 'ThExempt',
    title: 'ThExempt — Build Your Next Big Idea Together',
    description:
      'The platform for ambitious young people to discover purpose, build skills, and contribute to real business ideas.',
    images: [
      {
        url: 'https://thexempt.com/og-image.png',
        width: 1200,
        height: 630,
        alt: 'ThExempt — Build Your Next Big Idea Together',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'ThExempt — Build Your Next Big Idea Together',
    description:
      'The platform for ambitious young people to discover purpose, build skills, and contribute to real business ideas.',
    creator: '@thexempt',
    images: ['https://thexempt.com/og-image.png'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
}

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#030712' },
  ],
  width: 'device-width',
  initialScale: 1,
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className={inter.variable} suppressHydrationWarning>
      <body
        className={`${inter.className} antialiased dark:bg-gray-950 dark:text-gray-50`}
        suppressHydrationWarning
      >
        {children}
      </body>
    </html>
  )
}
