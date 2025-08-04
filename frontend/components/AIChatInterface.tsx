'use client'

import React, { useState, useRef, useEffect, useCallback, memo } from 'react'
import { Send, Bot, User, Loader2, Sparkles } from 'lucide-react'

interface ChatMessage {
  id: string
  type: 'user' | 'ai'
  content: string
  timestamp: Date
}

interface AIChatInterfaceProps {
  className?: string
}

// Memoized message component for better performance
const ChatMessage = memo(({ message, formatTime }: { 
  message: ChatMessage, 
  formatTime: (date: Date) => string 
}) => (
  <div className={`flex items-start space-x-3 ${
    message.type === 'user' ? 'flex-row-reverse space-x-reverse' : ''
  }`}>
    <div className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center ${
      message.type === 'user' 
        ? 'bg-solana-green text-white' 
        : 'bg-solana-purple text-white'
    }`}>
      {message.type === 'user' ? (
        <User className="h-4 w-4" />
      ) : (
        <Bot className="h-4 w-4" />
      )}
    </div>
    <div className={`flex-1 max-w-xs lg:max-w-md ${
      message.type === 'user' ? 'text-right' : ''
    }`}>
      <div className={`inline-block px-4 py-2 rounded-lg ${
        message.type === 'user'
          ? 'bg-solana-green text-white'
          : 'bg-gray-100 dark:bg-slate-700 text-gray-900 dark:text-white'
      }`}>
        <p className="text-sm whitespace-pre-wrap">{message.content}</p>
      </div>
      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
        {formatTime(message.timestamp)}
      </p>
    </div>
  </div>
))

ChatMessage.displayName = 'ChatMessage'

// Memoized loading indicator
const LoadingIndicator = memo(() => (
  <div className="flex items-start space-x-3">
    <div className="flex-shrink-0 w-8 h-8 rounded-full bg-solana-purple text-white flex items-center justify-center">
      <Bot className="h-4 w-4" />
    </div>
    <div className="flex-1">
      <div className="inline-block px-4 py-2 rounded-lg bg-gray-100 dark:bg-slate-700">
        <div className="flex items-center space-x-2">
          <Loader2 className="h-4 w-4 animate-spin text-solana-purple" />
          <span className="text-sm text-gray-600 dark:text-gray-300">
            AI is thinking...
          </span>
        </div>
      </div>
    </div>
  </div>
))

LoadingIndicator.displayName = 'LoadingIndicator'

export const AIChatInterface: React.FC<AIChatInterfaceProps> = memo(({ className = '' }) => {
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const [isInitialized, setIsInitialized] = useState(false)
  const [input, setInput] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  const scrollToBottom = useCallback(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [])

  useEffect(() => {
    if (!isInitialized) {
      setMessages([{
        id: '1',
        type: 'ai',
        content: 'Hello! I\'m your AI governance advisor powered by JuliaOS. Ask me anything about DAO governance, proposal analysis, or Solana ecosystem insights!',
        timestamp: new Date()
      }])
      setIsInitialized(true)
    }
  }, [isInitialized])

  useEffect(() => {
    scrollToBottom()
  }, [messages, scrollToBottom])

  const formatTime = useCallback((date: Date) => {
    return date.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false })
  }, [])

  const sendMessage = useCallback(async () => {
    if (!input.trim() || isLoading) return

    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      type: 'user',
      content: input.trim(),
      timestamp: new Date()
    }

    setMessages(prev => [...prev, userMessage])
    setInput('')
    setIsLoading(true)

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/ai/chat`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: userMessage.content,
          context: 'dao_governance'
        }),
      })

      if (!response.ok) {
        throw new Error('Failed to get AI response')
      }

      const data = await response.json()
      
      const aiMessage: ChatMessage = {
        id: (Date.now() + 1).toString(),
        type: 'ai',
        content: data.response,
        timestamp: new Date()
      }

      setMessages(prev => [...prev, aiMessage])
    } catch (error) {
      console.error('Error sending message:', error)
      const errorMessage: ChatMessage = {
        id: (Date.now() + 1).toString(),
        type: 'ai',
        content: 'I apologize, but I encountered an error processing your request. Please try again or check if the backend services are running.',
        timestamp: new Date()
      }
      setMessages(prev => [...prev, errorMessage])
    } finally {
      setIsLoading(false)
      inputRef.current?.focus()
    }
  }, [input, isLoading])

  const handleKeyPress = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      sendMessage()
    }
  }, [sendMessage])

  return (
    <div className={`bg-white dark:bg-slate-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 ${className}`}>
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-700">
        <div className="flex items-center space-x-3">
          <div className="relative">
            <Bot className="h-8 w-8 text-solana-purple" />
            <Sparkles className="h-4 w-4 text-solana-green absolute -top-1 -right-1" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              AI Governance Advisor
            </h3>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Powered by JuliaOS
            </p>
          </div>
        </div>
        <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
      </div>

      {/* Messages */}
      <div className="h-96 overflow-y-auto p-4 space-y-4">
        {messages.map((message) => (
          <ChatMessage 
            key={message.id} 
            message={message} 
            formatTime={formatTime}
          />
        ))}
        
        {isLoading && <LoadingIndicator />}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div className="p-4 border-t border-gray-200 dark:border-gray-700">
        <div className="flex items-center space-x-2">
          <input
            ref={inputRef}
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="Ask about DAO governance, proposals, or Solana insights..."
            className="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg 
                     bg-white dark:bg-slate-700 text-gray-900 dark:text-white 
                     placeholder-gray-500 dark:placeholder-gray-400 
                     focus:ring-2 focus:ring-solana-purple focus:border-transparent
                     text-sm"
            disabled={isLoading}
          />
          <button
            onClick={sendMessage}
            disabled={!input.trim() || isLoading}
            className="px-4 py-2 bg-solana-purple hover:bg-solana-purple/90 disabled:bg-gray-300 
                     dark:disabled:bg-gray-600 text-white rounded-lg transition-colors
                     disabled:cursor-not-allowed flex items-center justify-center min-w-[2.5rem]"
          >
            {isLoading ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Send className="h-4 w-4" />
            )}
          </button>
        </div>
        <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">
          💡 Try asking: "Analyze the risk factors in treasury proposals" or "What makes a good governance proposal?"
        </p>
      </div>
    </div>
  )
})

AIChatInterface.displayName = 'AIChatInterface'