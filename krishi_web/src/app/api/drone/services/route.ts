import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

// Helper function to get user ID from request
async function getUserIdFromRequest(request: NextRequest): Promise<string> {
  try {
    // Try to get user from Authorization header
    const authHeader = request.headers.get('authorization')
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '')
      const { data: { user }, error } = await supabase.auth.getUser(token)
      if (user && !error) {
        return user.id
      }
    }
  } catch (error) {
    console.error('Error getting user from request:', error)
    // Fallback to placeholder for now
  }
  
  // Fallback to placeholder for now
  return '00000000-0000-0000-0000-000000000001'
}

// GET /api/drone/services - Get all drone services
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const serviceType = searchParams.get('service_type')
    const city = searchParams.get('city')
    const state = searchParams.get('state')
    const limit = parseInt(searchParams.get('limit') || '50')
    const offset = parseInt(searchParams.get('offset') || '0')

    let query = supabase
      .from('drone_services')
      .select(`
        *,
        user_profile:user_id (
          id,
          name,
          email,
          phone,
          location
        )
      `)
      .eq('is_active', true)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1)

    // Apply filters
    if (serviceType) {
      query = query.eq('service_type', serviceType)
    }
    if (city) {
      query = query.ilike('location_city', `%${city}%`)
    }
    if (state) {
      query = query.ilike('location_state', `%${state}%`)
    }

    const { data: services, error } = await query

    if (error) {
      console.error('Error fetching drone services:', error)
      return NextResponse.json({ error: 'Failed to fetch drone services' }, { status: 500 })
    }

    return NextResponse.json({ services })
  } catch (error) {
    console.error('Error in GET /api/drone/services:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/drone/services - Create new drone service
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const {
      name,
      description,
      serviceType,
      pricePerHour,
      coverageArea,
      availability,
      features,
      images,
      contactInfo,
      location
    } = body

    // Validate required fields
    if (!name || !description || !serviceType || !pricePerHour || !coverageArea || !availability) {
      return NextResponse.json(
        { error: 'Missing required fields: name, description, serviceType, pricePerHour, coverageArea, availability' },
        { status: 400 }
      )
    }

    // Get user from request
    const userId = await getUserIdFromRequest(request)

    // Prepare data for insertion
    const serviceData = {
      user_id: userId,
      name: name.trim(),
      description: description.trim(),
      service_type: serviceType,
      price_per_hour: parseFloat(pricePerHour),
      coverage_area: coverageArea.trim(),
      availability: availability.trim(),
      features: features || [],
      images: images || [],
      contact_phone: contactInfo?.phone?.trim() || null,
      contact_email: contactInfo?.email?.trim() || null,
      location_address: location?.address?.trim() || null,
      location_city: location?.city?.trim() || null,
      location_state: location?.state?.trim() || null,
      location_pincode: location?.pincode?.trim() || null,
      is_active: true
    }

    // Insert the drone service
    const { data: newService, error } = await supabase
      .from('drone_services')
      .insert(serviceData)
      .select(`
        *,
        user_profile:user_id (
          id,
          name,
          email,
          phone,
          location
        )
      `)
      .single()

    if (error) {
      console.error('Error creating drone service:', error)
      return NextResponse.json({ error: 'Failed to create drone service' }, { status: 500 })
    }

    return NextResponse.json({ 
      message: 'Drone service created successfully',
      service: newService 
    }, { status: 201 })

  } catch (error) {
    console.error('Error in POST /api/drone/services:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// PUT /api/drone/services - Update drone service
export async function PUT(request: NextRequest) {
  try {
    const body = await request.json()
    const { id, ...updateData } = body

    if (!id) {
      return NextResponse.json({ error: 'Service ID is required' }, { status: 400 })
    }

    // Get user from request
    const userId = await getUserIdFromRequest(request)

    // Check if service exists and belongs to user
    const { data: existingService, error: fetchError } = await supabase
      .from('drone_services')
      .select('id, user_id')
      .eq('id', id)
      .single()

    if (fetchError || !existingService) {
      return NextResponse.json({ error: 'Service not found' }, { status: 404 })
    }

    if (existingService.user_id !== userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })
    }

    // Update the service
    const { data: updatedService, error } = await supabase
      .from('drone_services')
      .update({
        ...updateData,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select(`
        *,
        user_profile:user_id (
          id,
          name,
          email,
          phone,
          location
        )
      `)
      .single()

    if (error) {
      console.error('Error updating drone service:', error)
      return NextResponse.json({ error: 'Failed to update drone service' }, { status: 500 })
    }

    return NextResponse.json({ 
      message: 'Drone service updated successfully',
      service: updatedService 
    })

  } catch (error) {
    console.error('Error in PUT /api/drone/services:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// DELETE /api/drone/services - Delete drone service
export async function DELETE(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const id = searchParams.get('id')

    if (!id) {
      return NextResponse.json({ error: 'Service ID is required' }, { status: 400 })
    }

    // Get user from request
    const userId = await getUserIdFromRequest(request)

    // Check if service exists and belongs to user
    const { data: existingService, error: fetchError } = await supabase
      .from('drone_services')
      .select('id, user_id')
      .eq('id', id)
      .single()

    if (fetchError || !existingService) {
      return NextResponse.json({ error: 'Service not found' }, { status: 404 })
    }

    if (existingService.user_id !== userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })
    }

    // Soft delete by setting is_active to false
    const { error } = await supabase
      .from('drone_services')
      .update({ 
        is_active: false,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)

    if (error) {
      console.error('Error deleting drone service:', error)
      return NextResponse.json({ error: 'Failed to delete drone service' }, { status: 500 })
    }

    return NextResponse.json({ message: 'Drone service deleted successfully' })

  } catch (error) {
    console.error('Error in DELETE /api/drone/services:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
