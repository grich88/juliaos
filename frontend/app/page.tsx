'use client'

import { useState } from 'react'
import { Header } from '@/components/Header'
import { Dashboard } from '@/components/Dashboard'
import { ProposalAnalysis } from '@/components/ProposalAnalysis'
import { AIChatInterface } from '@/components/AIChatInterface'

export default function Home() {
  const [selectedProposal, setSelectedProposal] = useState<string | null>(null)
  const [selectedDAO, setSelectedDAO] = useState<string>('')

  return (
    <main className="min-h-screen">
      <Header />
      
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-6xl mx-auto">
          {selectedProposal ? (
            <ProposalAnalysis 
              proposalAddress={selectedProposal}
              onBack={() => setSelectedProposal(null)}
            />
          ) : (
            <Dashboard 
              selectedDAO={selectedDAO}
              onDAOChange={setSelectedDAO}
              onProposalSelect={setSelectedProposal}
            />
          )}

          {/* AI Chat Interface */}
          <div className="mt-16">
            <div className="text-center mb-8">
              <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-4">
                AI Governance Advisor
              </h2>
              <p className="text-lg text-gray-600 dark:text-gray-400 max-w-3xl mx-auto">
                Get instant insights and guidance on DAO governance, proposal analysis, and Solana ecosystem questions. 
                Powered by JuliaOS multi-agent intelligence.
              </p>
            </div>
            <AIChatInterface className="max-w-4xl mx-auto" />
          </div>
        </div>
      </div>
      
      {/* Footer */}
      <footer className="border-t border-gray-200 dark:border-gray-700 mt-16 py-8">
        <div className="container mx-auto px-4 text-center text-gray-600 dark:text-gray-400">
          <p className="mb-2">
            Built for the JuliaOS AI dApp Development Bounty 🏆
          </p>
          <p className="text-sm">
            Powered by{' '}
            <a 
              href="https://juliaos.com" 
              target="_blank" 
              rel="noopener noreferrer"
              className="text-solana-purple hover:underline"
            >
              JuliaOS
            </a>{' '}
            and{' '}
            <a 
              href="https://solana.com" 
              target="_blank" 
              rel="noopener noreferrer"
              className="text-solana-green hover:underline"
            >
              Solana
            </a>
          </p>
        </div>
      </footer>
    </main>
  )
} 