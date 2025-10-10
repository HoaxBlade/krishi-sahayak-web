/* eslint-disable @typescript-eslint/no-unused-vars */
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

    const { data: products, error, count } = await query

    if (error) {
      return NextResponse.json({ error: 'Failed to fetch products' }, { status: 500 })
    }

    return NextResponse.json({
      products: products || [],
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit)
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
