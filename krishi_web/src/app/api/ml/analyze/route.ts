import { NextRequest, NextResponse } from 'next/server'

const ML_SERVER_URL = process.env.NEXT_PUBLIC_ML_SERVER_URL || 'http://35.222.33.77'

export async function POST(request: NextRequest) {
  try {
    console.log('Proxying ML Server analyze request to:', ML_SERVER_URL)
    
    const body = await request.json()
    console.log('Request body:', { hasImage: !!body.image, imageLength: body.image?.length })
    
    // Create a timeout controller
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 30000)
    
    const response = await fetch(`${ML_SERVER_URL}/analyze_crop`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': 'Krishi-Sahayak-Web/1.0.0'
      },
      body: JSON.stringify(body),
      signal: controller.signal
    })
    
    clearTimeout(timeoutId)

    if (!response.ok) {
      throw new Error(`ML Server responded with status: ${response.status}`)
    }

    const data = await response.json()
    console.log('ML Server analyze response:', data)

    return NextResponse.json(data)
  } catch (error) {
    console.error('ML Server analyze failed:', error)
    
    return NextResponse.json({
      error: 'Failed to analyze crop health',
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 })
  }
}
