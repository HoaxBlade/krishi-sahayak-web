'use client'

import { createContext, useContext, useEffect, useState, ReactNode } from 'react'
import { User } from '@supabase/supabase-js'
import { AuthService } from '@/lib/authService'

interface AuthContextType {
  user: User | null
  loading: boolean
  isAuthenticated: boolean
  signIn: (email: string, password: string) => Promise<void>
  signUp: (email: string, password: string, metadata?: { full_name?: string; phone?: string }) => Promise<void>
  signOut: () => Promise<void>
  updateProfile: (updates: { full_name?: string; phone?: string }) => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

interface AuthProviderProps {
  children: ReactNode
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let mounted = true
    
    const initializeAuth = async () => {
      try {
        const authService = AuthService.getInstance()
        
        // Get initial session
        const { data: { session } } = await authService.getCurrentSession()
        if (mounted) {
          setUser(session?.user ?? null)
        }

        // Listen for auth state changes
        const { data: { subscription } } = authService.onAuthStateChange((user: User | null) => {
          if (mounted) {
            setUser(user)
            setLoading(false)
          }
        })

        return () => {
          if (subscription) {
            subscription.unsubscribe()
          }
        }
      } catch (error) {
        console.error('Error initializing auth:', error)
        if (mounted) {
          setLoading(false)
        }
      }
    }

    const cleanup = initializeAuth()

    return () => {
      mounted = false
      cleanup.then(cleanupFn => {
        if (cleanupFn) cleanupFn()
      })
    }
  }, [])

  const signIn = async (email: string, password: string) => {
    const authService = AuthService.getInstance()
    await authService.signIn({ email, password })
  }

  const signUp = async (email: string, password: string, metadata?: { full_name?: string; phone?: string }) => {
    const authService = AuthService.getInstance()
    await authService.signUp({ email, password, metadata })
  }

  const signOut = async () => {
    const authService = AuthService.getInstance()
    await authService.signOut()
  }

  const updateProfile = async (updates: { full_name?: string; phone?: string }) => {
    const authService = AuthService.getInstance()
    await authService.updateProfile(updates)
  }

  const value = {
    user,
    loading,
    isAuthenticated: !!user,
    signIn,
    signUp,
    signOut,
    updateProfile
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}
