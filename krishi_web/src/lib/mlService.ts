import axios from 'axios'

// ML Server URL - use environment variable or default
const ML_SERVER_URL = process.env.NEXT_PUBLIC_ML_SERVER_URL || 'http://35.222.33.77'

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
      const response = await axios.get(`${this.baseUrl}/health`, {
        timeout: 10000,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      })
      return response.status === 200
    } catch (error) {
      console.warn('ML Server health check failed:', error)
      return false
    }
  }

  async analyzeCropHealth(imageFile: File): Promise<MLAnalysisResult> {
    try {
      // Convert image to base64
      const base64Image = await this.convertToBase64(imageFile)
      
      const response = await axios.post(`${this.baseUrl}/analyze_crop`, {
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

    return {
      healthy,
      responseTime,
      timestamp: new Date().toISOString(),
      error
    }
  }
}
