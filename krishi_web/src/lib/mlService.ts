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

// Cache for ML model performance data
let mlPerformanceCache: {
  data: {
    activeUsers: number;
    avgResponseTime: number;
    downtime: number;
    lastUpdated: string;
    trends: {
      activeUsersChange: number;
      responseTimeChange: number;
    };
  } | null;
  timestamp: number;
} = { data: null, timestamp: 0 };
const ML_PERFORMANCE_CACHE_DURATION = 1000 * 30; // Cache for 30 seconds

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
  gemini_analysis_english: string
  gemini_analysis_hindi: string
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
    const status = await this.getServerStatus()
    return status.healthy
  }

  async analyzeCropHealth(imageFile: File): Promise<MLAnalysisResult> {
    try {
      const formData = new FormData();
      formData.append('image', imageFile);
      
      const url = USE_API_ROUTES ? '/api/ml/analyze' : `${this.baseUrl}/analyze_crop`;
      
      const response = await axios.post(url, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        },
        timeout: 30000
      });

      return response.data;
    } catch (error) {
      console.error('Crop analysis failed:', error);
      throw new Error('Failed to analyze crop health');
    }
  }

  async getModelPerformance(): Promise<{
    activeUsers: number;
    avgResponseTime: number;
    downtime: number;
    lastUpdated: string;
    trends: {
      activeUsersChange: number;
      responseTimeChange: number;
    };
  }> {
    const now = Date.now();
    if (mlPerformanceCache.data && (now - mlPerformanceCache.timestamp < ML_PERFORMANCE_CACHE_DURATION)) {
      return mlPerformanceCache.data;
    }

    try {
      const response = await axios.get('/api/ml/performance', {
        timeout: 15000,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'Krishi-Sahayak-Web/1.0.0'
        }
      });

      const data = {
        activeUsers: response.data.activeUsers || 0,
        avgResponseTime: Math.round((response.data.avgResponseTime || 0) * 10) / 10,
        downtime: Math.round((response.data.downtime || 0) * 10) / 10,
        lastUpdated: new Date().toISOString(),
        trends: {
          activeUsersChange: response.data.trends?.activeUsersChange || 0,
          responseTimeChange: response.data.trends?.responseTimeChange || 0,
        }
      };
      mlPerformanceCache = { data, timestamp: now };
      return data;
    } catch (error) {
      console.error('Failed to fetch ML performance data:', error);
      throw new Error('Failed to fetch ML performance data');
    }
  }

  async getServerStatus(): Promise<{
    healthy: boolean
    responseTime: number
    timestamp: string
    error?: string
  }> {
    const now = Date.now();
    if (mlStatusCache.data && (now - mlStatusCache.timestamp < ML_STATUS_CACHE_DURATION)) {
      return mlStatusCache.data;
    }

    const startTime = Date.now()
    let healthy = false
    let error: string | undefined

    try {
      // Use the correct URL for health check
      const url = USE_API_ROUTES ? '/api/ml/health' : `${this.baseUrl}/health`
      
      const response = await axios.get(url, {
        timeout: 15000,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'Krishi-Sahayak-Web/1.0.0'
        }
      })
      
      
      // Check if response is healthy
      if (response.status === 200 && response.data && response.data.data?.status === 'healthy') {
        healthy = true
      }
    } catch (err) {
      const axiosError = err as AxiosError
      error = 'ML Server is currently unavailable'
      console.warn('ML Server status check failed:', {
        url: USE_API_ROUTES ? '/api/ml/health' : this.baseUrl,
        error: axiosError.message || String(err),
        code: axiosError.code,
        response: axiosError.response?.data
      })
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
