'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { 
  BarChart3, 
  Activity, 
  Leaf,
  AlertTriangle,
  CheckCircle
} from 'lucide-react'
import Link from 'next/link'
import { ArrowLeft } from 'lucide-react'
import { MLService } from '@/lib/mlService'
import { WeatherService } from '@/lib/weatherService'

export default function DashboardPage() {
  const [mlStatus, setMlStatus] = useState<{
    healthy: boolean
    responseTime: number
    timestamp: string
    error?: string
  } | null>(null)
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

  useEffect(() => {
    const fetchData = async () => {
      try {
        const mlService = MLService.getInstance()
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

        const [mlStatus, weatherData] = await Promise.all([
          mlService.getServerStatus(),
          weatherDataPromise
        ])
        
        setMlStatus(mlStatus)
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

  const recentAnalyses = [
    {
      id: 1,
      crop: 'Tomato',
      status: 'Healthy',
      confidence: 94,
      date: '2024-01-15',
      location: 'Field A'
    },
    {
      id: 2,
      crop: 'Wheat',
      status: 'Diseased',
      confidence: 87,
      date: '2024-01-14',
      location: 'Field B'
    },
    {
      id: 3,
      crop: 'Rice',
      status: 'Healthy',
      confidence: 92,
      date: '2024-01-13',
      location: 'Field C'
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
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="mb-7"> {/* Adjusted margin */}
          <h1 className="text-3xl font-bold text-gray-900 mb-3"> {/* Adjusted text size and margin */}
            Farming Dashboard
          </h1>
          <p className="text-lg text-gray-600"> {/* Adjusted text size */}
            Monitor your agricultural operations and AI insights
          </p>
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
          {/* Recent Analyses */}
          <motion.div
            className="lg:col-span-2 bg-white rounded-xl shadow-subtle p-5" /* Refined card style */
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5 }}
          >
            <h2 className="text-xl font-semibold text-gray-900 mb-5"> {/* Adjusted text size and margin */}
              Recent Crop Analyses
            </h2>
            
            <div className="space-y-3"> {/* Adjusted spacing */}
              {recentAnalyses.map((analysis) => (
                <motion.div
                  key={analysis.id}
                  className="flex items-center justify-between p-3.5 border border-gray-100 rounded-lg"
                  whileHover={{ scale: 1.01, backgroundColor: "#f0f0f0", boxShadow: "0 5px 10px rgba(0, 0, 0, 0.05)" }}
                  transition={{ type: "spring", stiffness: 400, damping: 10 }}
                >
                  <div className="flex items-center space-x-4">
                    <div className={`w-2.5 h-2.5 rounded-full ${
                      analysis.status === 'Healthy' ? 'bg-green-500' : 'bg-red-500'
                    }`} />
                    <div>
                      <p className="font-medium text-gray-800">{analysis.crop}</p>
                      <p className="text-xs text-gray-500">{analysis.location}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="font-medium text-gray-800">{analysis.status}</p>
                    <p className="text-xs text-gray-500">{analysis.confidence}% confidence</p>
                  </div>
                  <div className="text-xs text-gray-400">
                    {analysis.date}
                  </div>
                </motion.div>
              ))}
            </div>
            
            <div className="mt-5"> {/* Adjusted margin */}
              <Link
                href="/analyze"
                className="inline-flex items-center text-green-600 hover:text-green-700 font-semibold text-sm transition-all hover:scale-[1.02]"
              >
                Analyze New Crop
                <BarChart3 className="w-3.5 h-3.5 ml-2" />
              </Link>
            </div>
          </motion.div>

          {/* System Status & Weather */}
          <div className="space-y-5"> {/* Adjusted spacing */}
            {/* System Status */}
            <motion.div
              className="bg-white rounded-xl shadow-subtle p-5"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              whileHover={{ scale: 1.02, boxShadow: "0 10px 20px rgba(0, 0, 0, 0.08)" }}
              transition={{ duration: 0.5, type: "spring", stiffness: 100 }}
            >
              <h3 className="text-lg font-semibold text-gray-900 mb-3">System Status</h3>
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-gray-500 text-sm">ML Server</span>
                  <div className="flex items-center space-x-2">
                    <div className={`w-2 h-2 rounded-full ${mlStatus?.healthy ? 'bg-green-500' : 'bg-red-500'}`} />
                    <span className="text-xs font-medium">{mlStatus?.healthy ? 'Online' : 'Offline'}</span>
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-gray-500 text-sm">Weather API</span>
                  <div className="flex items-center space-x-2">
                    <div className={`w-2 h-2 rounded-full ${weather ? 'bg-green-500' : 'bg-red-500'}`} />
                    <span className="text-xs font-medium">{weather ? 'Connected' : 'Disconnected'}</span>
                  </div>
                </div>
                <Link href="/" className="text-sm text-green-600 hover:text-green-700 font-medium mt-2 block transition-all hover:scale-[1.02]">
                  View Full Status
                </Link>
              </div>
            </motion.div>

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
      </div>
    </div>
  )
}

