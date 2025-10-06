import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

// GET /api/marketplace/rentals/availability - Get availability for a product
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const productId = searchParams.get('product_id')
    const startDate = searchParams.get('start_date')
    const endDate = searchParams.get('end_date')

    if (!productId) {
      return NextResponse.json({ error: 'Product ID is required' }, { status: 400 })
    }

    let query = supabase
      .from('rental_availability')
      .select('date, is_available')
      .eq('product_id', productId)
      .order('date', { ascending: true })

    if (startDate) {
      query = query.gte('date', startDate)
    }

    if (endDate) {
      query = query.lte('date', endDate)
    }

    const { data: availability, error } = await query

    if (error) {
      console.error('Error fetching availability:', error)
      return NextResponse.json({ error: 'Failed to fetch availability' }, { status: 500 })
    }

    return NextResponse.json({ availability: availability || [] })
  } catch (error) {
    console.error('Availability API error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/marketplace/rentals/availability - Update availability (Provider only)
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { product_id, date, is_available } = body

    // Get user from auth header (you'll need to implement this)
    const userId = 'placeholder-user-id' // TODO: Get from auth

    // Verify user owns this product
    const { data: product, error: productError } = await supabase
      .from('products')
      .select(`
        *,
        provider_profiles!inner(user_id)
      `)
      .eq('id', product_id)
      .single()

    if (productError || !product) {
      return NextResponse.json({ error: 'Product not found' }, { status: 404 })
    }

    if (product.provider_profiles.user_id !== userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })
    }

    const { data: availability, error } = await supabase
      .from('rental_availability')
      .upsert({
        product_id,
        date,
        is_available
      })
      .select()
      .single()

    if (error) {
      console.error('Error updating availability:', error)
      return NextResponse.json({ error: 'Failed to update availability' }, { status: 500 })
    }

    return NextResponse.json({ availability })
  } catch (error) {
    console.error('Update availability error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
