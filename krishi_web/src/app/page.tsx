/* eslint-disable @typescript-eslint/no-explicit-any */
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
  const [userLocation, setUserLocation] = useState<{ latitude: number; longitude: number } | null>(null)
  const [locationError, setLocationError] = useState<string | null>(null)

  useEffect(() => {
    const fetchLocationAndServices = async () => {
      setLoading(true)
      let lat: number | null = null
      let lon: number | null = null

      if (navigator.geolocation) {
        try {
          const position = await new Promise<GeolocationPosition>((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(resolve, reject, { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 });
          });
          lat = position.coords.latitude;
          lon = position.coords.longitude;
          setUserLocation({ latitude: lat, longitude: lon });
        } catch (error: any) {
          console.error("Geolocation error:", error);
          setLocationError("Unable to retrieve your location. Displaying weather for a default city.");
        }
      } else {
        setLocationError("Geolocation is not supported by your browser. Displaying weather for a default city.");
      }

      try {
        const mlService = MLService.getInstance()
        const weatherService = WeatherService.getInstance()
        
        let weatherDataPromise;
        if (lat !== null && lon !== null) {
          weatherDataPromise = weatherService.getWeatherByCoordinates(lat, lon);
        } else {
          weatherDataPromise = weatherService.getWeatherByCity("Delhi"); // Fallback to Delhi
        }

        const [ml, weatherData] = await Promise.all([
          mlService.getServerStatus(),
          weatherDataPromise
        ])
        setMlStatus(ml)
        setWeather(weatherData)

        // Store location data in localStorage
        if (weatherData) {
          localStorage.setItem('userWeatherLocation', JSON.stringify({
            location: weatherData.location,
            latitude: lat,
            longitude: lon
          }));
        }

      } catch (error) {
        console.error("Service check failed:", error)
        setLocationError(prev => prev || "Failed to fetch weather data.");
      } finally {
        setLoading(false)
      }
    }
    fetchLocationAndServices()
  }, [])

  const features = [
    { icon: <Camera />, title: "AI-Powered Crop Analysis", desc: "Upload crop images for instant health analysis using advanced machine learning" },
    { icon: <Cloud />, title: "Real-time Weather Data", desc: "Get accurate forecasts and smart farming recommendations" },
    { icon: <BarChart3 />, title: "Crop Management", desc: "Track your crops, planting dates, and harvest schedules" },
    { icon: <Shield />, title: "Disease Detection", desc: "Early alerts for plant diseases and pest infestations" }
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-100 via-blue-50 to-white">
      
      {/* Hero with animated background */}
      <section className="relative py-24 overflow-hidden text-center"> {/* Adjusted padding */}
        {/* Animated gradient waves */}
        <motion.div
          className="absolute inset-0 bg-gradient-to-br from-green-200 via-transparent to-blue-100"
          animate={{ backgroundPosition: ["0% 50%", "100% 50%", "0% 50%"] }}
          transition={{ duration: 15, repeat: Infinity, ease: "linear" }}
          style={{ backgroundSize: "200% 200%" }}
        />
        <div className="relative">
          <motion.h1
            className="text-5xl md:text-6xl font-extrabold text-gray-900 mb-8 leading-tight" /* Adjusted text size and margin */
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
          >
            Smart Farming with{" "}
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-green-600 to-blue-600">AI</span>
          </motion.h1>
          <p className="text-lg text-gray-600 mb-10 max-w-2xl mx-auto"> {/* Adjusted text size and margin */}
            Revolutionize your farming with AI-powered crop analysis, weather insights, and smart tools.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <button className="bg-gradient-to-r from-green-600 to-green-700 text-white px-7 py-3.5 rounded-xl text-base font-medium hover:shadow-lg hover:scale-[1.02] transition-all flex items-center justify-center shadow-md"> {/* Refined button style */}
              Analyze Your Crops <ArrowRight className="ml-2 w-5 h-5" />
            </button>
            <button className="border border-green-600 text-green-700 px-7 py-3.5 rounded-xl text-base font-medium hover:bg-green-50 hover:scale-[1.02] transition-all shadow-sm hover:shadow-md"> {/* Refined button style */}
              Learn More
            </button>
          </div>
        </div>
      </section>

      {/* Weather */}
      {weather && (
        <section className="py-10"> {/* Adjusted padding */}
          <motion.div
            className="backdrop-blur-xl bg-white/60 border border-gray-100 rounded-2xl shadow-subtle p-7 max-w-sm mx-auto hover:scale-[1.02] transition-transform" /* Refined card style */
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <div className="flex items-center justify-between mb-5"> {/* Adjusted margin */}
              <div>
                <h3 className="text-xl font-bold text-gray-900">{weather.location}</h3> {/* Adjusted text size */}
                <p className="text-gray-500">{weather.description}</p> {/* Adjusted text color */}
              </div>
              <div className="text-5xl animate-pulse"> {/* Adjusted text size */}
                {WeatherService.getInstance().getWeatherIcon(weather.description)}
              </div>
            </div>
            <div className="mt-5 grid grid-cols-2 gap-5 text-xs"> {/* Adjusted margin, gap, and text size */}
              <WeatherStat icon={<Thermometer />} label="Temperature" value={`${weather.temperature}°C`} />
              <WeatherStat icon={<Droplet />} label="Humidity" value={`${weather.humidity}%`} />
              <WeatherStat icon={<Wind />} label="Wind" value={`${weather.windSpeed} m/s`} />
              <WeatherStat icon={<Umbrella />} label="Rain" value={`${weather.precipitation}mm`} />
            </div>
          </motion.div>
        </section>
      )}

      {/* System Status Section */}
      <section className="py-16 bg-gray-50"> {/* Adjusted padding */}
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-10"> {/* Adjusted margin */}
            <h2 className="text-3xl font-bold text-gray-900 mb-3">System Status</h2> {/* Adjusted text size and margin */}
            <p className="text-lg text-gray-600">Real-time monitoring of our AI services</p> {/* Adjusted text size */}
          </div>
          
          <div className="grid md:grid-cols-3 gap-7"> {/* Adjusted gap */}
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
      <section className="py-20 bg-gradient-to-b from-white to-green-50"> {/* Adjusted padding */}
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl font-extrabold text-gray-900 mb-3">Powerful Features for Modern Farming</h2> {/* Adjusted text size and margin */}
          <p className="text-base text-gray-600 mb-14">Everything you need to optimize your agricultural operations</p> {/* Adjusted text size and margin */}
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8"> {/* Adjusted gap */}
            {features.map((f, i) => (
              <motion.div
                key={i}
                className="text-center p-6 rounded-xl bg-white/70 backdrop-blur-md shadow-subtle hover:shadow-lg hover:scale-[1.02] transition-all" /* Refined card style and hover effect */
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.15 }}
              >
                <div className="inline-flex items-center justify-center w-14 h-14 bg-gradient-to-br from-green-100 to-blue-100 text-green-600 rounded-full mb-3 shadow-inner"> {/* Adjusted size and margin */}
                  {f.icon}
                </div>
                <h3 className="text-lg font-medium text-gray-900 mb-1.5">{f.title}</h3> {/* Adjusted text size and weight */}
                <p className="text-gray-600 text-sm">{f.desc}</p> {/* Adjusted text size */}
              </motion.div>
            ))}
          </div>
        </div>
      </section>

    </div>
  )
}

function WeatherStat({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="flex items-center space-x-2">
      <span className="text-green-600">{icon}</span>
      <div>
        <span className="text-gray-500 text-xs">{label}</span> {/* Adjusted text size */}
        <p className="font-medium text-gray-700">{value}</p> {/* Adjusted font weight and color */}
      </div>
    </div>
  )
}

function StatusCard({ title, status, extra, healthy, delay = 0 }: { title: string; status: string; extra: string; healthy: boolean; delay?: number }) {
  return (
    <motion.div
      className="bg-white rounded-xl shadow-subtle p-5" /* Refined card style */
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay }}
    >
      <div className="flex items-center justify-between mb-3"> {/* Adjusted margin */}
        <h3 className="text-base font-medium text-gray-900">{title}</h3> {/* Adjusted text size and weight */}
        <CheckCircle className={`w-5 h-5 ${healthy ? "text-green-500" : "text-red-500"}`} /> {/* Adjusted icon size */}
      </div>
      <p className="text-gray-500 mb-1.5 text-sm">Status: {status}</p> {/* Adjusted text color and size */}
      <p className="text-gray-500 text-sm">{extra}</p> {/* Adjusted text color and size */}
    </motion.div>
  )
}