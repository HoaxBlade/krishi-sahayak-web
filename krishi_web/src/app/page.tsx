'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { 
  Leaf, 
  Camera, 
  BarChart3, 
  Cloud, 
  Shield, 
  ArrowRight,
  CheckCircle
} from 'lucide-react'
import { MLService } from '@/lib/mlService'
import { WeatherService } from '@/lib/weatherService'

export default function HomePage() {
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

  useEffect(() => {
    const checkServices = async () => {
      try {
        const mlService = MLService.getInstance()
        const weatherService = WeatherService.getInstance()
        
        const [mlStatus, weatherData] = await Promise.all([
          mlService.getServerStatus(),
          weatherService.getWeatherByCity('Delhi') // Default location
        ])
        
        setMlStatus(mlStatus)
        setWeather(weatherData)
      } catch (error) {
        console.error('Service check failed:', error)
      }
    }

    checkServices()
  }, [])

  const features = [
    {
      icon: <Camera className="w-8 h-8" />,
      title: "AI-Powered Crop Analysis",
      description: "Upload crop images for instant health analysis using advanced machine learning"
    },
    {
      icon: <Cloud className="w-8 h-8" />,
      title: "Real-time Weather Data",
      description: "Get accurate weather forecasts and farming recommendations"
    },
    {
      icon: <BarChart3 className="w-8 h-8" />,
      title: "Crop Management",
      description: "Track your crops, planting dates, and harvest schedules"
    },
    {
      icon: <Shield className="w-8 h-8" />,
      title: "Disease Detection",
      description: "Early detection of plant diseases and pest infestations"
    }
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div className="flex items-center space-x-2">
              <Leaf className="w-8 h-8 text-green-600" />
              <span className="text-2xl font-bold text-gray-900">Krishi Sahayak</span>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <div className={`w-3 h-3 rounded-full ${mlStatus?.healthy ? 'bg-green-500' : 'bg-red-500'}`} />
                <span className="text-sm text-gray-600">
                  ML Server {mlStatus?.error ? '(Offline)' : ''}
                </span>
              </div>
              <button className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors">
                Get Started
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <motion.h1 
              className="text-5xl md:text-6xl font-bold text-gray-900 mb-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8 }}
            >
              Smart Farming with{' '}
              <span className="text-green-600">AI</span>
            </motion.h1>
            <motion.p 
              className="text-xl text-gray-600 mb-8 max-w-3xl mx-auto"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.2 }}
            >
              Revolutionize your farming with AI-powered crop analysis, 
              weather insights, and smart agricultural management tools.
            </motion.p>
            <motion.div 
              className="flex flex-col sm:flex-row gap-4 justify-center"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.4 }}
            >
              <button className="bg-green-600 text-white px-8 py-4 rounded-lg text-lg font-semibold hover:bg-green-700 transition-colors flex items-center justify-center">
                Analyze Your Crops
                <ArrowRight className="ml-2 w-5 h-5" />
              </button>
              <button className="border border-green-600 text-green-600 px-8 py-4 rounded-lg text-lg font-semibold hover:bg-green-50 transition-colors">
                Learn More
              </button>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Weather Card */}
      {weather && (
        <section className="py-8">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <motion.div 
              className="bg-white rounded-xl shadow-lg p-6 max-w-md mx-auto"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.5 }}
            >
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">{weather.location}</h3>
                  <p className="text-gray-600">{weather.description}</p>
                </div>
                <div className="text-4xl">{WeatherService.getInstance().getWeatherIcon(weather.description)}</div>
              </div>
              <div className="mt-4 grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="text-gray-500">Temperature</span>
                  <p className="font-semibold">{weather.temperature}°C</p>
                </div>
                <div>
                  <span className="text-gray-500">Humidity</span>
                  <p className="font-semibold">{weather.humidity}%</p>
                </div>
                <div>
                  <span className="text-gray-500">Wind</span>
                  <p className="font-semibold">{weather.windSpeed} m/s</p>
                </div>
                <div>
                  <span className="text-gray-500">Rain</span>
                  <p className="font-semibold">{weather.precipitation}mm</p>
                </div>
              </div>
            </motion.div>
          </div>
        </section>
      )}

      {/* Features Section */}
      <section className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">
              Powerful Features for Modern Farming
            </h2>
            <p className="text-xl text-gray-600">
              Everything you need to optimize your agricultural operations
            </p>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((feature, index) => (
              <motion.div
                key={index}
                className="text-center p-6 rounded-xl hover:shadow-lg transition-shadow"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
              >
                <div className="inline-flex items-center justify-center w-16 h-16 bg-green-100 text-green-600 rounded-full mb-4">
                  {feature.icon}
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">
                  {feature.title}
                </h3>
                <p className="text-gray-600">
                  {feature.description}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Status Section */}
      <section className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">
              System Status
            </h2>
            <p className="text-xl text-gray-600">
              Real-time monitoring of our AI services
            </p>
          </div>
          
          <div className="grid md:grid-cols-3 gap-8">
            <motion.div 
              className="bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
            >
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900">ML Server</h3>
                <CheckCircle className={`w-6 h-6 ${mlStatus?.healthy ? 'text-green-500' : 'text-red-500'}`} />
              </div>
              <p className="text-gray-600 mb-2">
                Status: {mlStatus?.healthy ? 'Healthy' : 'Unhealthy'}
              </p>
              <p className="text-gray-600">
                Response Time: {mlStatus?.responseTime || 0}ms
              </p>
            </motion.div>
            
            <motion.div 
              className="bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
            >
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900">Weather API</h3>
                <CheckCircle className="w-6 h-6 text-green-500" />
              </div>
              <p className="text-gray-600 mb-2">
                Status: {weather ? 'Connected' : 'Disconnected'}
              </p>
              <p className="text-gray-600">
                Location: {weather?.location || 'N/A'}
              </p>
            </motion.div>
            
            <motion.div 
              className="bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.2 }}
            >
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900">Database</h3>
                <CheckCircle className="w-6 h-6 text-green-500" />
              </div>
              <p className="text-gray-600 mb-2">
                Status: Connected
              </p>
              <p className="text-gray-600">
                Provider: Supabase
              </p>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <div className="flex items-center justify-center space-x-2 mb-4">
              <Leaf className="w-8 h-8 text-green-400" />
              <span className="text-2xl font-bold">Krishi Sahayak</span>
            </div>
            <p className="text-gray-400 mb-4">
              Empowering farmers with AI-driven agricultural solutions
            </p>
            <p className="text-gray-500 text-sm">
              © 2024 Krishi Sahayak. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  )
}