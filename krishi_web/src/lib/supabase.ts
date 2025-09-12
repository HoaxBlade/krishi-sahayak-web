import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Database types
export interface Crop {
  id: string
  name: string
  variety: string
  planting_date: string
  expected_harvest: string
  location: string
  notes?: string
  created_at: string
  updated_at: string
}

export interface WeatherData {
  id: string
  location: string
  temperature: number
  humidity: number
  precipitation: number
  wind_speed: number
  description: string
  timestamp: string
}

export interface MLAnalysis {
  id: string
  crop_id: string
  image_url: string
  health_status: string
  confidence: number
  prediction_class: string
  all_predictions: Record<string, number>
  analysis_date: string
  created_at: string
}
