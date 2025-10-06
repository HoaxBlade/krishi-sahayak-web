/* eslint-disable @typescript-eslint/no-unused-vars */
import axios, { AxiosError } from 'axios'

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
interface WeatherCacheEntry {
  data: WeatherData;
  timestamp: number;
}

const weatherCache: { [key: string]: WeatherCacheEntry } = {};
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

  async getWeatherByCoordinates(latitude: number, longitude: number): Promise<WeatherData> {
    const cacheKey = `coords-${latitude}-${longitude}`;
    const now = Date.now();

    if (weatherCache[cacheKey] && (now - weatherCache[cacheKey].timestamp < WEATHER_CACHE_DURATION)) {
      return weatherCache[cacheKey].data;
    }

    try {
      const response = await axios.get(`/api/weather?lat=${latitude}&lon=${longitude}`);
      const data = response.data;
      weatherCache[cacheKey] = { data, timestamp: now };
      return data;
    } catch (error) {
      console.error('Weather fetch failed for coordinates:', error);
      throw new Error('Failed to fetch weather data');
    }
  }

  async getWeatherByCity(city: string): Promise<WeatherData> {
    const cacheKey = `city-${city.toLowerCase()}`;
    const now = Date.now();

    if (weatherCache[cacheKey] && (now - weatherCache[cacheKey].timestamp < WEATHER_CACHE_DURATION)) {
      return weatherCache[cacheKey].data;
    }

    try {
      const response = await axios.get(`/api/weather?city=${city}`, {
        timeout: 10000,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      });
      
      if (response.status === 200 && response.data) {
        const data = response.data;
        weatherCache[cacheKey] = { data, timestamp: now };
        return data;
      }
      throw new Error(`Weather API returned status: ${response.status}`);
    } catch (error) {
      console.error('Weather fetch failed for city:', error);
      if (axios.isAxiosError(error)) {
        if (error.response?.status === 500) {
          throw new Error('Weather API server error - check configuration');
        } else if (error.response?.status === 401) {
          throw new Error('Weather API authentication failed - check API key');
        } else if (error.code === 'ECONNABORTED') {
          throw new Error('Weather API request timeout');
        }
      }
      throw new Error('Failed to fetch weather data');
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
