'use client'

import { useState, useEffect, useCallback, memo } from 'react'
import { useWallet } from '@solana/wallet-adapter-react'
import { Search, FileText, Clock, AlertCircle, CheckCircle2 } from 'lucide-react'

interface Proposal {
  address: string
  title: string
  description: string
  state: string
  created_at?: string
}

interface DashboardProps {
  selectedDAO: string
  onDAOChange: (dao: string) => void
  onProposalSelect: (proposalAddress: string) => void
}

// Memoized sample DAO buttons
const SampleDAOs = memo(({ onDAOChange, connected }: { 
  onDAOChange: (dao: string) => void, 
  connected: boolean 
}) => (
  <div className="text-sm text-gray-600 dark:text-gray-400">
    <p className="mb-2">Try these sample DAOs:</p>
    <div className="flex flex-wrap gap-2">
      {[
        { name: 'Sample DAO 1', address: '7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU' },
        { name: 'Sample DAO 2', address: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM' },
      ].map((dao) => (
        <button
          key={dao.address}
          onClick={() => onDAOChange(dao.address)}
          className="px-3 py-1 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-md text-xs transition-colors"
          disabled={!connected}
        >
          {dao.name}
        </button>
      ))}
    </div>
  </div>
))

SampleDAOs.displayName = 'SampleDAOs'

// Memoized proposal card component
const ProposalCard = memo(({ 
  proposal, 
  onSelect, 
  getStateIcon, 
  getStateColor 
}: { 
  proposal: Proposal, 
  onSelect: (address: string) => void,
  getStateIcon: (state: string) => JSX.Element,
  getStateColor: (state: string) => string
}) => (
  <div
    className="border border-gray-200 dark:border-gray-700 rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer group"
    onClick={() => onSelect(proposal.address)}
  >
    <div className="flex items-start justify-between">
      <div className="flex-1">
        <div className="flex items-center space-x-3 mb-2">
          {getStateIcon(proposal.state)}
          <h4 className="font-medium text-gray-900 dark:text-white group-hover:text-solana-purple transition-colors">
            {proposal.title}
          </h4>
          <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStateColor(proposal.state)}`}>
            {proposal.state}
          </span>
        </div>
        <p className="text-sm text-gray-600 dark:text-gray-400 mb-2 line-clamp-2">
          {proposal.description}
        </p>
        <p className="text-xs text-gray-500 dark:text-gray-500">
          Address: {proposal.address}
        </p>
      </div>
      <div className="ml-4">
        <button className="px-4 py-2 bg-gradient-to-r from-solana-purple to-purple-600 text-white text-sm font-medium rounded-lg hover:from-purple-600 hover:to-purple-700 transition-all group-hover:scale-105">
          Analyze with AI
        </button>
      </div>
    </div>
  </div>
))

ProposalCard.displayName = 'ProposalCard'

export const Dashboard = memo(function Dashboard({ selectedDAO, onDAOChange, onProposalSelect }: DashboardProps) {
  const { connected } = useWallet()
  const [proposals, setProposals] = useState<Proposal[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchProposals = useCallback(async (daoAddress: string) => {
    if (!daoAddress) return

    setLoading(true)
    setError(null)

    try {
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/v1/dao/${daoAddress}/proposals`
      )

      if (!response.ok) {
        throw new Error('Failed to fetch proposals')
      }

      const data = await response.json()
      setProposals(data.proposals)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error occurred')
      setProposals([])
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    if (selectedDAO) {
      fetchProposals(selectedDAO)
    }
  }, [selectedDAO, fetchProposals])

  const getStateIcon = useCallback((state: string) => {
    switch (state.toLowerCase()) {
      case 'voting':
        return <Clock className="h-4 w-4 text-blue-500" />
      case 'succeeded':
        return <CheckCircle2 className="h-4 w-4 text-green-500" />
      case 'defeated':
        return <AlertCircle className="h-4 w-4 text-red-500" />
      default:
        return <FileText className="h-4 w-4 text-gray-500" />
    }
  }, [])

  const getStateColor = useCallback((state: string) => {
    switch (state.toLowerCase()) {
      case 'voting':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300'
      case 'succeeded':
        return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
      case 'defeated':
        return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300'
    }
  }, [])

  return (
    <div className="max-w-6xl mx-auto">
      {/* Connection Check */}
      {!connected && (
        <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4 mb-6">
          <div className="flex items-center space-x-2">
            <AlertCircle className="h-5 w-5 text-yellow-600 dark:text-yellow-400" />
            <p className="text-yellow-800 dark:text-yellow-200">
              Please connect your Solana wallet to continue
            </p>
          </div>
        </div>
      )}

      {/* DAO Input Section */}
      <div className="bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6 mb-8">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
          DAO Governance Analysis
        </h2>
        
        <div className="space-y-4">
          <div>
            <label htmlFor="dao-address" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Enter DAO Address (Realms-based)
            </label>
            <div className="relative">
              <input
                id="dao-address"
                type="text"
                value={selectedDAO}
                onChange={(e) => onDAOChange(e.target.value)}
                placeholder="e.g., 9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"
                className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:ring-2 focus:ring-solana-purple focus:border-transparent"
                disabled={!connected}
              />
              <Search className="absolute right-3 top-3 h-5 w-5 text-gray-400" />
            </div>
          </div>

          {/* Sample DAO addresses */}
          <SampleDAOs onDAOChange={onDAOChange} connected={connected} />
        </div>
      </div>

      {/* Proposals Section */}
      {selectedDAO && (
        <div className="bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white">
              Governance Proposals
            </h3>
            {loading && (
              <div className="flex items-center space-x-2 text-sm text-gray-600 dark:text-gray-400">
                <div className="w-4 h-4 border-2 border-solana-purple border-t-transparent rounded-full animate-spin"></div>
                <span>Loading proposals...</span>
              </div>
            )}
          </div>

          {error && (
            <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-6">
              <div className="flex items-center space-x-2">
                <AlertCircle className="h-5 w-5 text-red-600 dark:text-red-400" />
                <p className="text-red-800 dark:text-red-200">{error}</p>
              </div>
            </div>
          )}

          {!loading && !error && proposals.length === 0 && selectedDAO && (
            <div className="text-center py-8 text-gray-500 dark:text-gray-400">
              <FileText className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>No proposals found for this DAO</p>
            </div>
          )}

          {proposals.length > 0 && (
            <div className="space-y-4">
              {proposals.map((proposal) => (
                <ProposalCard
                  key={proposal.address}
                  proposal={proposal}
                  onSelect={onProposalSelect}
                  getStateIcon={getStateIcon}
                  getStateColor={getStateColor}
                />
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  )
})

Dashboard.displayName = 'Dashboard'