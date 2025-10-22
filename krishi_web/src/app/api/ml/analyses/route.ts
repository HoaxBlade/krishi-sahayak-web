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
        .from('crop_analyses')
        .select(`
          id,
          user_id,
          image_url,
          crop_type,
          disease_type,
          health_status,
          is_healthy,
          confidence,
          prediction_class,
          all_predictions,
          model_type,
          analysis_mode,
          processing_time,
          created_at,
          updated_at
        `)
        .order('created_at', { ascending: false })
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
      const transformedAnalyses = analyses?.map((analysis, index) => ({
        id: analysis.id,
        crop: analysis.crop_type || 'Unknown Crop',
        status: analysis.is_healthy ? 'Healthy' : 'Diseased',
        confidence: Math.round(analysis.confidence * 100),
        date: analysis.created_at,
        location: `Field ${String.fromCharCode(65 + index)}` // Field A, B, C, etc.
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
