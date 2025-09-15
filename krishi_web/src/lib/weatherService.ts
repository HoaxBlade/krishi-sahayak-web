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

// Cache for weather data
const weatherCache: {
  [key: string]: {
    data: WeatherData;
    timestamp: number;
  };
} = {};
const WEATHER_CACHE_DURATION = 1000 * 60 * 5; // Cache for 5 minutes

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
    const cacheKey = `geo-${latitude}-${longitude}`;
    const now = Date.now();

    if (weatherCache[cacheKey] && (now - weatherCache[cacheKey].timestamp < WEATHER_CACHE_DURATION)) {
      console.log('Returning weather data from cache for:', cacheKey);
      return weatherCache[cacheKey].data;
    }

    try {
      const response = await axios.get(
        `https://api.openweathermap.org/data/2.5/weather?lat=${latitude}&lon=${longitude}&appid=${OPENWEATHER_API_KEY}&units=metric`
      )

      const data = response.data
      
      const weatherData: WeatherData = {
        temperature: Math.round(data.main.temp),
        humidity: data.main.humidity,
        precipitation: data.rain?.['1h'] || 0,
        windSpeed: data.wind.speed,
        description: data.weather[0].description,
        location: data.name,
        timestamp: new Date().toISOString()
      };

      weatherCache[cacheKey] = { data: weatherData, timestamp: now };
      return weatherData;
    } catch (error) {
      console.error('Weather fetch failed:', error)
      throw new Error('Failed to fetch weather data')
    }
  }

  async getWeatherByCity(city: string): Promise<WeatherData> {
    const cacheKey = `city-${city.toLowerCase()}`;
    const now = Date.now();

    if (weatherCache[cacheKey] && (now - weatherCache[cacheKey].timestamp < WEATHER_CACHE_DURATION)) {
      console.log('Returning weather data from cache for:', cacheKey);
      return weatherCache[cacheKey].data;
    }

    try {
      const response = await axios.get(
        `https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${OPENWEATHER_API_KEY}&units=metric`
      )

      const data = response.data
      
      const weatherData: WeatherData = {
        temperature: Math.round(data.main.temp),
        humidity: data.main.humidity,
        precipitation: data.rain?.['1h'] || 0,
        windSpeed: data.wind.speed,
        description: data.weather[0].description,
        location: data.name,
        timestamp: new Date().toISOString()
      };

      weatherCache[cacheKey] = { data: weatherData, timestamp: now };
      return weatherData;
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
