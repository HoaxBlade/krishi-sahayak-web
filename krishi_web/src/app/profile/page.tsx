'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { 
  User, 
  Mail, 
  Calendar, 
  Phone, 
  Edit3, 
  LogOut, 
  Save,
  X,
  MapPin
} from 'lucide-react'
import ProtectedRoute from '@/components/ProtectedRoute'
import { useAuth } from '@/contexts/AuthContext'
import RegionSelector from '@/components/RegionSelector'

export default function ProfilePage() {
  const { user, signOut, updateProfile } = useAuth()
  const [isEditing, setIsEditing] = useState(false)
  const [loading, setLoading] = useState(false)
  const [editData, setEditData] = useState({
    full_name: user?.user_metadata?.full_name || '',
    phone: user?.user_metadata?.phone || '',
    state: user?.user_metadata?.state || '',
    district: user?.user_metadata?.district || '',
    region: user?.user_metadata?.region || ''
  })

  const handleEdit = () => {
    setIsEditing(true)
    setEditData({
      full_name: user?.user_metadata?.full_name || '',
      phone: user?.user_metadata?.phone || '',
      state: user?.user_metadata?.state || '',
      district: user?.user_metadata?.district || '',
      region: user?.user_metadata?.region || ''
    })
  }

  const handleSave = async () => {
    setLoading(true)
    try {
      await updateProfile(editData)
      setIsEditing(false)
    } catch (error) {
      console.error('Failed to update profile:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCancel = () => {
    setIsEditing(false)
    setEditData({
      full_name: user?.user_metadata?.full_name || '',
      phone: user?.user_metadata?.phone || '',
      state: user?.user_metadata?.state || '',
      district: user?.user_metadata?.district || '',
      region: user?.user_metadata?.region || ''
    })
  }

  const handleSignOut = async () => {
    try {
      await signOut()
    } catch (error) {
      console.error('Failed to sign out:', error)
    }
  }

  return (
    <ProtectedRoute>
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="bg-white rounded-xl shadow-lg p-8"
          >
            {/* Profile Header */}
            <div className="text-center mb-8">
              <div className="w-24 h-24 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <User className="w-12 h-12 text-green-600" />
              </div>
              <h1 className="text-3xl font-bold text-gray-900 mb-2">
                {user?.user_metadata?.full_name || user?.email?.split('@')[0] || 'User'}
              </h1>
              <p className="text-gray-600">Manage your account settings</p>
            </div>

            {/* Profile Information */}
            <div className="space-y-6">
              {/* Email */}
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center space-x-3">
                  <Mail className="w-5 h-5 text-black" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Email</p>
                    <p className="text-gray-900 break-all">{user?.email}</p>
                  </div>
                </div>
                <span className="text-xs text-gray-500 bg-gray-200 px-2 py-1 rounded flex-shrink-0 ml-2">Verified</span>
              </div>

              {/* Full Name */}
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center space-x-3">
                  <User className="w-5 h-5 text-black" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Full Name</p>
                    {isEditing ? (
                      <input
                        type="text"
                        value={editData.full_name}
                        onChange={(e) => setEditData(prev => ({ ...prev, full_name: e.target.value }))}
                        className="mt-1 px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
                        placeholder="Enter your full name"
                      />
                    ) : (
                      <p className="text-gray-900">
                        {user?.user_metadata?.full_name || 'Not provided'}
                      </p>
                    )}
                  </div>
                </div>
              </div>

              {/* Phone */}
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center space-x-3">
                  <Phone className="w-5 h-5 text-black" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Phone</p>
                    {isEditing ? (
                      <input
                        type="tel"
                        value={editData.phone}
                        onChange={(e) => setEditData(prev => ({ ...prev, phone: e.target.value }))}
                        className="mt-1 px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
                        placeholder="Enter your phone number"
                      />
                    ) : (
                      <p className="text-gray-900">
                        {user?.user_metadata?.phone || 'Not provided'}
                      </p>
                    )}
                  </div>
                </div>
              </div>

              {/* Location */}
              <div className="p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center space-x-3 mb-4">
                  <MapPin className="w-5 h-5 text-black" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Location</p>
                    {!isEditing ? (
                      <div className="mt-1">
                        {user?.user_metadata?.state && user?.user_metadata?.district ? (
                          <div className="space-y-1">
                            <p className="text-gray-900 font-medium">
                              {user.user_metadata.district}, {user.user_metadata.state}
                            </p>
                            {user.user_metadata.region && (
                              <p className="text-sm text-gray-600">
                                {user.user_metadata.region} India
                              </p>
                            )}
                          </div>
                        ) : (
                          <p className="text-gray-500">Not provided</p>
                        )}
                      </div>
                    ) : (
                      <div className="mt-2">
                        <RegionSelector
                          selectedState={editData.state}
                          selectedDistrict={editData.district}
                          onStateChange={(state) => setEditData(prev => ({ ...prev, state }))}
                          onDistrictChange={(district) => setEditData(prev => ({ ...prev, district }))}
                          onRegionChange={(region) => setEditData(prev => ({ ...prev, region }))}
                          required={false}
                          label=""
                          className="mt-2"
                        />
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Account Created */}
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center space-x-3">
                  <Calendar className="w-5 h-5 text-black" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Member Since</p>
                    <p className="text-gray-900">
                      {user?.created_at ? new Date(user.created_at).toLocaleDateString('en-US', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                      }) : 'Unknown'}
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="mt-8 flex flex-col sm:flex-row gap-4 justify-center">
              {isEditing ? (
                <>
                  <button
                    onClick={handleSave}
                    disabled={loading}
                    className="flex items-center justify-center space-x-2 bg-green-600 text-white px-6 py-3 rounded-lg font-medium hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                  >
                    {loading ? (
                      <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    ) : (
                      <Save className="w-5 h-5" />
                    )}
                    <span>{loading ? 'Saving...' : 'Save Changes'}</span>
                  </button>
                  <button
                    onClick={handleCancel}
                    className="flex items-center justify-center space-x-2 bg-gray-500 text-white px-6 py-3 rounded-lg font-medium hover:bg-gray-600 transition-colors"
                  >
                    <X className="w-5 h-5" />
                    <span>Cancel</span>
                  </button>
                </>
              ) : (
                <button
                  onClick={handleEdit}
                  className="flex items-center justify-center space-x-2 bg-blue-600 text-white px-6 py-3 rounded-lg font-medium hover:bg-blue-700 transition-colors"
                >
                  <Edit3 className="w-5 h-5" />
                  <span>Edit Profile</span>
                </button>
              )}
            </div>

            {/* Sign Out Section */}
            <div className="mt-8 pt-8 border-t border-gray-200">
              <div className="text-center">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Account Actions</h3>
                <button
                  onClick={handleSignOut}
                  className="flex items-center justify-center space-x-2 bg-red-600 text-white px-6 py-3 rounded-lg font-medium hover:bg-red-700 transition-colors mx-auto"
                >
                  <LogOut className="w-5 h-5" />
                  <span>Sign Out</span>
                </button>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </ProtectedRoute>
  )
}
