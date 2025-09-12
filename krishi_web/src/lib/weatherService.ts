import axios from 'axios'

const OPENWEATHER_API_KEY = process.env.NEXT_PUBLIC_OPENWEATHERMAP_API_KEY!

export interface WeatherData {
  temperature: number
  humidity: number
  precipitation: number
  windSpeed: number
  description: string
  location: string
  timestamp: string
}

export class WeatherService {
  private static instance: WeatherService

  private constructor() {}

  public static getInstance(): WeatherService {
    if (!WeatherService.instance) {
      WeatherService.instance = new WeatherService()
    }
    return WeatherService.instance
  }

  async getCurrentWeather(latitude: number, longitude: number): Promise<WeatherData> {
    try {
      const response = await axios.get(
        `https://api.openweathermap.org/data/2.5/weather?lat=${latitude}&lon=${longitude}&appid=${OPENWEATHER_API_KEY}&units=metric`
      )

      const data = response.data
      
      return {
        temperature: Math.round(data.main.temp),
        humidity: data.main.humidity,
        precipitation: data.rain?.['1h'] || 0,
        windSpeed: data.wind.speed,
        description: data.weather[0].description,
        location: data.name,
        timestamp: new Date().toISOString()
      }
    } catch (error) {
      console.error('Weather fetch failed:', error)
      throw new Error('Failed to fetch weather data')
    }
  }

  async getWeatherByCity(city: string): Promise<WeatherData> {
    try {
      const response = await axios.get(
        `https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${OPENWEATHER_API_KEY}&units=metric`
      )

      const data = response.data
      
      return {
        temperature: Math.round(data.main.temp),
        humidity: data.main.humidity,
        precipitation: data.rain?.['1h'] || 0,
        windSpeed: data.wind.speed,
        description: data.weather[0].description,
        location: data.name,
        timestamp: new Date().toISOString()
      }
    } catch (error) {
      console.error('Weather fetch failed:', error)
      throw new Error('Failed to fetch weather data')
    }
  }

  getWeatherIcon(description: string): string {
    const desc = description.toLowerCase()
    
    if (desc.includes('rain')) return '🌧️'
    if (desc.includes('cloud')) return '☁️'
    if (desc.includes('sun') || desc.includes('clear')) return '☀️'
    if (desc.includes('snow')) return '❄️'
    if (desc.includes('storm')) return '⛈️'
    if (desc.includes('fog') || desc.includes('mist')) return '🌫️'
    
    return '🌤️'
  }

  getWeatherAdvice(weather: WeatherData): string[] {
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
}
