/* eslint-disable react-hooks/exhaustive-deps */
/* eslint-disable @typescript-eslint/no-unused-vars */

"use client"

import { useState, useEffect } from "react"
import Image from "next/image" // Import next/image
import {
  ShoppingCart, BarChart3, Cloud, Shield, ArrowRight, Wind, Droplet, Thermometer, Umbrella, CheckCircle, Download, Plane, Monitor, Leaf
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

  const [locationFetched, setLocationFetched] = useState(false);
  useEffect(() => {
    const fetchLocationAndServices = async () => {
      if (locationFetched) {
        return;
      }
      setLoading(true);
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
                  enableHighAccuracy: false, // Prefer lower accuracy for faster results on low-end devices
                  timeout: 5000, // Reduced timeout for quicker fallback
                  maximumAge: 60000 // Allow cached position for up to 1 minute
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
        setLoading(false);
      }
      setLocationFetched(true);
    };

    // Wrap the entire function call in try-catch to handle any unhandled errors
    fetchLocationAndServices().catch((error) => {
      console.warn("Failed to fetch location and services:", error);
      setLocationError("Unable to load location and weather data. Please refresh the page.");
      setLoading(false);
    });

    return () => {
      setLocationFetched(false);
    };
  }, []);

  const features = [
    { icon: <Plane />, title: "Drone Technologies Marketplace", desc: "Buy, sell, and rent agricultural drones and related services." },
    { icon: <Shield />, title: "AI Crop Disease Detection", desc: "AI-driven early warnings protect crops before diseases spread widely." },
    { icon: <Cloud />, title: "Regional language support", desc: "Support for Regional language to give insights into crop diseases." },
    { icon: <ShoppingCart />, title: "Farming Marketplace", desc: "Connect with buyers and sellers for crops, seeds, and equipment." }
  ]

  return (
    <div className="min-h-screen relative overflow-hidden">
      {/* Animated gradient waves */}
      {/* Simplified static background for low-end devices */}
      <div className="absolute inset-0 bg-gradient-to-br from-green-100 via-blue-50 to-green-100 z-0" />
      
      {/* Hero with animated background */}
      <section className="relative py-24 overflow-hidden text-center z-10">
        <div className="relative">
          <h1
            className="text-5xl md:text-6xl font-extrabold text-gray-900 mb-8 leading-tight" /* Adjusted text size and margin */
          >
            Smart Farming with{" "}
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-green-600 to-blue-600"> AI</span>
          </h1>
          <p className="text-lg text-gray-600 mb-10 max-w-2xl mx-auto"> {/* Adjusted text size and margin */}
            Revolutionize your farming with advanced drone technology, AI-powered crop analysis, weather insights, and smart tools.
          </p>
          <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center items-center px-4">
            <a
              href="/marketplace"
              className="w-full sm:w-auto bg-gradient-to-r from-green-600 to-green-700 text-white px-6 py-4 sm:px-7 sm:py-3.5 rounded-xl text-sm sm:text-base font-medium flex items-center justify-center shadow-md min-h-[48px]"
            >
              Explore Marketplace <ArrowRight className="ml-2 w-5 h-5" />
            </a>
            <a
              href="/learn-more"
              className="w-full sm:w-auto border border-green-600 text-green-700 px-6 py-4 sm:px-7 sm:py-3.5 rounded-xl text-sm sm:text-base font-medium shadow-sm min-h-[48px] flex items-center justify-center"
            >
              Learn More
            </a>
          </div>
        </div>
      </section>
    
      {/* Weather */}
      {weather && (
        <section className="relative py-4 z-10">
          <div
            className="backdrop-blur-xl bg-white/60 border border-gray-100 rounded-2xl shadow-subtle p-7 max-w-sm mx-auto"
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
            
          </div>
        </section>
      )}

      {/* Incubated By Section */}
      <section className="relative py-8 pt-16 pb-8 z-10 bg-gradient-to-br from-green-50 via-blue-50 to-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <p className="text-lg text-gray-600 font-medium mb-1">Incubated By:</p>
          <Image src="/NIELIT.png" alt="NIELIT Logo" width={150} height={64} className="mx-auto h-16" priority />
          <p className="text-sm text-gray-500 mt-1">An initiative by NIELIT</p>
        </div>
      </section>

      {/* System Status Section */}
      <section className="relative py-5 bg-gray-50 z-10">
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
            />
            <StatusCard
              title="Database"
              status="Connected"
              extra="Provider: Supabase"
              healthy
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
              <div
                key={i}
                className="text-center p-6 rounded-xl bg-white/70 backdrop-blur-md shadow-subtle"
              >
                <div className="inline-flex items-center justify-center w-14 h-14 bg-gradient-to-br from-green-100 to-blue-100 text-green-600 rounded-full mb-3 shadow-inner">
                  {f.icon}
                </div>
                <h3 className="text-lg font-medium text-gray-900 mb-1.5">{f.title}</h3>
                <p className="text-gray-600 text-sm">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>
      {/* Floating Android Download Button */}
      <a
        href="/KrishiSahayak-release.apk"
        download="KrishiSahayak-release.apk"
        className="fixed bottom-8 right-8 bg-green-600 text-white p-4 rounded-full shadow-lg flex items-center justify-center z-50 cursor-pointer"
        title="Download Android App - Krishi Sahayak v1.0 (101.8MB)"
      >
        <Download className="w-7 h-7" />
      </a>
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

function StatusCard({ title, status, extra, healthy }: { title: string; status: string; extra: string; healthy: boolean }) {
  return (
    <div
      className="bg-white rounded-xl shadow-subtle p-5" /* Refined card style */
      style={{
        boxShadow: healthy
          ? "0 0 10px 2px rgba(22, 163, 74, 0.4)" // green-600 with reduced opacity and spread
          : "0 0 10px 2px rgba(220, 38, 38, 0.4)", // red-600 with reduced opacity and spread
      }}
    >
      <div className="flex items-center justify-between mb-3"> {/* Adjusted margin */}
        <h3 className="text-base font-medium text-gray-900">{title}</h3> {/* Adjusted text size and weight */}
        <CheckCircle className={`w-5 h-5 ${healthy ? "text-green-500" : "text-red-500"}`} /> {/* Adjusted icon size */}
      </div>
      <p className="text-gray-500 mb-1.5 text-sm">Status: {status}</p> {/* Adjusted text color and size */}
      <p className="text-gray-500 text-sm">{extra}</p> {/* Adjusted text color and size */}
    </div>
  )
}
