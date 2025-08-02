'use client'

import React, { FC, ReactNode, useMemo, useState, useEffect } from 'react'
import {
  ConnectionProvider,
  WalletProvider as SolanaWalletProvider,
} from '@solana/wallet-adapter-react'
import { WalletModalProvider } from '@solana/wallet-adapter-react-ui'
import {
  PhantomWalletAdapter,
  SolflareWalletAdapter,
} from '@solana/wallet-adapter-wallets'
import { clusterApiUrl } from '@solana/web3.js'

// Import wallet adapter CSS
require('@solana/wallet-adapter-react-ui/styles.css')

interface WalletProviderProps {
  children: ReactNode
}

export const WalletProvider: FC<WalletProviderProps> = ({ children }) => {
  const [mounted, setMounted] = useState(false)
  const network = process.env.NEXT_PUBLIC_SOLANA_NETWORK || 'devnet'
  
  // Prevent hydration mismatches by only rendering on client
  useEffect(() => {
    setMounted(true)
  }, [])
  
  // Configure the RPC endpoint
  const endpoint = useMemo(() => {
    if (network === 'devnet') {
      return clusterApiUrl('devnet')
    } else if (network === 'testnet') {
      return clusterApiUrl('testnet')
    } else if (network === 'mainnet-beta') {
      return clusterApiUrl('mainnet-beta')
    }
    return clusterApiUrl('devnet') // Default to devnet
  }, [network])

  // Configure supported wallets
  const wallets = useMemo(
    () => [
      new PhantomWalletAdapter(),
      new SolflareWalletAdapter(),
    ],
    []
  )

  // Don't render wallet providers until mounted (client-side only)
  if (!mounted) {
    return <div>{children}</div>
  }

  return (
    <ConnectionProvider endpoint={endpoint}>
      <SolanaWalletProvider wallets={wallets} autoConnect>
        <WalletModalProvider>
          {children}
        </WalletModalProvider>
      </SolanaWalletProvider>
    </ConnectionProvider>
  )
} 