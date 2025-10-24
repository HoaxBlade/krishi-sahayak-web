'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { 
  Drone,
  MapPin,
  Clock,
  DollarSign,
  Camera,
  Shield,
  CheckCircle,
  AlertTriangle,
  Upload,
  X
} from 'lucide-react'
import Link from 'next/link'
import Image from 'next/image'
import ProtectedRoute from '@/components/ProtectedRoute'
import { useAuth } from '@/contexts/AuthContext'
import DroneServiceAPI, { DroneService } from '@/lib/droneServiceAPI'


const serviceTypes = [
  'Crop Monitoring',
  'Pest Detection',
  'Spraying Services',
  'Mapping & Surveying',
  'Weather Monitoring',
  'Livestock Monitoring',
  'Custom Services'
]

const features = [
  'High Resolution Camera',
  'Thermal Imaging',
  'GPS Navigation',
  'Real-time Data Transmission',
  'Weather Resistant',
  'Long Flight Time',
  'Automated Flight Path',
  'Emergency Landing',
  'Insurance Coverage',
  'Certified Pilot'
]

export default function DronePage() {
  const { user } = useAuth()
  const droneServiceAPI = DroneServiceAPI.getInstance()
  const [formData, setFormData] = useState<DroneService>({
    name: '',
    description: '',
    serviceType: '',
    pricePerHour: 0,
    coverageArea: '',
    availability: '',
    features: [],
    images: [] as File[],
    contactInfo: {
      phone: '',
      email: user?.email || ''
    },
    location: {
      address: '',
      city: '',
      state: '',
      pincode: ''
    }
  })

  const [isSubmitting, setIsSubmitting] = useState(false)
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'success' | 'error'>('idle')
  const [errorMessage, setErrorMessage] = useState('')

  const handleInputChange = (field: string, value: string | number) => {
    if (field.includes('.')) {
      const [parent, child] = field.split('.')
      setFormData(prev => ({
        ...prev,
        [parent]: {
          ...(prev[parent as keyof DroneService] as Record<string, unknown>),
          [child]: value
        }
      }))
    } else {
      setFormData(prev => ({
        ...prev,
        [field]: value
      }))
    }
  }

  const handleFeatureToggle = (feature: string) => {
    setFormData(prev => ({
      ...prev,
      features: prev.features.includes(feature)
        ? prev.features.filter(f => f !== feature)
        : [...prev.features, feature]
    }))
  }

  const handleImageUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || [])
    setFormData(prev => ({
      ...prev,
      images: [...(prev.images as File[]), ...files]
    }))
  }

  const removeImage = (index: number) => {
    setFormData(prev => ({
      ...prev,
      images: (prev.images as File[]).filter((_, i) => i !== index)
    }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)
    setSubmitStatus('idle')

    try {
      // Validate required fields
      if (!formData.name || !formData.description || !formData.serviceType || !formData.pricePerHour || !formData.coverageArea || !formData.availability) {
        setErrorMessage('Please fill in all required fields')
        setSubmitStatus('error')
        return
      }

      // Convert File objects to base64 strings for storage
      const imagePromises = (formData.images as File[]).map(file => {
        return new Promise<string>((resolve) => {
          const reader = new FileReader()
          reader.onload = () => resolve(reader.result as string)
          reader.readAsDataURL(file)
        })
      })
      
      const imageUrls = await Promise.all(imagePromises)

      // Prepare data for API
      const serviceData: DroneService = {
        ...formData,
        images: imageUrls
      }

      // Submit to Supabase
      await droneServiceAPI.createService(serviceData)
      
      setSubmitStatus('success')
      
      // Reset form
      setFormData({
        name: '',
        description: '',
        serviceType: '',
        pricePerHour: 0,
        coverageArea: '',
        availability: '',
        features: [],
        images: [] as File[],
        contactInfo: {
          phone: '',
          email: user?.email || ''
        },
        location: {
          address: '',
          city: '',
          state: '',
          pincode: ''
        }
      })
    } catch (error) {
      console.error('Error submitting drone service:', error)
      setErrorMessage(error instanceof Error ? error.message : 'Failed to submit drone service')
      setSubmitStatus('error')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <ProtectedRoute>
      <style jsx>{`
        input[type="text"]::placeholder,
        input[type="email"]::placeholder,
        input[type="tel"]::placeholder,
        input[type="number"]::placeholder,
        textarea::placeholder,
        select option:first-child {
          color: #6B7280 !important;
        }
        select {
          color: #000000 !important;
        }
        input, textarea, select {
          color: #000000 !important;
        }
      `}</style>
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-green-100">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          {/* Header */}
          <motion.div
            className="text-center mb-10"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
            <div className="flex items-center justify-center mb-4">
              <Drone className="w-12 h-12 text-green-600 mr-3" />
              <h1 className="text-4xl font-bold text-gray-900">Add Drone Service</h1>
            </div>
            <p className="text-lg text-gray-600 max-w-2xl mx-auto">
              Register your drone services to help farmers with precision agriculture, 
              crop monitoring, and aerial surveying.
            </p>
            <div className="mt-4">
              <Link 
                href="/dashboard"
                className="inline-flex items-center text-green-600 hover:text-green-700 font-medium"
              >
                ← Back to Dashboard
              </Link>
            </div>
          </motion.div>

          {/* Form */}
          <motion.div
            className="bg-white rounded-xl shadow-lg p-8"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
          >
            <form onSubmit={handleSubmit} className="space-y-8">
              {/* Basic Information */}
              <div>
                <h2 className="text-xl font-semibold text-gray-900 mb-6 flex items-center">
                  <Drone className="w-6 h-6 mr-2 text-green-600" />
                  Basic Information
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Service Name *
                    </label>
                    <input
                      type="text"
                      required
                      value={formData.name}
                      onChange={(e) => handleInputChange('name', e.target.value)}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent placeholder:text-gray-900"
                      placeholder="e.g., Precision Crop Monitoring"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Service Type *
                    </label>
                    <select
                      required
                      value={formData.serviceType}
                      onChange={(e) => handleInputChange('serviceType', e.target.value)}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent placeholder:text-gray-900"
                    >
                      <option value="">Select Service Type</option>
                      {serviceTypes.map(type => (
                        <option key={type} value={type}>{type}</option>
                      ))}
                    </select>
                  </div>
                </div>
                <div className="mt-6">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Description *
                  </label>
                  <textarea
                    required
                    rows={4}
                    value={formData.description}
                    onChange={(e) => handleInputChange('description', e.target.value)}
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent placeholder:text-gray-900"
                    placeholder="Describe your drone service capabilities, experience, and what makes you unique..."
                  />
                </div>
              </div>

              {/* Pricing & Availability */}
              <div>
                <h2 className="text-xl font-semibold text-gray-900 mb-6 flex items-center">
                  <DollarSign className="w-6 h-6 mr-2 text-green-600" />
                  Pricing & Availability
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Price per Hour (₹) *
                    </label>
                    <input
                      type="text"
                      required
                      pattern="[0-9]*"
                      value={formData.pricePerHour === 0 ? '' : formData.pricePerHour.toString()}
                      onChange={(e) => {
                        const value = e.target.value.replace(/[^0-9]/g, '')
                        handleInputChange('pricePerHour', value === '' ? 0 : parseFloat(value))
                      }}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent placeholder:text-gray-900"
                      placeholder="1500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Coverage Area (km²) *
                    </label>
                    <input
                      type="text"
                      required
                      pattern="[0-9]*"
                      value={formData.coverageArea}
                      onChange={(e) => {
                        const value = e.target.value.replace(/[^0-9]/g, '')
                        handleInputChange('coverageArea', value)
                      }}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent placeholder:text-gray-900"
                      placeholder="50"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Availability *
                    </label>
                    <select
                      required
                      value={formData.availability}
                      onChange={(e) => handleInputChange('availability', e.target.value)}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent placeholder:text-gray-900"
                    >
                      <option value="">Select Availability</option>
                      <option value="24/7">24/7 Available</option>
                      <option value="Business Hours">Business Hours Only</option>
                      <option value="Weekdays">Weekdays Only</option>
                      <option value="Weekends">Weekends Only</option>
                      <option value="On Request">On Request</option>
                    </select>
                  </div>
                </div>
              </div>

              {/* Features */}
              <div>
                <h2 className="text-xl font-semibold text-gray-900 mb-6 flex items-center">
                  <Shield className="w-6 h-6 mr-2 text-purple-600" />
                  Service Features
                </h2>
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
                  {features.map(feature => (
                    <label key={feature} className="flex items-center space-x-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={formData.features.includes(feature)}
                        onChange={() => handleFeatureToggle(feature)}
                        className="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                      />
                      <span className="text-sm text-gray-700">{feature}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Location */}
              <div>
                <h2 className="text-xl font-semibold text-gray-900 mb-6 flex items-center">
                  <MapPin className="w-6 h-6 mr-2 text-red-600" />
                  Service Location
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="md:col-span-2">
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Full Address *
                    </label>
                    <input
                      type="text"
                      required
                      value={formData.location.address}
                      onChange={(e) => handleInputChange('location.address', e.target.value)}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent placeholder:text-gray-900"
                      placeholder="Street address, landmark..."
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      City *
                    </label>
                    <input
                      type="text"
                      required
                      value={formData.location.city}
                      onChange={(e) => handleInputChange('location.city', e.target.value)}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent placeholder:text-gray-900"
                      placeholder="Mumbai"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      State *
                    </label>
                    <input
                      type="text"
                      required
                      value={formData.location.state}
                      onChange={(e) => handleInputChange('location.state', e.target.value)}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent placeholder:text-gray-900"
                      placeholder="Maharashtra"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Pincode *
                    </label>
                    <input
                      type="text"
                      required
                      value={formData.location.pincode}
                      onChange={(e) => handleInputChange('location.pincode', e.target.value)}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent placeholder:text-gray-900"
                      placeholder="400001"
                    />
                  </div>
                </div>
              </div>

              {/* Contact Information */}
              <div>
                <h2 className="text-xl font-semibold text-gray-900 mb-6 flex items-center">
                  <Clock className="w-6 h-6 mr-2 text-orange-600" />
                  Contact Information
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Phone Number *
                    </label>
                    <input
                      type="tel"
                      required
                      value={formData.contactInfo.phone}
                      onChange={(e) => handleInputChange('contactInfo.phone', e.target.value)}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent placeholder:text-gray-900"
                      placeholder="+91 9876543210"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Email Address *
                    </label>
                    <input
                      type="email"
                      required
                      value={formData.contactInfo.email}
                      onChange={(e) => handleInputChange('contactInfo.email', e.target.value)}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent placeholder:text-gray-900"
                      placeholder="your@email.com"
                    />
                  </div>
                </div>
              </div>

              {/* Image Upload */}
              <div>
                <h2 className="text-xl font-semibold text-gray-900 mb-6 flex items-center">
                  <Camera className="w-6 h-6 mr-2 text-indigo-600" />
                  Service Images
                </h2>
                <div className="border-2 border-dashed border-gray-300 rounded-lg p-6">
                  <div className="text-center">
                    <Upload className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                    <p className="text-gray-600 mb-4">Upload images of your drone and previous work</p>
                    <input
                      type="file"
                      multiple
                      accept="image/*"
                      onChange={handleImageUpload}
                      className="hidden"
                      id="image-upload"
                    />
                    <label
                      htmlFor="image-upload"
                      className="inline-flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 cursor-pointer"
                    >
                      <Upload className="w-4 h-4 mr-2" />
                      Choose Images
                    </label>
                  </div>
                  {formData.images.length > 0 && (
                    <div className="mt-6 grid grid-cols-2 md:grid-cols-4 gap-4">
                      {formData.images.map((image, index) => (
                        <div key={index} className="relative">
                          <Image
                            src={typeof image === 'string' ? image : URL.createObjectURL(image)}
                            alt={`Upload ${index + 1}`}
                            width={96}
                            height={96}
                            className="w-full h-24 object-cover rounded-lg"
                            style={{ width: 'auto', height: 'auto' }}
                          />
                          <button
                            type="button"
                            onClick={() => removeImage(index)}
                            className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600"
                          >
                            <X className="w-3 h-3" />
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              {/* Submit Button */}
              <div className="flex justify-center pt-6">
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="w-full md:w-auto bg-green-600 text-white px-8 py-4 rounded-lg font-semibold hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center space-x-2"
                >
                  {isSubmitting ? (
                    <>
                      <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                      <span>Submitting...</span>
                    </>
                  ) : (
                    <>
                      <Drone className="w-5 h-5" />
                      <span>Register Drone Service</span>
                    </>
                  )}
                </button>
              </div>

              {/* Status Messages */}
              {submitStatus === 'success' && (
                <motion.div
                  className="bg-green-50 border border-green-200 rounded-lg p-4 flex items-center"
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                >
                  <CheckCircle className="w-5 h-5 text-green-600 mr-3" />
                  <p className="text-green-800">Drone service registered successfully!</p>
                </motion.div>
              )}

              {submitStatus === 'error' && (
                <motion.div
                  className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-center"
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                >
                  <AlertTriangle className="w-5 h-5 text-red-600 mr-3" />
                  <p className="text-red-800">{errorMessage || 'Failed to register drone service. Please try again.'}</p>
                </motion.div>
              )}
            </form>
          </motion.div>
        </div>
      </div>
    </ProtectedRoute>
  )
}
