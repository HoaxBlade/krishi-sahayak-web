import { createClient, User } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export interface AuthUser {
  id: string
  email: string
  created_at: string
  updated_at: string
}

export interface SignUpData {
  email: string
  password: string
  metadata?: {
    full_name?: string
    phone?: string
  }
}

export interface SignInData {
  email: string
  password: string
}

export class AuthService {
  private static instance: AuthService

  private constructor() {}

  public static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService()
    }
    return AuthService.instance
  }

  // Sign up with email and password
  async signUp({ email, password, metadata }: SignUpData) {
    try {
      
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: metadata
        }
      })

      if (error) {
        console.error('❌ [AuthService] Sign up failed:', error.message)
        throw new Error(error.message)
      }

      return { data, error: null }
    } catch (error) {
      console.error('❌ [AuthService] Sign up error:', error)
      throw error
    }
  }

  // Sign in with email and password
  async signIn({ email, password }: SignInData) {
    try {
      
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      })

      if (error) {
        console.error('❌ [AuthService] Sign in failed:', error.message)
        throw new Error(error.message)
      }

      return { data, error: null }
    } catch (error) {
      console.error('❌ [AuthService] Sign in error:', error)
      throw error
    }
  }

  // Sign out
  async signOut() {
    try {
      
      const { error } = await supabase.auth.signOut()
      
      if (error) {
        console.error('❌ [AuthService] Sign out failed:', error.message)
        throw new Error(error.message)
      }

    } catch (error) {
      console.error('❌ [AuthService] Sign out error:', error)
      throw error
    }
  }

  // Get current user
  getCurrentUser() {
    return supabase.auth.getUser()
  }

  // Get current session
  getCurrentSession() {
    return supabase.auth.getSession()
  }

  // Check if user is authenticated
  async isAuthenticated(): Promise<boolean> {
    try {
      const { data: { user } } = await supabase.auth.getUser()
      return user !== null
    } catch (error) {
      console.error('❌ [AuthService] Error checking authentication:', error)
      return false
    }
  }

  // Listen to auth state changes
  onAuthStateChange(callback: (user: User | null) => void) {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      callback(session?.user ?? null)
    })
    return { data: { subscription } }
  }

  // Reset password
  async resetPassword(email: string) {
    try {
      
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`
      })

      if (error) {
        console.error('❌ [AuthService] Password reset failed:', error.message)
        throw new Error(error.message)
      }

    } catch (error) {
      console.error('❌ [AuthService] Password reset error:', error)
      throw error
    }
  }

  // Update user profile
  async updateProfile(updates: { full_name?: string; phone?: string }) {
    try {
      
      const { data, error } = await supabase.auth.updateUser({
        data: updates
      })

      if (error) {
        console.error('❌ [AuthService] Profile update failed:', error.message)
        throw new Error(error.message)
      }

      return { data, error: null }
    } catch (error) {
      console.error('❌ [AuthService] Profile update error:', error)
      throw error
    }
  }

  // Health check
  async checkConnection(): Promise<boolean> {
    try {
      const { error } = await supabase.from('crops').select('id').limit(1)
      return !error
    } catch (error) {
      console.error('❌ [AuthService] Connection check failed:', error)
      return false
    }
  }
}
