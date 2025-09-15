import axios from 'axios'

// Use API routes for all environments (more reliable)
const ML_SERVER_URL = process.env.NEXT_PUBLIC_ML_SERVER_URL || 'http://35.222.33.77'
const USE_API_ROUTES = true // Always use API routes for consistency

// Cache for ML server status
let mlStatusCache: {
  data: { healthy: boolean; responseTime: number; timestamp: string; error?: string } | null;
  timestamp: number;
} = { data: null, timestamp: 0 };
const ML_STATUS_CACHE_DURATION = 1000 * 10; // Cache for 10 seconds

// Type for axios error
interface AxiosError {
  message: string
  code?: string
  response?: {
    data?: unknown
  }
}

export interface MLAnalysisResult {
  health_status: string
  confidence: string
  prediction_class: string
  all_predictions: Record<string, number>
}

export class MLService {
  private static instance: MLService
  private baseUrl: string

  private constructor() {
    this.baseUrl = ML_SERVER_URL
  }

  public static getInstance(): MLService {
    if (!MLService.instance) {
      MLService.instance = new MLService()
    }
    return MLService.instance
  }

  async checkServerHealth(): Promise<boolean> {
    try {
      const url = USE_API_ROUTES ? '/api/ml/health' : `${this.baseUrl}/health`
      console.log('Checking ML Server health at:', url)
      
      const response = await axios.get(url, {
        timeout: 15000,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'Krishi-Sahayak-Web/1.0.0'
        }
      })
      console.log('ML Server health response:', response.status, response.data)
      return response.status === 200
    } catch (error) {
      const axiosError = error as AxiosError
      console.error('ML Server health check failed:', {
        url: USE_API_ROUTES ? '/api/ml/health' : this.baseUrl,
        error: axiosError.message || String(error),
        code: axiosError.code,
        response: axiosError.response?.data
      })
      return false
    }
  }

  async analyzeCropHealth(imageFile: File): Promise<MLAnalysisResult> {
    try {
      // Convert image to base64
      const base64Image = await this.convertToBase64(imageFile)
      
      const url = USE_API_ROUTES ? '/api/ml/analyze' : `${this.baseUrl}/analyze_crop`
      console.log('Analyzing crop health at:', url)
      
      const response = await axios.post(url, {
        image: base64Image
      }, {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 30000
      })

      return response.data
    } catch (error) {
      console.error('Crop analysis failed:', error)
      throw new Error('Failed to analyze crop health')
    }
  }

  private async convertToBase64(file: File): Promise<string> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.readAsDataURL(file)
      reader.onload = () => {
        const result = reader.result as string
        // Remove data:image/jpeg;base64, prefix
        const base64 = result.split(',')[1]
        resolve(base64)
      }
      reader.onerror = error => reject(error)
    })
  }

  async getServerStatus(): Promise<{
    healthy: boolean
    responseTime: number
    timestamp: string
    error?: string
  }> {
    const now = Date.now();
    if (mlStatusCache.data && (now - mlStatusCache.timestamp < ML_STATUS_CACHE_DURATION)) {
      console.log('Returning ML server status from cache.');
      return mlStatusCache.data;
    }

    const startTime = Date.now()
    let healthy = false
    let error: string | undefined

    try {
      healthy = await this.checkServerHealth()
    } catch (err) {
      error = 'ML Server is currently unavailable'
      console.warn('ML Server status check failed:', err)
    }

    const responseTime = Date.now() - startTime

    const status = {
      healthy,
      responseTime,
      timestamp: new Date().toISOString(),
      error
    };

    mlStatusCache = { data: status, timestamp: now };
    return status;
  }
}
