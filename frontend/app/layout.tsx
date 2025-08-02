import './globals.css'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import { WalletProvider } from '@/components/WalletProvider'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'AdeptDAO - AI-Powered DAO Governance',
  description: 'AI-powered analysis for DAO governance proposals on Solana',
  keywords: ['DAO', 'Governance', 'Solana', 'AI', 'Blockchain', 'DeFi'],
  authors: [{ name: 'AdeptDAO Team' }],
  icons: {
    icon: '/favicon.svg',
    shortcut: '/favicon.svg',
    apple: '/favicon.svg',
  },
  openGraph: {
    title: 'AdeptDAO - AI-Powered DAO Governance',
    description: 'Make informed DAO governance decisions with AI-powered multi-agent analysis',
    type: 'website',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <WalletProvider>
          <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100 dark:from-slate-900 dark:via-slate-800 dark:to-slate-900">
            {children}
          </div>
        </WalletProvider>
      </body>
    </html>
  )
} 