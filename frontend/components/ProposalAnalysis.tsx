'use client'

import { useState, useEffect } from 'react'
import { useWallet } from '@solana/wallet-adapter-react'
import { ArrowLeft, Brain, DollarSign, Shield, MessageSquare, ThumbsUp, ThumbsDown, Loader2, AlertCircle } from 'lucide-react'

interface AnalysisData {
  proposal_address: string
  proposal_title: string
  proposal_description: string
  financial_analysis: {
    treasury_impact: string
    roi_assessment: string
    risk_level: string
    recommendations: string[]
  }
  technical_analysis: {
    complexity: string
    security_risks: string[]
    feasibility: string
    timeline: string
  }
  sentiment_analysis: {
    tone: string
    clarity: string
    potential_reception: string
    contentious_points: string[]
  }
  aggregated_summary: {
    overall_score: number
    recommendation: string
    key_considerations: string[]
  }
}

interface ProposalAnalysisProps {
  proposalAddress: string
  onBack: () => void
}

export function ProposalAnalysis({ proposalAddress, onBack }: ProposalAnalysisProps) {
  const { connected, publicKey } = useWallet()
  const [analysis, setAnalysis] = useState<AnalysisData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<'financial' | 'technical' | 'sentiment' | 'summary'>('summary')
  const [votingLoading, setVotingLoading] = useState(false)

  useEffect(() => {
    fetchAnalysis()
  }, [proposalAddress])

  const fetchAnalysis = async () => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/v1/proposals/${proposalAddress}/analyze`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
        }
      )

      if (!response.ok) {
        throw new Error('Failed to analyze proposal')
      }

      const data = await response.json()
      setAnalysis(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error occurred')
    } finally {
      setLoading(false)
    }
  }

  const handleVote = async (voteChoice: 'approve' | 'deny') => {
    if (!connected || !publicKey) {
      alert('Please connect your wallet first')
      return
    }

    setVotingLoading(true)

    try {
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/v1/proposals/${proposalAddress}/prepare-vote`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            proposal_address: proposalAddress,
            vote_choice: voteChoice,
            user_wallet: publicKey.toString(),
          }),
        }
      )

      if (!response.ok) {
        throw new Error('Failed to prepare vote transaction')
      }

      const data = await response.json()
      
      // In a real implementation, this would use @solana/web3.js to sign and send the transaction
      alert(`Vote transaction prepared: ${data.transaction_message}\n\nIn production, this would prompt your wallet to sign the transaction.`)
      
    } catch (err) {
      alert(`Error: ${err instanceof Error ? err.message : 'Unknown error occurred'}`)
    } finally {
      setVotingLoading(false)
    }
  }

  const getScoreColor = (score: number) => {
    if (score >= 8) return 'text-green-600 dark:text-green-400'
    if (score >= 6) return 'text-yellow-600 dark:text-yellow-400'
    return 'text-red-600 dark:text-red-400'
  }

  const getScoreBackground = (score: number) => {
    if (score >= 8) return 'from-green-500 to-green-600'
    if (score >= 6) return 'from-yellow-500 to-yellow-600'
    return 'from-red-500 to-red-600'
  }

  if (loading) {
    return (
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center justify-center py-16">
          <div className="text-center">
            <div className="w-16 h-16 border-4 border-solana-purple border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
            <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
              AI Swarm Analyzing Proposal
            </h3>
            <p className="text-gray-600 dark:text-gray-400">
              Financial Analyst, Technical Assessor, and Sentiment Analyst are working...
            </p>
          </div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="max-w-4xl mx-auto">
        <button
          onClick={onBack}
          className="flex items-center space-x-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white mb-6"
        >
          <ArrowLeft className="h-4 w-4" />
          <span>Back to Dashboard</span>
        </button>
        
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-6">
          <div className="flex items-center space-x-2 mb-4">
            <AlertCircle className="h-5 w-5 text-red-600 dark:text-red-400" />
            <h3 className="text-lg font-medium text-red-800 dark:text-red-200">Analysis Failed</h3>
          </div>
          <p className="text-red-700 dark:text-red-300 mb-4">{error}</p>
          <button
            onClick={fetchAnalysis}
            className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
          >
            Retry Analysis
          </button>
        </div>
      </div>
    )
  }

  if (!analysis) return null

  return (
    <div className="max-w-6xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <button
          onClick={onBack}
          className="flex items-center space-x-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
        >
          <ArrowLeft className="h-4 w-4" />
          <span>Back to Dashboard</span>
        </button>
      </div>

      {/* Proposal Info */}
      <div className="bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6 mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
          {analysis.proposal_title}
        </h1>
        <p className="text-gray-600 dark:text-gray-400 mb-4">
          {analysis.proposal_description}
        </p>
        <p className="text-xs text-gray-500 dark:text-gray-500">
          Address: {analysis.proposal_address}
        </p>
      </div>

      {/* Overall Score */}
      <div className="bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6 mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
              AI Swarm Analysis Score
            </h2>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Aggregated assessment from 3 specialized AI agents
            </p>
          </div>
          <div className="text-center">
            <div className={`text-4xl font-bold ${getScoreColor(analysis.aggregated_summary.overall_score)}`}>
              {analysis.aggregated_summary.overall_score}/10
            </div>
            <div className={`mt-2 px-4 py-2 rounded-full text-white text-sm font-medium bg-gradient-to-r ${getScoreBackground(analysis.aggregated_summary.overall_score)}`}>
              {analysis.aggregated_summary.recommendation}
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="bg-white dark:bg-slate-800 rounded-xl shadow-lg mb-6">
        <div className="border-b border-gray-200 dark:border-gray-700">
          <nav className="flex space-x-8 px-6">
            {[
              { id: 'summary', label: 'Summary', icon: Brain },
              { id: 'financial', label: 'Financial', icon: DollarSign },
              { id: 'technical', label: 'Technical', icon: Shield },
              { id: 'sentiment', label: 'Sentiment', icon: MessageSquare },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center space-x-2 py-4 px-1 border-b-2 font-medium text-sm ${
                  activeTab === tab.id
                    ? 'border-solana-purple text-solana-purple'
                    : 'border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300'
                }`}
              >
                <tab.icon className="h-4 w-4" />
                <span>{tab.label}</span>
              </button>
            ))}
          </nav>
        </div>

        {/* Tab Content */}
        <div className="p-6">
          {activeTab === 'summary' && (
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-gray-900 dark:text-white">
                Key Considerations
              </h3>
              <ul className="space-y-2">
                {analysis.aggregated_summary.key_considerations.map((consideration, index) => (
                  <li key={index} className="flex items-start space-x-2">
                    <div className="w-2 h-2 bg-solana-purple rounded-full mt-2 flex-shrink-0"></div>
                    <span className="text-gray-700 dark:text-gray-300">{consideration}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {activeTab === 'financial' && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
                  <h4 className="font-medium text-blue-900 dark:text-blue-300 mb-2">Treasury Impact</h4>
                  <p className="text-blue-800 dark:text-blue-200">{analysis.financial_analysis.treasury_impact}</p>
                </div>
                <div className="bg-green-50 dark:bg-green-900/20 rounded-lg p-4">
                  <h4 className="font-medium text-green-900 dark:text-green-300 mb-2">ROI Assessment</h4>
                  <p className="text-green-800 dark:text-green-200">{analysis.financial_analysis.roi_assessment}</p>
                </div>
                <div className="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4">
                  <h4 className="font-medium text-yellow-900 dark:text-yellow-300 mb-2">Risk Level</h4>
                  <p className="text-yellow-800 dark:text-yellow-200">{analysis.financial_analysis.risk_level}</p>
                </div>
              </div>
              <div>
                <h4 className="font-medium text-gray-900 dark:text-white mb-3">Recommendations</h4>
                <ul className="space-y-2">
                  {analysis.financial_analysis.recommendations.map((rec, index) => (
                    <li key={index} className="flex items-start space-x-2">
                      <div className="w-2 h-2 bg-green-500 rounded-full mt-2 flex-shrink-0"></div>
                      <span className="text-gray-700 dark:text-gray-300">{rec}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          )}

          {activeTab === 'technical' && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <div>
                    <h4 className="font-medium text-gray-900 dark:text-white mb-2">Complexity</h4>
                    <p className="text-gray-700 dark:text-gray-300">{analysis.technical_analysis.complexity}</p>
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900 dark:text-white mb-2">Feasibility</h4>
                    <p className="text-gray-700 dark:text-gray-300">{analysis.technical_analysis.feasibility}</p>
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900 dark:text-white mb-2">Timeline</h4>
                    <p className="text-gray-700 dark:text-gray-300">{analysis.technical_analysis.timeline}</p>
                  </div>
                </div>
                <div>
                  <h4 className="font-medium text-gray-900 dark:text-white mb-3">Security Risks</h4>
                  <ul className="space-y-2">
                    {analysis.technical_analysis.security_risks.map((risk, index) => (
                      <li key={index} className="flex items-start space-x-2">
                        <AlertCircle className="h-4 w-4 text-red-500 mt-0.5 flex-shrink-0" />
                        <span className="text-gray-700 dark:text-gray-300">{risk}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'sentiment' && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-4">
                  <h4 className="font-medium text-purple-900 dark:text-purple-300 mb-2">Tone</h4>
                  <p className="text-purple-800 dark:text-purple-200">{analysis.sentiment_analysis.tone}</p>
                </div>
                <div className="bg-indigo-50 dark:bg-indigo-900/20 rounded-lg p-4">
                  <h4 className="font-medium text-indigo-900 dark:text-indigo-300 mb-2">Clarity</h4>
                  <p className="text-indigo-800 dark:text-indigo-200">{analysis.sentiment_analysis.clarity}</p>
                </div>
                <div className="bg-pink-50 dark:bg-pink-900/20 rounded-lg p-4">
                  <h4 className="font-medium text-pink-900 dark:text-pink-300 mb-2">Reception</h4>
                  <p className="text-pink-800 dark:text-pink-200">{analysis.sentiment_analysis.potential_reception}</p>
                </div>
              </div>
              {analysis.sentiment_analysis.contentious_points.length > 0 && (
                <div>
                  <h4 className="font-medium text-gray-900 dark:text-white mb-3">Contentious Points</h4>
                  <ul className="space-y-2">
                    {analysis.sentiment_analysis.contentious_points.map((point, index) => (
                      <li key={index} className="flex items-start space-x-2">
                        <AlertCircle className="h-4 w-4 text-orange-500 mt-0.5 flex-shrink-0" />
                        <span className="text-gray-700 dark:text-gray-300">{point}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Voting Section */}
      {connected && (
        <div className="bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Cast Your Vote
          </h3>
          <p className="text-gray-600 dark:text-gray-400 mb-6">
            Based on the AI analysis, make your governance decision
          </p>
          <div className="flex space-x-4">
            <button
              onClick={() => handleVote('approve')}
              disabled={votingLoading}
              className="flex items-center space-x-2 px-6 py-3 bg-green-600 hover:bg-green-700 disabled:bg-gray-400 text-white font-medium rounded-lg transition-colors"
            >
              {votingLoading ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <ThumbsUp className="h-4 w-4" />
              )}
              <span>Vote Approve</span>
            </button>
            <button
              onClick={() => handleVote('deny')}
              disabled={votingLoading}
              className="flex items-center space-x-2 px-6 py-3 bg-red-600 hover:bg-red-700 disabled:bg-gray-400 text-white font-medium rounded-lg transition-colors"
            >
              {votingLoading ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <ThumbsDown className="h-4 w-4" />
              )}
              <span>Vote Deny</span>
            </button>
          </div>
        </div>
      )}
    </div>
  )
} 