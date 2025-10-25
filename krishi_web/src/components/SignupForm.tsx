'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { Eye, EyeOff, Mail, Lock, User, Phone, Loader2 } from 'lucide-react'
import { AuthService } from '@/lib/authService'
import RegionSelector from './RegionSelector'

interface SignupFormProps {
  onSuccess?: () => void
  onSwitchToLogin?: () => void
}

export default function SignupForm({ onSuccess, onSwitchToLogin }: SignupFormProps) {
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phone: '',
    password: '',
    confirmPassword: '',
    state: '',
    district: '',
    region: ''
  })
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [validationErrors, setValidationErrors] = useState<{ [key: string]: string }>({})

  const validateForm = () => {
    const errors: { [key: string]: string } = {}

    if (!formData.fullName.trim()) {
      errors.fullName = 'Full Name is required.'
    } else if (formData.fullName.trim().length < 3) {
      errors.fullName = 'Full Name must be at least 3 characters.'
    }

    if (!formData.email.trim()) {
      errors.email = 'Email is required.'
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      errors.email = 'Email is invalid.'
    }

    if (formData.phone && !/^\+?[0-9]{10,15}$/.test(formData.phone)) {
      errors.phone = 'Phone number is invalid.'
    }

    if (!formData.state.trim()) {
      errors.state = 'State is required.'
    }

    if (!formData.district.trim()) {
      errors.district = 'District is required.'
    }

    if (!formData.password) {
      errors.password = 'Password is required.'
    } else if (formData.password.length < 8) {
      errors.password = 'Password must be at least 8 characters.'
    } else if (!/[A-Z]/.test(formData.password)) {
      errors.password = 'Password must contain an uppercase letter.'
    } else if (!/[a-z]/.test(formData.password)) {
      errors.password = 'Password must contain a lowercase letter.'
    } else if (!/[0-9]/.test(formData.password)) {
      errors.password = 'Password must contain a number.'
    } else if (!/[!@#$%^&*]/.test(formData.password)) {
      errors.password = 'Password must contain a special character (!@#$%^&*).'
    }

    if (!formData.confirmPassword) {
      errors.confirmPassword = 'Confirm Password is required.'
    } else if (formData.password !== formData.confirmPassword) {
      errors.confirmPassword = 'Passwords do not match.'
    }

    setValidationErrors(errors)
    return Object.keys(errors).length === 0
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    setValidationErrors({})

    if (!validateForm()) {
      setLoading(false)
      return
    }

    try {
      const authService = AuthService.getInstance()
      await authService.signUp({
        email: formData.email,
        password: formData.password,
        metadata: {
          full_name: formData.fullName,
          phone: formData.phone,
          state: formData.state,
          district: formData.district,
          region: formData.region
        }
      })
      onSuccess?.()
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Sign up failed. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData(prev => ({
      ...prev,
      [e.target.name]: e.target.value
    }))
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="w-full max-w-md mx-auto"
    >
      <div className="bg-white rounded-xl shadow-lg p-8">
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold text-gray-900 mb-2">Create Account</h2>
          <p className="text-gray-600">Join Krishi Sahayak and start your farming journey</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {error && (
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              className="bg-red-50 border border-red-200 rounded-lg p-4"
            >
              <p className="text-red-700 text-sm">{error}</p>
            </motion.div>
          )}

          <div>
            <label htmlFor="fullName" className="block text-sm font-medium text-gray-700 mb-2">
              Full Name
            </label>
            <div className="relative">
              <User className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="text"
                id="fullName"
                name="fullName"
                value={formData.fullName}
                onChange={handleInputChange}
                required
                className={`w-full pl-10 pr-4 py-3 border ${validationErrors.fullName ? 'border-red-500' : 'border-gray-300'} rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors placeholder:text-gray-500`}
                placeholder="Enter your full name"
              />
            </div>
            {validationErrors.fullName && <p className="mt-2 text-sm text-red-600">{validationErrors.fullName}</p>}
          </div>

          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
              Email Address
            </label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="email"
                id="email"
                name="email"
                value={formData.email}
                onChange={handleInputChange}
                required
                className={`w-full pl-10 pr-4 py-3 border ${validationErrors.email ? 'border-red-500' : 'border-gray-300'} rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors placeholder:text-gray-500`}
                placeholder="Enter your email"
              />
            </div>
            {validationErrors.email && <p className="mt-2 text-sm text-red-600">{validationErrors.email}</p>}
          </div>

          <div>
            <label htmlFor="phone" className="block text-sm font-medium text-gray-700 mb-2">
              Phone Number (Optional)
            </label>
            <div className="relative">
              <Phone className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="tel"
                id="phone"
                name="phone"
                value={formData.phone}
                onChange={handleInputChange}
                className={`w-full pl-10 pr-4 py-3 border ${validationErrors.phone ? 'border-red-500' : 'border-gray-300'} rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors placeholder:text-gray-500`}
                placeholder="Enter your phone number"
              />
            </div>
            {validationErrors.phone && <p className="mt-2 text-sm text-red-600">{validationErrors.phone}</p>}
          </div>

          {/* Region Selection */}
          <RegionSelector
            selectedState={formData.state}
            selectedDistrict={formData.district}
            onStateChange={(state) => setFormData(prev => ({ ...prev, state }))}
            onDistrictChange={(district) => setFormData(prev => ({ ...prev, district }))}
            onRegionChange={(region) => setFormData(prev => ({ ...prev, region }))}
            required={true}
            label="Location"
          />
          {(validationErrors.state || validationErrors.district) && (
            <div className="space-y-1">
              {validationErrors.state && <p className="text-sm text-red-600">{validationErrors.state}</p>}
              {validationErrors.district && <p className="text-sm text-red-600">{validationErrors.district}</p>}
            </div>
          )}

          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
              Password
            </label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type={showPassword ? 'text' : 'password'}
                id="password"
                name="password"
                value={formData.password}
                onChange={handleInputChange}
                required
                className={`w-full pl-10 pr-12 py-3 border ${validationErrors.password ? 'border-red-500' : 'border-gray-300'} rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors placeholder:text-gray-500`}
                placeholder="Create a password"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
            {validationErrors.password && <p className="mt-2 text-sm text-red-600">{validationErrors.password}</p>}
          </div>

          <div>
            <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 mb-2">
              Confirm Password
            </label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type={showConfirmPassword ? 'text' : 'password'}
                id="confirmPassword"
                name="confirmPassword"
                value={formData.confirmPassword}
                onChange={handleInputChange}
                required
                className={`w-full pl-10 pr-12 py-3 border ${validationErrors.confirmPassword ? 'border-red-500' : 'border-gray-300'} rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors placeholder:text-gray-500`}
                placeholder="Confirm your password"
              />
              <button
                type="button"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
              >
                {showConfirmPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
            {validationErrors.confirmPassword && <p className="mt-2 text-sm text-red-600">{validationErrors.confirmPassword}</p>}
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-green-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-green-700 focus:ring-2 focus:ring-green-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center"
          >
            {loading ? (
              <>
                <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                Creating Account...
              </>
            ) : (
              'Create Account'
            )}
          </button>
        </form>

        <div className="mt-6 text-center">
          <p className="text-gray-600">
            Already have an account?{' '}
            <button
              onClick={onSwitchToLogin}
              className="text-green-600 hover:text-green-700 font-medium transition-colors"
            >
              Sign in here
            </button>
          </p>
        </div>
      </div>
    </motion.div>
  )
}
