/* eslint-disable @typescript-eslint/no-unused-vars */
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
    state?: string
    district?: string
    region?: string
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
        throw new Error(error.message)
      }

      return { data, error: null }
    } catch (error) {
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
        throw new Error(error.message)
      }

      // Create provider profile if it doesn't exist
      if (data.user) {
        await this.ensureProviderProfile(data.user.id)
      }

      return { data, error: null }
    } catch (error) {
      throw error
    }
  }

  // Sign out
  async signOut() {
    try {
      const { error } = await supabase.auth.signOut()
      
      if (error) {
        throw new Error(error.message)
      }
    } catch (error) {
      throw error
    }
  }

  // Clear all cached auth data
  async clearAuthCache() {
    try {
      // Sign out from Supabase
      await supabase.auth.signOut()

      // Clear localStorage
      if (typeof window !== 'undefined') {
        // Clear Supabase auth storage
        localStorage.removeItem('sb-' + supabaseUrl.split('//')[1].split('.')[0] + '-auth-token')

        // Clear any other auth-related storage
        Object.keys(localStorage).forEach(key => {
          if (key.includes('supabase') || key.includes('auth')) {
            localStorage.removeItem(key)
          }
        })
      }
    } catch (error) {
      throw error
    }
  }

  // Resend confirmation email
  async resendConfirmation(email: string) {
    try {
      const { error } = await supabase.auth.resend({
        type: 'signup',
        email: email
      })

      if (error) {
        throw new Error(error.message)
      }

      return { success: true }
    } catch (error) {
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
    } catch {
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
        throw new Error(error.message)
      }
    } catch (error) {
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
        throw new Error(error.message)
      }

      return { data, error: null }
    } catch (error) {
      throw error
    }
  }

  // Health check
  async checkConnection(): Promise<boolean> {
    try {
      const { error } = await supabase.from('crops').select('id').limit(1)
      return !error
    } catch {
      return false
    }
  }

  // Check if user exists in Supabase Auth
  async checkUserExists(): Promise<boolean> {
    // Note: This method requires service role key, not anon key
    // For now, we'll return false and let the sign-in process handle it
    return false
  }

  // Ensure provider profile exists for user
  async ensureProviderProfile(userId: string): Promise<void> {
    try {
      // Check if provider profile already exists
      const { data: existingProfile, error: checkError } = await supabase
        .from('provider_profiles')
        .select('id')
        .eq('user_id', userId)
        .single()

      // If profile exists, no need to create
      if (existingProfile && !checkError) {
        return
      }

      // Create default provider profile
      const profileData = {
        user_id: userId,
        business_name: 'My Business',
        description: 'Default business profile',
        business_type: 'individual',
        address: 'Address not provided',
        city: 'City not provided',
        state: 'State not provided',
        pincode: '000000',
        phone: '0000000000',
        rating_avg: 0,
        total_orders: 0,
        verification_status: 'pending'
      }
      
      const { error: createError } = await supabase
        .from('provider_profiles')
        .insert(profileData)
        .select('id')
        .single()

      if (createError) {
        // Don't throw error - this shouldn't break the login process
      }
    } catch (error) {
      // Don't throw error - this shouldn't break the login process
    }
  }
}
