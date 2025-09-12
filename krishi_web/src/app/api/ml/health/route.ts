import { NextRequest, NextResponse } from 'next/server'

const ML_SERVER_URL = process.env.NEXT_PUBLIC_ML_SERVER_URL || 'http://35.222.33.77'

export async function GET(request: NextRequest) {
  try {
    console.log('Proxying ML Server health check to:', ML_SERVER_URL)
    
    const response = await fetch(`${ML_SERVER_URL}/health`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': 'Krishi-Sahayak-Web/1.0.0'
      },
      // Increase timeout for serverless functions
      signal: AbortSignal.timeout(20000)
    })

    if (!response.ok) {
      throw new Error(`ML Server responded with status: ${response.status}`)
    }

    const data = await response.json()
    console.log('ML Server health response:', data)

    return NextResponse.json({
      healthy: true,
      responseTime: 0, // We can't measure this in serverless
      timestamp: new Date().toISOString(),
      data
    })
  } catch (error) {
    console.error('ML Server health check failed:', error)
    
    return NextResponse.json({
      healthy: false,
      responseTime: 0,
      timestamp: new Date().toISOString(),
      error: error instanceof Error ? error.message : 'Unknown error'
    })
  }
}
