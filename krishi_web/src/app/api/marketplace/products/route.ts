/* eslint-disable @typescript-eslint/no-unused-vars */
import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'
import { Product } from '@/lib/marketplaceService'

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
    // Fallback to placeholder for now
  }
  
  // Fallback to placeholder for now
  return '00000000-0000-0000-0000-000000000001'
}

// GET /api/marketplace/products - Get all products with filters
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const category = searchParams.get('category')
    const search = searchParams.get('search')
    const minPrice = searchParams.get('minPrice')
    const maxPrice = searchParams.get('maxPrice')
    const location = searchParams.get('location')
    const sortBy = searchParams.get('sortBy') || 'created_at'
    const sortOrder = searchParams.get('sortOrder') || 'desc'
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '12')
    const offset = (page - 1) * limit

    // Check if we're filtering for drone services or showing all products
    const isDroneCategory = category === 'drone-services'
    const isAllProducts = !category || category === 'all'
    
    let products: Product[] = []
    let totalCount = 0

    if (isDroneCategory) {
      // Query drone services instead of products
      let droneQuery = supabase
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

      // Apply search filter to drone services
      if (search) {
        droneQuery = droneQuery.or(`name.ilike.%${search}%,description.ilike.%${search}%,service_type.ilike.%${search}%`)
      }

      // Apply price filter to drone services
      if (minPrice) {
        droneQuery = droneQuery.gte('price_per_hour', parseFloat(minPrice))
      }
      if (maxPrice) {
        droneQuery = droneQuery.lte('price_per_hour', parseFloat(maxPrice))
      }

      // Apply location filter to drone services
      if (location) {
        droneQuery = droneQuery.or(`location_city.ilike.%${location}%,location_state.ilike.%${location}%`)
      }

      // Apply sorting
      const sortField = sortBy === 'price' ? 'price_per_hour' : sortBy
      droneQuery = droneQuery.order(sortField, { ascending: sortOrder === 'asc' })

      // Apply pagination
      droneQuery = droneQuery.range(offset, offset + limit - 1)

      const { data: droneServices, error: droneError, count: droneCount } = await droneQuery

      if (droneError) {
        console.error('Error fetching drone services:', droneError)
        return NextResponse.json({ error: 'Failed to fetch drone services' }, { status: 500 })
      }

      // Transform drone services to match product format
      products = (droneServices || []).map(service => ({
        id: service.id,
        name: service.name,
        description: service.description,
        price: service.price_per_hour,
        stock_quantity: 1, // Drone services are always available
        min_order_quantity: 1,
        unit: 'hour',
        images: service.images || [],
        specifications: {
          service_type: service.service_type,
          coverage_area: service.coverage_area,
          availability: service.availability,
          features: service.features,
          is_drone_service: true
        },
        is_active: service.is_active,
        is_featured: false,
        rating_avg: 0,
        review_count: 0,
        product_type: 'rentable',
        rental_price_per_day: service.price_per_hour * 8, // Approximate daily rate
        created_at: service.created_at,
        updated_at: service.updated_at,
        provider_profiles: {
          id: service.user_profile?.id || service.user_id,
          business_name: service.user_profile?.name || 'Drone Service Provider',
          city: service.location_city || 'Unknown',
          state: service.location_state || 'Unknown',
          rating_avg: 0,
          verification_status: 'verified'
        },
        categories: {
          id: 'drone-services',
          name: 'Drone Services'
        }
      }))

      totalCount = droneCount || 0
    } else {
      // Query regular products
      let query = supabase
        .from('products')
        .select(`
          *,
          provider_profiles!inner(
            id,
            business_name,
            city,
            state,
            rating_avg,
            verification_status
          ),
          categories!inner(
            id,
            name
          )
        `)
        .eq('is_active', true)

      // Apply filters
      if (category) {
        query = query.eq('category_id', category)
      }

      if (search) {
        query = query.or(`name.ilike.%${search}%,description.ilike.%${search}%`)
      }

      if (minPrice) {
        query = query.gte('price', parseFloat(minPrice))
      }

      if (maxPrice) {
        query = query.lte('price', parseFloat(maxPrice))
      }

      if (location) {
        query = query.or(`provider_profiles.city.ilike.%${location}%,provider_profiles.state.ilike.%${location}%`)
      }

      // Apply sorting
      query = query.order(sortBy, { ascending: sortOrder === 'asc' })

      // Apply pagination
      query = query.range(offset, offset + limit - 1)

      const { data: regularProducts, error, count } = await query

      if (error) {
        return NextResponse.json({ error: 'Failed to fetch products' }, { status: 500 })
      }

      products = regularProducts || []
      totalCount = count || 0

      // If showing all products, also include drone services
      if (isAllProducts) {
        let droneQuery = supabase
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

        // Apply search filter to drone services
        if (search) {
          droneQuery = droneQuery.or(`name.ilike.%${search}%,description.ilike.%${search}%,service_type.ilike.%${search}%`)
        }

        // Apply price filter to drone services
        if (minPrice) {
          droneQuery = droneQuery.gte('price_per_hour', parseFloat(minPrice))
        }
        if (maxPrice) {
          droneQuery = droneQuery.lte('price_per_hour', parseFloat(maxPrice))
        }

        // Apply location filter to drone services
        if (location) {
          droneQuery = droneQuery.or(`location_city.ilike.%${location}%,location_state.ilike.%${location}%`)
        }

        // Apply sorting
        const sortField = sortBy === 'price' ? 'price_per_hour' : sortBy
        droneQuery = droneQuery.order(sortField, { ascending: sortOrder === 'asc' })

        // Apply pagination
        droneQuery = droneQuery.range(offset, offset + limit - 1)

        const { data: droneServices, error: droneError, count: droneCount } = await droneQuery

        if (!droneError && droneServices) {
          // Transform drone services to match product format
          const transformedDroneServices = droneServices.map(service => ({
            id: service.id,
            name: service.name,
            description: service.description,
            price: service.price_per_hour,
            stock_quantity: 1, // Drone services are always available
            min_order_quantity: 1,
            unit: 'hour',
            images: service.images || [],
            specifications: {
              service_type: service.service_type,
              coverage_area: service.coverage_area,
              availability: service.availability,
              features: service.features,
              is_drone_service: true
            },
            is_active: service.is_active,
            is_featured: false,
            rating_avg: 0,
            review_count: 0,
            product_type: 'rentable',
            rental_price_per_day: service.price_per_hour * 8, // Approximate daily rate
            created_at: service.created_at,
            updated_at: service.updated_at,
            provider_profiles: {
              id: service.user_profile?.id || service.user_id,
              business_name: service.user_profile?.name || 'Drone Service Provider',
              city: service.location_city || 'Unknown',
              state: service.location_state || 'Unknown',
              rating_avg: 0,
              verification_status: 'verified'
            },
            categories: {
              id: 'drone-services',
              name: 'Drone Services'
            }
          }))

          // Combine regular products and drone services
          products = [...products, ...transformedDroneServices as Product[]]
          totalCount += droneCount || 0
        }
      }
    }

    return NextResponse.json({
      products: products,
      pagination: {
        page,
        limit,
        total: totalCount,
        totalPages: Math.ceil(totalCount / limit)
      }
    })
  } catch (error) {
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/marketplace/products - Create new product (Provider only)
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { 
      name, 
      description, 
      price, 
      discount_price, 
      category_id, 
      stock_quantity, 
      min_order_quantity, 
      unit, 
      images, 
      specifications 
    } = body

    // Get user from request
    const userId = await getUserIdFromRequest(request)

    // Handle category_id - if it's a string (category name), convert to UUID
    let categoryId = category_id
    if (typeof category_id === 'string' && !category_id.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)) {
      // First, try to find existing category by name
      const { data: existingCategory, error: categoryError } = await supabase
        .from('categories')
        .select('id')
        .eq('name', category_id)
        .eq('is_active', true)
        .single()

      if (existingCategory && !categoryError) {
        categoryId = existingCategory.id
      } else {
        // If category doesn't exist, create it
        const { data: newCategory, error: createCategoryError } = await supabase
          .from('categories')
          .insert({
            name: category_id,
            description: `Category for ${category_id}`,
            is_active: true
          })
          .select('id')
          .single()

        if (createCategoryError) {
          return NextResponse.json({ error: 'Failed to create category' }, { status: 500 })
        }

        categoryId = newCategory.id
      }
    }

    // Get or create provider profile for this user
    const { data: existingProvider, error: providerError } = await supabase
      .from('provider_profiles')
      .select('id')
      .eq('user_id', userId)
      .single()

    let providerProfile = existingProvider

    // If provider profile doesn't exist, create a default one
    if (providerError || !providerProfile) {
      const { data: newProvider, error: createError } = await supabase
        .from('provider_profiles')
        .insert({
          user_id: userId,
          business_name: 'Default Business',
          description: 'Default business profile',
          business_type: 'individual',
          address: 'Unknown Address',
          city: 'Unknown',
          state: 'Unknown',
          pincode: '000000',
          phone: '0000000000',
          rating_avg: 0,
          total_orders: 0,
          verification_status: 'pending'
        })
        .select('id')
        .single()

      if (createError) {
        return NextResponse.json({ error: 'Failed to create provider profile' }, { status: 500 })
      }
      
      providerProfile = newProvider
    }

    // Validate and set default unit if empty or invalid
    const validUnits = ['kg', 'bag', 'unit', 'liter', 'piece', 'set', 'acre', 'hour', 'per kg', 'per bag', 'per unit', 'per liter', 'per piece', 'per set', 'per acre', 'per hour']
    let productUnit = 'unit' // Default fallback
    
    if (unit) {
      // Try exact match first
      if (validUnits.includes(unit)) {
        productUnit = unit
      } else {
        // Try to extract unit from "per X" format
        const match = unit.match(/per\s+(.+)/i)
        if (match && validUnits.includes(match[1])) {
          productUnit = match[1]
        } else {
          // Try to find partial match
          const partialMatch = validUnits.find(u => u.includes(unit.toLowerCase()) || unit.toLowerCase().includes(u))
          if (partialMatch) {
            productUnit = partialMatch
          }
        }
      }
    }

    // Try creating the product with different unit formats if the first attempt fails
    let product, error
    const unitAttempts = [productUnit, 'unit', 'kg', 'piece']
    
    for (let i = 0; i < unitAttempts.length; i++) {
      const attemptUnit = unitAttempts[i]
      
      const result = await supabase
        .from('products')
        .insert({
          provider_id: providerProfile.id,
          name,
          description,
          price: parseFloat(price),
          discount_price: discount_price ? parseFloat(discount_price) : null,
          category_id: categoryId, // Use the resolved categoryId
          stock_quantity: parseInt(stock_quantity),
          min_order_quantity: parseInt(min_order_quantity) || 1,
          unit: attemptUnit,
          images: images || [],
          specifications: specifications || {},
          is_active: true,
          is_featured: false,
          rating_avg: 0,
          review_count: 0,
          product_type: 'buyable'
        })
        .select()
        .single()

      product = result.data
      error = result.error
      
      if (!error) {
        break
      }
    }

    if (error) {
      return NextResponse.json({ error: 'Failed to create product' }, { status: 500 })
    }

    return NextResponse.json({ product }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
