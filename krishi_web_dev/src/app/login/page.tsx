'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { motion } from 'framer-motion'
import LoginForm from '@/components/LoginForm'
import SignupForm from '@/components/SignupForm'
import { AuthService } from '@/lib/authService'

export default function AuthPage() {
  const [isLogin, setIsLogin] = useState(true)
  const [loading, setLoading] = useState(true)
  const router = useRouter()

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const authService = AuthService.getInstance()
        const isAuthenticated = await authService.isAuthenticated()
        
        if (isAuthenticated) {
          router.push('/dashboard')
        }
      } catch (error) {
        console.error('Auth check failed:', error)
      } finally {
        setLoading(false)
      }
    }

    checkAuth()
  }, [router])

  const handleAuthSuccess = () => {
    router.push('/dashboard')
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50">
      {/* Main Content */}
      <div className="flex items-center justify-center min-h-screen py-12 px-4 sm:px-6 lg:px-8">
        <div className="w-full max-w-6xl">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            {/* Left Side - Branding */}
            <motion.div
              initial={{ opacity: 0, x: -50 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.6 }}
              className="text-center lg:text-left"
            >
              <h1 className="text-4xl lg:text-5xl font-bold text-gray-900 mb-6">
                Welcome to{' '}
                <span className="text-green-600">Krishi Sahayak</span>
              </h1>
              <p className="text-xl text-gray-600 mb-8">
                Your AI-powered farming companion for crop health analysis, 
                weather forecasting, and agricultural insights.
              </p>
              
              <div className="space-y-4">
                <div className="flex items-center space-x-3">
                  <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                  <span className="text-gray-700">AI-powered crop disease detection</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                  <span className="text-gray-700">Real-time weather monitoring</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                  <span className="text-gray-700">Personalized farming recommendations</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                  <span className="text-gray-700">Offline-capable mobile app</span>
                </div>
              </div>
            </motion.div>

            {/* Right Side - Auth Form */}
            <motion.div
              initial={{ opacity: 0, x: 50 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.6, delay: 0.2 }}
            >
              {isLogin ? (
                <LoginForm 
                  onSuccess={handleAuthSuccess}
                  onSwitchToSignup={() => setIsLogin(false)}
                />
              ) : (
                <SignupForm 
                  onSuccess={handleAuthSuccess}
                  onSwitchToLogin={() => setIsLogin(true)}
                />
              )}
            </motion.div>
          </div>
        </div>
      </div>
    </div>
  )
}
