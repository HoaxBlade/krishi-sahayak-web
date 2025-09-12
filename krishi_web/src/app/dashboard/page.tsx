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
        
        const [mlStatus, weatherData] = await Promise.all([
          mlService.getServerStatus(),
          weatherService.getWeatherByCity('Delhi')
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
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <Link href="/" className="flex items-center space-x-2 text-gray-600 hover:text-gray-900">
              <ArrowLeft className="w-5 h-5" />
              <span>Back to Home</span>
            </Link>
            <div className="flex items-center space-x-2">
              <Leaf className="w-8 h-8 text-green-600" />
              <span className="text-2xl font-bold text-gray-900">Krishi Sahayak</span>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">
            Farming Dashboard
          </h1>
          <p className="text-xl text-gray-600">
            Monitor your agricultural operations and AI insights
          </p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {stats.map((stat, index) => (
            <motion.div
              key={stat.title}
              className="bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{stat.title}</p>
                  <p className="text-3xl font-bold text-gray-900">{stat.value}</p>
                </div>
                <div className={`p-3 rounded-full ${
                  stat.changeType === 'positive' ? 'bg-green-100' : 'bg-red-100'
                }`}>
                  <stat.icon className={`w-6 h-6 ${
                    stat.changeType === 'positive' ? 'text-green-600' : 'text-red-600'
                  }`} />
                </div>
              </div>
              <div className="mt-4 flex items-center">
                <span className={`text-sm font-medium ${
                  stat.changeType === 'positive' ? 'text-green-600' : 'text-red-600'
                }`}>
                  {stat.change}
                </span>
                <span className="text-sm text-gray-500 ml-2">from last month</span>
              </div>
            </motion.div>
          ))}
        </div>

        <div className="grid lg:grid-cols-3 gap-8">
          {/* Recent Analyses */}
          <motion.div 
            className="lg:col-span-2 bg-white rounded-xl shadow-lg p-6"
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5 }}
          >
            <h2 className="text-2xl font-semibold text-gray-900 mb-6">
              Recent Crop Analyses
            </h2>
            
            <div className="space-y-4">
              {recentAnalyses.map((analysis) => (
                <div key={analysis.id} className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                  <div className="flex items-center space-x-4">
                    <div className={`w-3 h-3 rounded-full ${
                      analysis.status === 'Healthy' ? 'bg-green-500' : 'bg-red-500'
                    }`} />
                    <div>
                      <p className="font-medium text-gray-900">{analysis.crop}</p>
                      <p className="text-sm text-gray-600">{analysis.location}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="font-medium text-gray-900">{analysis.status}</p>
                    <p className="text-sm text-gray-600">{analysis.confidence}% confidence</p>
                  </div>
                  <div className="text-sm text-gray-500">
                    {analysis.date}
                  </div>
                </div>
              ))}
            </div>
            
            <div className="mt-6">
              <Link 
                href="/analyze"
                className="inline-flex items-center text-green-600 hover:text-green-700 font-medium"
              >
                Analyze New Crop
                <BarChart3 className="w-4 h-4 ml-2" />
              </Link>
            </div>
          </motion.div>

          {/* System Status & Weather */}
          <div className="space-y-6">
            {/* System Status */}
            <motion.div 
              className="bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5 }}
            >
              <h3 className="text-xl font-semibold text-gray-900 mb-4">
                System Status
              </h3>
              
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">ML Server</span>
                  <div className="flex items-center space-x-2">
                    <div className={`w-2 h-2 rounded-full ${
                      mlStatus?.healthy ? 'bg-green-500' : 'bg-red-500'
                    }`} />
                    <span className="text-sm font-medium">
                      {mlStatus?.healthy ? 'Online' : 'Offline'}
                    </span>
                  </div>
                </div>
                
                {mlStatus?.error && (
                  <div className="mt-2 p-2 bg-red-50 border border-red-200 rounded text-xs text-red-700">
                    {mlStatus.error}
                  </div>
                )}
                
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">Response Time</span>
                  <span className="text-sm font-medium">
                    {mlStatus?.responseTime || 0}ms
                  </span>
                </div>
                
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">Weather API</span>
                  <div className="flex items-center space-x-2">
                    <div className="w-2 h-2 rounded-full bg-green-500" />
                    <span className="text-sm font-medium">Online</span>
                  </div>
                </div>
              </div>
            </motion.div>

            {/* Weather Summary */}
            {weather && (
              <motion.div 
                className="bg-white rounded-xl shadow-lg p-6"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.5, delay: 0.1 }}
              >
                <h3 className="text-xl font-semibold text-gray-900 mb-4">
                  Current Weather
                </h3>
                
                <div className="text-center mb-4">
                  <div className="text-4xl mb-2">
                    {WeatherService.getInstance().getWeatherIcon(weather.description)}
                  </div>
                  <p className="text-2xl font-bold text-gray-900">{weather.temperature}°C</p>
                  <p className="text-gray-600 capitalize">{weather.description}</p>
                  <p className="text-sm text-gray-500">{weather.location}</p>
                </div>
                
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="text-gray-500">Humidity</span>
                    <p className="font-medium">{weather.humidity}%</p>
                  </div>
                  <div>
                    <span className="text-gray-500">Wind</span>
                    <p className="font-medium">{weather.windSpeed} m/s</p>
                  </div>
                </div>
              </motion.div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
