'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { 
  Cloud, 
  Droplets, 
  Wind, 
  Thermometer,
  MapPin,
  RefreshCw,
  AlertCircle
} from 'lucide-react'
import { WeatherService, WeatherData } from '@/lib/weatherService'
import Link from 'next/link'
import { ArrowLeft, Leaf } from 'lucide-react'

export default function WeatherPage() {
  const [weather, setWeather] = useState<WeatherData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [location, setLocation] = useState('Delhi')
  const [customLocation, setCustomLocation] = useState('')

  useEffect(() => {
    fetchWeather(location)
  }, [location])

  const fetchWeather = async (city: string) => {
    setLoading(true)
    setError(null)
    
    try {
      const weatherService = WeatherService.getInstance()
      const data = await weatherService.getWeatherByCity(city)
      setWeather(data)
    } catch (err) {
      setError('Failed to fetch weather data. Please try again.')
      console.error('Weather fetch error:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleLocationSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (customLocation.trim()) {
      setLocation(customLocation.trim())
      fetchWeather(customLocation.trim())
    }
  }

  const getWeatherIcon = (description: string) => {
    const desc = description.toLowerCase()
    
    if (desc.includes('rain')) return '🌧️'
    if (desc.includes('cloud')) return '☁️'
    if (desc.includes('sun') || desc.includes('clear')) return '☀️'
    if (desc.includes('snow')) return '❄️'
    if (desc.includes('storm')) return '⛈️'
    if (desc.includes('fog') || desc.includes('mist')) return '🌫️'
    
    return '🌤️'
  }

  const getWeatherAdvice = (weather: WeatherData) => {
    const advice: string[] = []
    
    if (weather.temperature < 5) {
      advice.push('⚠️ Protect crops from frost damage')
    }
    
    if (weather.temperature > 35) {
      advice.push('🌡️ High temperature - ensure adequate irrigation')
    }
    
    if (weather.humidity > 80) {
      advice.push('💧 High humidity - watch for fungal diseases')
    }
    
    if (weather.precipitation > 10) {
      advice.push('🌧️ Heavy rain - check drainage systems')
    }
    
    if (weather.windSpeed > 10) {
      advice.push('💨 Strong winds - secure plants and structures')
    }
    
    if (advice.length === 0) {
      advice.push('✅ Weather conditions are favorable for farming')
    }
    
    return advice
  }

  const quickLocations = ['Delhi', 'Mumbai', 'Bangalore', 'Chennai', 'Kolkata', 'Hyderabad']

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-green-50">
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

      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Weather Dashboard
          </h1>
          <p className="text-xl text-gray-600">
            Real-time weather data and farming recommendations
          </p>
        </div>

        {/* Location Search */}
        <div className="bg-white rounded-xl shadow-lg p-6 mb-8">
          <h2 className="text-2xl font-semibold text-gray-900 mb-4">
            Select Location
          </h2>
          
          <form onSubmit={handleLocationSubmit} className="mb-6">
            <div className="flex gap-4">
              <input
                type="text"
                value={customLocation}
                onChange={(e) => setCustomLocation(e.target.value)}
                placeholder="Enter city name..."
                className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <button
                type="submit"
                className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors"
              >
                Search
              </button>
            </div>
          </form>

          <div className="flex flex-wrap gap-2">
            {quickLocations.map((city) => (
              <button
                key={city}
                onClick={() => {
                  setLocation(city)
                  fetchWeather(city)
                }}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  location === city
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {city}
              </button>
            ))}
          </div>
        </div>

        {loading ? (
          <div className="text-center py-12">
            <RefreshCw className="w-8 h-8 text-blue-600 animate-spin mx-auto mb-4" />
            <p className="text-gray-600">Loading weather data...</p>
          </div>
        ) : error ? (
          <div className="text-center py-12">
            <AlertCircle className="w-8 h-8 text-red-600 mx-auto mb-4" />
            <p className="text-red-600">{error}</p>
          </div>
        ) : weather ? (
          <div className="grid lg:grid-cols-3 gap-8">
            {/* Main Weather Card */}
            <motion.div 
              className="lg:col-span-2 bg-white rounded-xl shadow-lg p-8"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
            >
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h2 className="text-2xl font-bold text-gray-900 flex items-center">
                    <MapPin className="w-6 h-6 mr-2 text-blue-600" />
                    {weather.location}
                  </h2>
                  <p className="text-gray-600 capitalize">{weather.description}</p>
                </div>
                <div className="text-6xl">{getWeatherIcon(weather.description)}</div>
              </div>

              <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
                <div className="text-center">
                  <div className="flex items-center justify-center w-12 h-12 bg-blue-100 text-blue-600 rounded-full mx-auto mb-2">
                    <Thermometer className="w-6 h-6" />
                  </div>
                  <p className="text-2xl font-bold text-gray-900">{weather.temperature}°C</p>
                  <p className="text-sm text-gray-600">Temperature</p>
                </div>

                <div className="text-center">
                  <div className="flex items-center justify-center w-12 h-12 bg-blue-100 text-blue-600 rounded-full mx-auto mb-2">
                    <Droplets className="w-6 h-6" />
                  </div>
                  <p className="text-2xl font-bold text-gray-900">{weather.humidity}%</p>
                  <p className="text-sm text-gray-600">Humidity</p>
                </div>

                <div className="text-center">
                  <div className="flex items-center justify-center w-12 h-12 bg-blue-100 text-blue-600 rounded-full mx-auto mb-2">
                    <Wind className="w-6 h-6" />
                  </div>
                  <p className="text-2xl font-bold text-gray-900">{weather.windSpeed} m/s</p>
                  <p className="text-sm text-gray-600">Wind Speed</p>
                </div>

                <div className="text-center">
                  <div className="flex items-center justify-center w-12 h-12 bg-blue-100 text-blue-600 rounded-full mx-auto mb-2">
                    <Cloud className="w-6 h-6" />
                  </div>
                  <p className="text-2xl font-bold text-gray-900">{weather.precipitation}mm</p>
                  <p className="text-sm text-gray-600">Precipitation</p>
                </div>
              </div>
            </motion.div>

            {/* Farming Recommendations */}
            <motion.div 
              className="bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
            >
              <h3 className="text-xl font-semibold text-gray-900 mb-4">
                Farming Recommendations
              </h3>
              
              <div className="space-y-3">
                {getWeatherAdvice(weather).map((advice, index) => (
                  <div key={index} className="flex items-start space-x-3 p-3 bg-yellow-50 rounded-lg">
                    <div className="text-lg">{advice.split(' ')[0]}</div>
                    <p className="text-sm text-gray-700">{advice.substring(advice.indexOf(' ') + 1)}</p>
                  </div>
                ))}
              </div>

              <div className="mt-6 p-4 bg-green-50 rounded-lg">
                <h4 className="font-semibold text-green-900 mb-2">Current Conditions</h4>
                <p className="text-sm text-green-800">
                  {weather.temperature < 15 
                    ? 'Cool weather - good for root vegetables and leafy greens'
                    : weather.temperature > 30
                    ? 'Hot weather - ensure adequate watering and shade'
                    : 'Moderate weather - ideal for most crops'
                  }
                </p>
              </div>
            </motion.div>
          </div>
        ) : null}
      </div>
    </div>
  )
}
