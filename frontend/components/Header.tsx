'use client'

import { WalletMultiButton } from '@solana/wallet-adapter-react-ui'
import { useWallet } from '@solana/wallet-adapter-react'
import { Brain, Zap } from 'lucide-react'
import { useState, useEffect } from 'react'

export function Header() {
  const [mounted, setMounted] = useState(false)
  
  // Always call useWallet to follow Rules of Hooks
  const { connected } = useWallet()
  
  // Prevent hydration mismatches for rendering
  useEffect(() => {
    setMounted(true)
  }, [])

  return (
    <header className="border-b border-gray-200 dark:border-gray-700 bg-white/80 dark:bg-slate-900/80 backdrop-blur-sm">
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          {/* Logo and Title */}
          <div className="flex items-center space-x-3">
            <div className="flex items-center space-x-2">
              <div className="relative">
                <Brain className="h-8 w-8 text-solana-purple" />
                <Zap className="h-4 w-4 text-solana-green absolute -top-1 -right-1" />
              </div>
              <div>
                <h1 className="text-2xl font-bold bg-gradient-to-r from-solana-purple to-solana-green bg-clip-text text-transparent">
                  AdeptDAO
                </h1>
                <p className="text-xs text-gray-600 dark:text-gray-400">
                  AI-Powered Governance
                </p>
              </div>
            </div>
          </div>

          {/* Navigation and Wallet */}
          <div className="flex items-center space-x-6">
            {/* Network Indicator */}
            <div className="hidden sm:flex items-center space-x-2 text-sm">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span className="text-gray-600 dark:text-gray-400">Devnet</span>
            </div>

            {/* Connection Status */}
            {connected && (
              <div className="hidden sm:flex items-center space-x-2 text-sm text-green-600 dark:text-green-400">
                <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                <span>Connected</span>
              </div>
            )}

            {/* Wallet Connection Button */}
            {mounted ? (
              <WalletMultiButton className="!bg-solana-purple hover:!bg-purple-700 !transition-colors !rounded-lg !text-white !font-medium" />
            ) : (
              <button 
                disabled 
                className="bg-gray-300 dark:bg-gray-600 text-gray-500 px-4 py-2 rounded-lg cursor-not-allowed"
              >
                Loading...
              </button>
            )}
          </div>
        </div>

        {/* Subtitle */}
        <div className="mt-4 text-center">
          <p className="text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
            Harness the power of AI swarms to analyze DAO governance proposals with unprecedented depth and clarity
          </p>
        </div>
      </div>
    </header>
  )
} 