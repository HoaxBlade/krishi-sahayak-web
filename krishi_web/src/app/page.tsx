"use client"

import { useState, useEffect } from "react"
import { motion } from "framer-motion"
import { 
  Leaf, Camera, BarChart3, Cloud, Shield, ArrowRight, Wind, Droplet, Thermometer, Umbrella, CheckCircle 
} from "lucide-react"
import { MLService } from "@/lib/mlService"
import { WeatherService } from "@/lib/weatherService"
import React from "react" 

type MLStatus = {
  healthy: boolean
  responseTime: number
  timestamp: string
  error?: string
}

type WeatherData = {
  temperature: number
  humidity: number
  precipitation: number
  windSpeed: number
  description: string
  location: string
  timestamp: string
}

export default function HomePage() {
  const [mlStatus, setMlStatus] = useState<MLStatus | null>(null)
  const [weather, setWeather] = useState<WeatherData | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const checkServices = async () => {
      try {
        const mlService = MLService.getInstance()
        const weatherService = WeatherService.getInstance()
        const [ml, weatherData] = await Promise.all([
          mlService.getServerStatus(),
          weatherService.getWeatherByCity("Delhi")
        ])
        setMlStatus(ml)
        setWeather(weatherData)
      } catch (error) {
        console.error("Service check failed:", error)
      } finally {
        setLoading(false)
      }
    }
    checkServices()
  }, [])

  const features = [
    { icon: <Camera />, title: "AI-Powered Crop Analysis", desc: "Upload crop images for instant health analysis using advanced machine learning" },
    { icon: <Cloud />, title: "Real-time Weather Data", desc: "Get accurate forecasts and smart farming recommendations" },
    { icon: <BarChart3 />, title: "Crop Management", desc: "Track your crops, planting dates, and harvest schedules" },
    { icon: <Shield />, title: "Disease Detection", desc: "Early alerts for plant diseases and pest infestations" }
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-100 via-blue-50 to-white">
      {/* Header */}
      <header className="backdrop-blur-md bg-white/70 shadow-md sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-2">
              <Leaf className="w-8 h-8 text-green-600" />
              <span className="text-2xl font-bold text-gray-900">Krishi Sahayak</span>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                {loading ? (
                  <span className="text-sm text-gray-500">Checking services...</span>
                ) : (
                  <>
                    <div className={`w-3 h-3 rounded-full ${mlStatus?.healthy ? "bg-green-500 animate-pulse" : "bg-red-500"}`} />
                    <span className="text-sm text-gray-600">
                      {mlStatus?.healthy ? "ML Server Online" : "ML Server Offline"}
                    </span>
                  </>
                )}
              </div>
              <button className="bg-gradient-to-r from-green-600 to-green-700 text-white px-5 py-2 rounded-xl hover:shadow-lg hover:scale-105 transition-all">
                Get Started
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Hero with animated background */}
      <section className="relative py-28 overflow-hidden text-center">
        {/* Animated gradient waves */}
        <motion.div
          className="absolute inset-0 bg-gradient-to-br from-green-200 via-transparent to-blue-100"
          animate={{ backgroundPosition: ["0% 50%", "100% 50%", "0% 50%"] }}
          transition={{ duration: 15, repeat: Infinity, ease: "linear" }}
          style={{ backgroundSize: "200% 200%" }}
        />
        <div className="relative">
          <motion.h1 
            className="text-6xl md:text-7xl font-extrabold text-gray-900 mb-6 leading-tight"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
          >
            Smart Farming with{" "}
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-green-600 to-blue-600">AI</span>
          </motion.h1>
          <p className="text-xl text-gray-600 mb-8 max-w-2xl mx-auto">
            Revolutionize your farming with AI-powered crop analysis, weather insights, and smart tools.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <button className="bg-gradient-to-r from-green-600 to-green-700 text-white px-8 py-4 rounded-xl text-lg font-semibold hover:shadow-lg hover:scale-105 transition-all flex items-center justify-center">
              Analyze Your Crops <ArrowRight className="ml-2 w-5 h-5" />
            </button>
            <button className="border-2 border-green-600 text-green-700 px-8 py-4 rounded-xl text-lg font-semibold hover:bg-green-50 hover:scale-105 transition-all">
              Learn More
            </button>
          </div>
        </div>
      </section>

      {/* Weather */}
      {weather && (
        <section className="py-12">
          <motion.div 
            className="backdrop-blur-2xl bg-white/50 border border-gray-200 rounded-3xl shadow-2xl p-8 max-w-md mx-auto hover:scale-105 transition-transform"
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <div className="flex items-center justify-between mb-6">
              <div>
                <h3 className="text-2xl font-bold text-gray-900">{weather.location}</h3>
                <p className="text-gray-600">{weather.description}</p>
              </div>
              <div className="text-6xl animate-pulse">
                {WeatherService.getInstance().getWeatherIcon(weather.description)}
              </div>
            </div>
            <div className="mt-6 grid grid-cols-2 gap-6 text-sm">
              <WeatherStat icon={<Thermometer />} label="Temperature" value={`${weather.temperature}°C`} />
              <WeatherStat icon={<Droplet />} label="Humidity" value={`${weather.humidity}%`} />
              <WeatherStat icon={<Wind />} label="Wind" value={`${weather.windSpeed} m/s`} />
              <WeatherStat icon={<Umbrella />} label="Rain" value={`${weather.precipitation}mm`} />
            </div>
          </motion.div>
        </section>
      )}

      {/* System Status Section */}
      <section className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">System Status</h2>
            <p className="text-xl text-gray-600">Real-time monitoring of our AI services</p>
          </div>
          
          <div className="grid md:grid-cols-3 gap-8">
            {/* ML Server */}
            <StatusCard 
              title="ML Server"
              status={mlStatus?.healthy ? "Healthy" : "Unhealthy"}
              extra={`Response Time: ${mlStatus?.responseTime || 0}ms`}
              healthy={!!mlStatus?.healthy}
            />
            {/* Weather API */}
            <StatusCard 
              title="Weather API"
              status={weather ? "Connected" : "Disconnected"}
              extra={`Location: ${weather?.location || "N/A"}`}
              healthy={!!weather}
              delay={0.1}
            />
            {/* Database */}
            <StatusCard 
              title="Database"
              status="Connected"
              extra="Provider: Supabase"
              healthy
              delay={0.2}
            />
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="py-24 bg-gradient-to-b from-white to-green-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-4xl font-extrabold text-gray-900 mb-4">Powerful Features for Modern Farming</h2>
          <p className="text-lg text-gray-600 mb-16">Everything you need to optimize your agricultural operations</p>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-10">
            {features.map((f, i) => (
              <motion.div 
                key={i}
                className="text-center p-8 rounded-2xl bg-white/80 backdrop-blur-lg shadow-md hover:shadow-xl hover:scale-105 transition-all"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.15 }}
              >
                <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-green-100 to-blue-100 text-green-600 rounded-full mb-4 shadow-inner">
                  {f.icon}
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">{f.title}</h3>
                <p className="text-gray-600">{f.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12 relative">
        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-green-500 via-blue-500 to-green-500" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="flex items-center justify-center space-x-2 mb-6">
            <Leaf className="w-8 h-8 text-green-400" />
            <span className="text-2xl font-bold">Krishi Sahayak</span>
          </div>
          <p className="text-gray-400 mb-4">Empowering farmers with AI-driven agricultural solutions</p>
          <p className="text-gray-500 text-sm">© 2025 Krishi Sahayak. All rights reserved.</p>
        </div>
      </footer>
    </div>
  )
}

function WeatherStat({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="flex items-center space-x-2">
      <span className="text-green-600">{icon}</span>
      <div>
        <span className="text-gray-500">{label}</span>
        <p className="font-bold text-gray-800">{value}</p>
      </div>
    </div>
  )
}

function StatusCard({ title, status, extra, healthy, delay = 0 }: { title: string; status: string; extra: string; healthy: boolean; delay?: number }) {
  return (
    <motion.div 
      className="bg-white rounded-xl shadow-lg p-6"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay }}
    >
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
        <CheckCircle className={`w-6 h-6 ${healthy ? "text-green-500" : "text-red-500"}`} />
      </div>
      <p className="text-gray-600 mb-2">Status: {status}</p>
      <p className="text-gray-600">{extra}</p>
    </motion.div>
  )
}