/* eslint-disable @typescript-eslint/no-unused-vars */
 
"use client"

import { useState, useEffect } from "react"
import { motion } from "framer-motion"
import { 
  ShoppingCart, BarChart3, Cloud, Shield, ArrowRight, Wind, Droplet, Thermometer, Umbrella, CheckCircle 
} from "lucide-react"
import { MLService } from "@/lib/mlService"
import { WeatherService } from "@/lib/weatherService"
import { useAuth } from "@/contexts/AuthContext"
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
  const { isAuthenticated } = useAuth()
  const [mlStatus, setMlStatus] = useState<MLStatus | null>(null)
  const [weather, setWeather] = useState<WeatherData | null>(null)
  const [loading, setLoading] = useState(true)
  const [userLocation, setUserLocation] = useState<{ latitude: number; longitude: number } | null>(null)
  const [locationError, setLocationError] = useState<string | null>(null)

  // Add global error handler for unhandled promise rejections
  useEffect(() => {
    const handleUnhandledRejection = (event: PromiseRejectionEvent) => {
      console.warn('Unhandled promise rejection:', event.reason);
      event.preventDefault(); // Prevent the default browser behavior
    };

    window.addEventListener('unhandledrejection', handleUnhandledRejection);
    
    return () => {
      window.removeEventListener('unhandledrejection', handleUnhandledRejection);
    };
  }, []);

  useEffect(() => {
    const fetchLocationAndServices = async () => {
      setLoading(true)
      let lat: number | null = null
      let lon: number | null = null

      // First, try to get location from stored data
      const storedLocation = localStorage.getItem('userWeatherLocation');
      if (storedLocation) {
        try {
          const { latitude, longitude } = JSON.parse(storedLocation);
          if (latitude && longitude) {
            lat = latitude;
            lon = longitude;
            setUserLocation({ latitude, longitude });
            console.log("Using stored location:", { lat, lon });
          }
        } catch (error) {
          console.warn('Failed to parse stored location:', error);
        }
      }

      // If no stored location, try to get current location
      if (!lat || !lon) {
        if (navigator.geolocation) {
          try {
            const position = await new Promise<GeolocationPosition>((resolve, reject) => {
              navigator.geolocation.getCurrentPosition(
                resolve, 
                (error) => {
                  // Handle specific geolocation errors
                  let errorMessage = 'Unknown geolocation error';
                  switch (error.code) {
                    case error.PERMISSION_DENIED:
                      errorMessage = 'Location access denied by user';
                      break;
                    case error.POSITION_UNAVAILABLE:
                      errorMessage = 'Location information unavailable';
                      break;
                    case error.TIMEOUT:
                      errorMessage = 'Location request timed out';
                      break;
                    default:
                      errorMessage = error.message || 'Unknown geolocation error';
                  }
                  reject(new Error(errorMessage));
                }, 
                { 
                  enableHighAccuracy: false, // Start with less accurate but faster
                  timeout: 15000, // Increased timeout
                  maximumAge: 600000 // 10 minutes cache
                }
              );
            });
            lat = position.coords.latitude;
            lon = position.coords.longitude;
            setUserLocation({ latitude: lat, longitude: lon });
            console.log("Geolocation successful:", { lat, lon });
          } catch (error: unknown) {
            // Handle geolocation errors gracefully without throwing
            console.warn("Geolocation error:", error);
            const errorMessage = error instanceof Error ? error.message : 'Unknown geolocation error';
            setLocationError(`Unable to retrieve your location (${errorMessage}). Displaying weather for a default city.`);
            // Don't re-throw the error, just continue with fallback
          }
        } else {
          setLocationError("Geolocation is not supported by your browser. Displaying weather for a default city.");
        }
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
        console.warn("Service check failed:", error)
        setLocationError(prev => prev || "Failed to fetch weather data.");
      } finally {
        setLoading(false)
      }
    }
    
    // Wrap the entire function call in try-catch to handle any unhandled errors
    fetchLocationAndServices().catch((error) => {
      console.warn("Failed to fetch location and services:", error);
      setLocationError("Unable to load location and weather data. Please refresh the page.");
      setLoading(false);
    });
  }, [])

  const features = [
    { icon: <ShoppingCart />, title: "Agricultural Marketplace", desc: "Buy and sell crops, seeds, fertilizers, and farming equipment" },
    { icon: <Cloud />, title: "Real-time Weather Data", desc: "Get accurate forecasts and smart farming recommendations" },
    { icon: <BarChart3 />, title: "Crop Management", desc: "Track your crops, planting dates, and harvest schedules" },
    { icon: <Shield />, title: "Disease Detection", desc: "Early alerts for plant diseases and pest infestations" }
  ]

  return (
    <div className="min-h-screen relative overflow-hidden">
      {/* Animated gradient waves */}
      <motion.div
        className="absolute inset-0 bg-gradient-to-br from-green-200 via-blue-100 to-white z-0"
        animate={{ backgroundPosition: ["0% 50%", "100% 50%", "0% 50%", "50% 0%", "0% 50%"] }}
        transition={{ duration: 25, repeat: Infinity, ease: "easeInOut" }}
        style={{ backgroundSize: "200% 200%" }}
      />
      
      {/* Hero with animated background */}
      <section className="relative py-24 overflow-hidden text-center z-10">
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
            <motion.a
              href="/marketplace"
              className="bg-gradient-to-r from-green-600 to-green-700 text-white px-7 py-3.5 rounded-xl text-base font-medium flex items-center justify-center shadow-md"
              whileHover={{ scale: 1.02, boxShadow: "0 10px 20px rgba(0, 0, 0, 0.1)" }}
              whileTap={{ scale: 0.98 }}
              transition={{ type: "spring", stiffness: 400, damping: 10 }}
            >
              Explore Marketplace <ArrowRight className="ml-2 w-5 h-5" />
            </motion.a>
            <motion.a
              href="/learn-more"
              className="border border-green-600 text-green-700 px-7 py-3.5 rounded-xl text-base font-medium shadow-sm"
              whileHover={{ scale: 1.02, boxShadow: "0 10px 20px rgba(0, 0, 0, 0.08)" }}
              whileTap={{ scale: 0.98 }}
              transition={{ type: "spring", stiffness: 400, damping: 10 }}
            >
              Learn More
            </motion.a>
          </div>
        </div>
      </section>

      {/* Weather */}
      {weather && (
        <section className="relative py-12 z-10">
          <motion.div
            className="backdrop-blur-xl bg-white/60 border border-gray-100 rounded-2xl shadow-subtle p-7 max-w-sm mx-auto"
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            whileHover={{ scale: 1.02, boxShadow: "0 10px 20px rgba(0, 0, 0, 0.08)" }}
            transition={{ duration: 0.8, type: "spring", stiffness: 100 }}
          >
            <div className="flex items-center justify-between mb-5"> {/* Adjusted margin */}
              <div>
                <h3 className="text-xl font-bold text-gray-900">{weather.location}</h3> {/* Adjusted text size */}
                <p className="text-gray-500">{weather.description}</p> {/* Adjusted text color */}
                {userLocation && (
                  <p className="text-xs text-green-600 mt-1">📍 Your current location</p>
                )}
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
      <section className="relative py-12 bg-gray-50 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-10">
            <h2 className="text-3xl font-bold text-gray-900 mb-3">System Status</h2>
            <p className="text-lg text-gray-600">Real-time monitoring of our AI services</p>
          </div>
          
          <div className="grid md:grid-cols-3 gap-7">
            <StatusCard
              title="ML Server"
              status={mlStatus?.healthy ? "Healthy" : "Unhealthy"}
              extra={`Response Time: ${mlStatus?.responseTime || 0}ms`}
              healthy={!!mlStatus?.healthy}
            />
            <StatusCard
              title="Weather API"
              status={weather ? "Connected" : "Disconnected"}
              extra={`Location: ${weather?.location || "N/A"}`}
              healthy={!!weather}
              delay={0.1}
            />
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
      <section className="relative py-12 bg-gradient-to-b from-white to-green-50 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl font-extrabold text-gray-900 mb-3">Powerful Features for Modern Farming</h2>
          <p className="text-base text-gray-600 mb-14">Everything you need to optimize your agricultural operations</p>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((f, i) => (
              <motion.div
                key={i}
                className="text-center p-6 rounded-xl bg-white/70 backdrop-blur-md shadow-subtle"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                whileHover={{ scale: 1.02, boxShadow: "0 10px 20px rgba(0, 0, 0, 0.08)" }}
                transition={{ delay: i * 0.15, type: "spring", stiffness: 100 }}
              >
                <div className="inline-flex items-center justify-center w-14 h-14 bg-gradient-to-br from-green-100 to-blue-100 text-green-600 rounded-full mb-3 shadow-inner">
                  {f.icon}
                </div>
                <h3 className="text-lg font-medium text-gray-900 mb-1.5">{f.title}</h3>
                <p className="text-gray-600 text-sm">{f.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Incubated By Section */}
      <section className="relative py-8 bg-white z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <p className="text-lg text-gray-600 font-medium mb-4">Incubated By:</p>
          <img src="/NIELIT.png" alt="NIELIT Logo" className="mx-auto h-16" />
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
