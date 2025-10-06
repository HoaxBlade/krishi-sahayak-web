import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const limit = parseInt(searchParams.get('limit') || '10')
    const offset = parseInt(searchParams.get('offset') || '0')

    // Try to fetch recent ML analyses from Supabase
    try {
      const { data: analyses, error } = await supabase
        .from('ml_analyses')
        .select(`
          id,
          crop_id,
          image_url,
          health_status,
          confidence,
          prediction_class,
          analysis_date,
          created_at,
          crops (
            name,
            location
          )
        `)
        .order('analysis_date', { ascending: false })
        .range(offset, offset + limit - 1)

      if (error) {
        console.error('Supabase error:', error)
        // If table doesn't exist or other DB error, return sample data
        return NextResponse.json({
          analyses: getSampleAnalyses(limit),
          total: limit,
          note: 'Using sample data - database not available'
        })
      }

      // Transform the data to match the expected format
      const transformedAnalyses = analyses?.map((analysis) => ({
        id: analysis.id,
        crop: analysis.crops?.[0]?.name || analysis.prediction_class || 'Unknown Crop',
        status: analysis.health_status === 'healthy' ? 'Healthy' : 'Diseased',
        confidence: Math.round(analysis.confidence * 100),
        date: analysis.analysis_date || analysis.created_at,
        location: analysis.crops?.[0]?.location || 'Unknown Location'
      })) || []

      return NextResponse.json({
        analyses: transformedAnalyses,
        total: transformedAnalyses.length
      })

    } catch (dbError) {
      console.error('Database connection error:', dbError)
      // Return sample data if database is not available
      return NextResponse.json({
        analyses: getSampleAnalyses(limit),
        total: limit,
        note: 'Using sample data - database not available'
      })
    }

  } catch (error) {
    console.error('Error in analyses API:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// Fallback function to provide sample data when database is not available
function getSampleAnalyses(limit: number) {
  const sampleData = [
    {
      id: '1',
      crop: 'Tomato',
      status: 'Healthy',
      confidence: 96,
      date: new Date().toISOString().split('T')[0],
      location: 'Field A'
    },
    {
      id: '2',
      crop: 'Wheat',
      status: 'Diseased',
      confidence: 89,
      date: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      location: 'Field B'
    },
    {
      id: '3',
      crop: 'Rice',
      status: 'Healthy',
      confidence: 94,
      date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      location: 'Field C'
    },
    {
      id: '4',
      crop: 'Corn',
      status: 'Healthy',
      confidence: 91,
      date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      location: 'Field D'
    },
    {
      id: '5',
      crop: 'Potato',
      status: 'Diseased',
      confidence: 85,
      date: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      location: 'Field E'
    }
  ]

  return sampleData.slice(0, limit)
}
