import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

// GET /api/marketplace/providers - Get all providers
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const location = searchParams.get('location')
    const verified = searchParams.get('verified')
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '12')
    const offset = (page - 1) * limit

    let query = supabase
      .from('provider_profiles')
      .select(`
        *,
        products!inner(
          id,
          name,
          price,
          images,
          rating_avg
        )
      `)
      .order('rating_avg', { ascending: false })

    // Apply filters
    if (location) {
      query = query.or(`city.ilike.%${location}%,state.ilike.%${location}%`)
    }

    if (verified === 'true') {
      query = query.eq('verification_status', 'verified')
    }

    query = query.range(offset, offset + limit - 1)

    const { data: providers, error, count } = await query

    if (error) {
      console.error('Error fetching providers:', error)
      return NextResponse.json({ error: 'Failed to fetch providers' }, { status: 500 })
    }

    return NextResponse.json({
      providers: providers || [],
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit)
      }
    })
  } catch (error) {
    console.error('Providers API error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/marketplace/providers - Create provider profile
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { 
      business_name, 
      description, 
      business_type, 
      address, 
      city, 
      state, 
      pincode, 
      phone, 
      gst_number, 
      license_number 
    } = body

    // Get user from auth header (you'll need to implement this)
    const userId = 'placeholder-user-id' // TODO: Get from auth

    // Check if user already has a provider profile
    const { data: existingProfile } = await supabase
      .from('provider_profiles')
      .select('id')
      .eq('user_id', userId)
      .single()

    if (existingProfile) {
      return NextResponse.json({ error: 'Provider profile already exists' }, { status: 400 })
    }

    const { data: provider, error } = await supabase
      .from('provider_profiles')
      .insert({
        user_id: userId,
        business_name,
        description,
        business_type,
        address,
        city,
        state,
        pincode,
        phone,
        gst_number,
        license_number
      })
      .select()
      .single()

    if (error) {
      console.error('Error creating provider profile:', error)
      return NextResponse.json({ error: 'Failed to create provider profile' }, { status: 500 })
    }

    return NextResponse.json({ provider }, { status: 201 })
  } catch (error) {
    console.error('Create provider error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
