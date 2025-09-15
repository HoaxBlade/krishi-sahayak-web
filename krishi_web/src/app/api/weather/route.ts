import { NextResponse } from 'next/server';
import axios from 'axios';

const OPENWEATHER_API_KEY = process.env.OPENWEATHERMAP_API_KEY;
const WEATHER_CACHE_DURATION = 1000 * 60 * 5; // Cache for 5 minutes

interface WeatherData {
  temperature: number;
  humidity: number;
  precipitation: number;
  windSpeed: number;
  description: string;
  location: string;
  timestamp: string;
}

const serverWeatherCache: {
  [key: string]: {
    data: WeatherData;
    timestamp: number;
  };
} = {};

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const city = searchParams.get('city');
  const lat = searchParams.get('lat');
  const lon = searchParams.get('lon');

  if (!OPENWEATHER_API_KEY) {
    return NextResponse.json({ error: 'OpenWeatherMap API key not configured' }, { status: 500 });
  }

  let cacheKey: string;
  let apiUrl: string;

  if (city) {
    cacheKey = `city-${city.toLowerCase()}`;
    apiUrl = `https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${OPENWEATHER_API_KEY}&units=metric`;
  } else if (lat && lon) {
    cacheKey = `geo-${lat}-${lon}`;
    apiUrl = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${OPENWEATHER_API_KEY}&units=metric`;
  } else {
    return NextResponse.json({ error: 'City or latitude/longitude are required' }, { status: 400 });
  }

  const now = Date.now();
  if (serverWeatherCache[cacheKey] && (now - serverWeatherCache[cacheKey].timestamp < WEATHER_CACHE_DURATION)) {
    console.log('Returning weather data from server cache for:', cacheKey);
    return NextResponse.json(serverWeatherCache[cacheKey].data);
  }

  try {
    const response = await axios.get(apiUrl);
    const data = response.data;

    const weatherData: WeatherData = {
      temperature: Math.round(data.main.temp),
      humidity: data.main.humidity,
      precipitation: data.rain?.['1h'] || 0,
      windSpeed: data.wind.speed,
      description: data.weather[0].description,
      location: data.name,
      timestamp: new Date().toISOString(),
    };

    serverWeatherCache[cacheKey] = { data: weatherData, timestamp: now };
    return NextResponse.json(weatherData);
  } catch (error) {
    console.error('Error fetching weather data:', error);
    if (axios.isAxiosError(error) && error.response) {
      return NextResponse.json({ error: error.response.data }, { status: error.response.status });
    }
    return NextResponse.json({ error: 'Failed to fetch weather data' }, { status: 500 });
  }
}