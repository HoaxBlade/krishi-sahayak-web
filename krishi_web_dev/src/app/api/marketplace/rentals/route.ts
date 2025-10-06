import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

// GET /api/marketplace/rentals - Get user's rental bookings
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const status = searchParams.get('status')
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '10')
    const offset = (page - 1) * limit

    // Get user from auth header (you'll need to implement this)
    const userId = 'placeholder-user-id' // TODO: Get from auth

    let query = supabase
      .from('rental_bookings')
      .select(`
        *,
        provider_profiles!inner(
          id,
          business_name,
          city,
          state,
          phone
        ),
        products!inner(
          id,
          name,
          images,
          product_type
        )
      `)
      .eq('farmer_id', userId)
      .order('created_at', { ascending: false })

    if (status) {
      query = query.eq('status', status)
    }

    query = query.range(offset, offset + limit - 1)

    const { data: rentals, error, count } = await query

    if (error) {
      console.error('Error fetching rentals:', error)
      return NextResponse.json({ error: 'Failed to fetch rentals' }, { status: 500 })
    }

    return NextResponse.json({
      rentals: rentals || [],
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit)
      }
    })
  } catch (error) {
    console.error('Rentals API error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/marketplace/rentals - Create new rental booking
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { 
      product_id, 
      start_date, 
      end_date, 
      rental_rate_type,
      delivery_address,
      pickup_address,
      notes 
    } = body

    // Get user from auth header (you'll need to implement this)
    const userId = 'placeholder-user-id' // TODO: Get from auth

    // Validate dates
    const start = new Date(start_date)
    const end = new Date(end_date)
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    if (start < today) {
      return NextResponse.json({ error: 'Start date cannot be in the past' }, { status: 400 })
    }

    if (end <= start) {
      return NextResponse.json({ error: 'End date must be after start date' }, { status: 400 })
    }

    // Calculate total days
    const totalDays = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24))

    // Get product details and pricing
    const { data: product, error: productError } = await supabase
      .from('products')
      .select(`
        *,
        provider_profiles!inner(id)
      `)
      .eq('id', product_id)
      .eq('is_active', true)
      .single()

    if (productError || !product) {
      return NextResponse.json({ error: 'Product not found' }, { status: 404 })
    }

    if (product.product_type !== 'rentable') {
      return NextResponse.json({ error: 'Product is not available for rental' }, { status: 400 })
    }

    // Calculate pricing based on rate type
    let ratePerPeriod = 0
    let totalAmount = 0

    switch (rental_rate_type) {
      case 'daily':
        ratePerPeriod = product.rental_price_per_day || 0
        totalAmount = ratePerPeriod * totalDays
        break
      case 'weekly':
        ratePerPeriod = product.rental_price_per_week || 0
        totalAmount = ratePerPeriod * Math.ceil(totalDays / 7)
        break
      case 'monthly':
        ratePerPeriod = product.rental_price_per_month || 0
        totalAmount = ratePerPeriod * Math.ceil(totalDays / 30)
        break
      default:
        return NextResponse.json({ error: 'Invalid rental rate type' }, { status: 400 })
    }

    // Check minimum rental days
    if (totalDays < (product.min_rental_days || 1)) {
      return NextResponse.json({ 
        error: `Minimum rental period is ${product.min_rental_days || 1} days` 
      }, { status: 400 })
    }

    // Check maximum rental days
    if (product.max_rental_days && totalDays > product.max_rental_days) {
      return NextResponse.json({ 
        error: `Maximum rental period is ${product.max_rental_days} days` 
      }, { status: 400 })
    }

    // Check availability for the selected dates
    const { data: availability, error: availabilityError } = await supabase
      .from('rental_availability')
      .select('date, is_available')
      .eq('product_id', product_id)
      .gte('date', start_date)
      .lte('date', end_date)
      .eq('is_available', false)

    if (availabilityError) {
      console.error('Error checking availability:', availabilityError)
      return NextResponse.json({ error: 'Failed to check availability' }, { status: 500 })
    }

    if (availability && availability.length > 0) {
      return NextResponse.json({ 
        error: 'Product is not available for the selected dates' 
      }, { status: 400 })
    }

    // Calculate deposit amount
    const depositAmount = product.requires_deposit ? (product.deposit_amount || 0) : 0

    // Create rental booking
    const { data: rental, error: rentalError } = await supabase
      .from('rental_bookings')
      .insert({
        farmer_id: userId,
        provider_id: product.provider_profiles.id,
        product_id,
        start_date,
        end_date,
        total_days: totalDays,
        rental_rate_type,
        rate_per_period: ratePerPeriod,
        total_amount: totalAmount,
        deposit_amount: depositAmount,
        delivery_address,
        pickup_address,
        notes
      })
      .select()
      .single()

    if (rentalError) {
      console.error('Error creating rental booking:', rentalError)
      return NextResponse.json({ error: 'Failed to create rental booking' }, { status: 500 })
    }

    // Block availability for the selected dates
    const availabilityRecords = []
    for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
      availabilityRecords.push({
        product_id,
        date: d.toISOString().split('T')[0],
        is_available: false
      })
    }

    const { error: availabilityInsertError } = await supabase
      .from('rental_availability')
      .upsert(availabilityRecords)

    if (availabilityInsertError) {
      console.error('Error updating availability:', availabilityInsertError)
      // Don't fail the booking for this, just log it
    }

    return NextResponse.json({ rental }, { status: 201 })
  } catch (error) {
    console.error('Create rental error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
