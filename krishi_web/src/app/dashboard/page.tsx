'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { 
  Activity, 
  Leaf,
  AlertTriangle,
  CheckCircle,
  User,
  Plus
} from 'lucide-react'
import Link from 'next/link'
import { WeatherService } from '@/lib/weatherService'
import ProtectedRoute from '@/components/ProtectedRoute'
import { useAuth } from '@/contexts/AuthContext'
import AddProductModal from '@/components/AddProductModal'

export default function DashboardPage() {
  const { user } = useAuth()
  const [weather, setWeather] = useState<{
    temperature: number
    humidity: number
    precipitation: number
    windSpeed: number
    description: string
    location: string
    timestamp: string
  } | null>(null)
  const [loading, setLoading] = useState(true)
  const [showAddProductModal, setShowAddProductModal] = useState(false)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const weatherService = WeatherService.getInstance()
        
        let weatherDataPromise;
        const storedLocation = localStorage.getItem('userWeatherLocation');
        if (storedLocation) {
          const { latitude, longitude, location } = JSON.parse(storedLocation);
          if (latitude && longitude) {
            weatherDataPromise = weatherService.getWeatherByCoordinates(latitude, longitude);
          } else if (location) {
            weatherDataPromise = weatherService.getWeatherByCity(location);
          } else {
            weatherDataPromise = weatherService.getWeatherByCity('Delhi');
          }
        } else {
          weatherDataPromise = weatherService.getWeatherByCity('Delhi');
        }

        const weatherData = await weatherDataPromise
        setWeather(weatherData)
      } catch (error) {
        console.error('Dashboard data fetch failed:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [])

  const stats = [
    {
      title: 'Crops Analyzed',
      value: '1,247',
      change: '+12%',
      changeType: 'positive',
      icon: Leaf
    },
    {
      title: 'Healthy Crops',
      value: '89%',
      change: '+5%',
      changeType: 'positive',
      icon: CheckCircle
    },
    {
      title: 'Diseases Detected',
      value: '23',
      change: '-8%',
      changeType: 'negative',
      icon: AlertTriangle
    },
    {
      title: 'Active Users',
      value: '456',
      change: '+18%',
      changeType: 'positive',
      icon: Activity
    }
  ]


  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    )
  }

  return (
    <ProtectedRoute>
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="mb-7"> {/* Adjusted margin */}
          <div className="flex justify-between items-start mb-3">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 mb-2"> {/* Adjusted text size and margin */}
                Farming Dashboard
              </h1>
              <p className="text-lg text-gray-600"> {/* Adjusted text size */}
                Monitor your agricultural operations and AI insights
              </p>
            </div>
            <div className="flex items-center space-x-3">
              <button 
                onClick={() => setShowAddProductModal(true)}
                className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors flex items-center"
              >
                <Plus className="w-4 h-4 mr-2" />
                Add Product
              </button>
              <Link
                href="/profile"
                className="flex items-center space-x-2 text-gray-600 hover:text-gray-900 transition-colors px-3 py-2 rounded-lg hover:bg-gray-100"
              >
                <User className="w-5 h-5" />
                <span className="text-sm">
                  Hi {user?.user_metadata?.full_name || user?.email?.split('@')[0] || 'User'}
                </span>
              </Link>
            </div>
          </div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5 mb-7"> {/* Adjusted gap and margin */}
          {stats.map((stat, index) => (
            <motion.div
              key={stat.title}
              className="bg-white rounded-xl shadow-subtle p-5"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              whileHover={{ scale: 1.02, boxShadow: "0 10px 20px rgba(0, 0, 0, 0.08)" }}
              transition={{ duration: 0.5, delay: index * 0.1, type: "spring", stiffness: 100 }}
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs font-medium text-gray-500">{stat.title}</p> {/* Adjusted text size and color */}
                  <p className="text-2xl font-semibold text-gray-800">{stat.value}</p> {/* Adjusted text size and weight */}
                </div>
                <div className={`p-2.5 rounded-full ${ /* Adjusted padding */
                  stat.changeType === 'positive' ? 'bg-green-100' : 'bg-red-100'
                }`}>
                  <stat.icon className={`w-5 h-5 ${ /* Adjusted icon size */
                    stat.changeType === 'positive' ? 'text-green-600' : 'text-red-600'
                  }`} />
                </div>
              </div>
              <div className="mt-3 flex items-center"> {/* Adjusted margin */}
                <span className={`text-xs font-medium ${ /* Adjusted text size */
                  stat.changeType === 'positive' ? 'text-green-600' : 'text-red-600'
                }`}>
                  {stat.change}
                </span>
                <span className="text-xs text-gray-400 ml-2">from last month</span> {/* Adjusted text size and color */}
              </div>
            </motion.div>
          ))}
        </div>

        <div className="grid lg:grid-cols-3 gap-7"> {/* Adjusted gap */}
          {/* Weather Summary */}
            {weather && (
              <motion.div
                className="bg-white rounded-xl shadow-subtle p-5"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                whileHover={{ scale: 1.02, boxShadow: "0 10px 20px rgba(0, 0, 0, 0.08)" }}
                transition={{ duration: 0.5, delay: 0.1, type: "spring", stiffness: 100 }}
              >
                <h3 className="text-lg font-semibold text-gray-900 mb-3">Current Weather</h3>
                <div className="text-center mb-3">
                  <p className="text-xl font-bold text-gray-900">{weather.temperature}°C</p>
                  <p className="text-gray-500 capitalize text-sm">{weather.description}</p>
                  <p className="text-xs text-gray-400">{weather.location}</p>
                </div>
                <Link href="/weather" className="text-sm text-green-600 hover:text-green-700 font-medium mt-2 block transition-all hover:scale-[1.02]">
                  View Full Forecast
                </Link>
              </motion.div>
            )}
          </div>
        </div>

        {/* Add Product Modal */}
        <AddProductModal 
          isOpen={showAddProductModal}
          onClose={() => setShowAddProductModal(false)}
        />
      </div>
    </ProtectedRoute>
  )
}

