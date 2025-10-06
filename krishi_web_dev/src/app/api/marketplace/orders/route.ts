import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

// GET /api/marketplace/orders - Get user's orders
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
      .from('orders')
      .select(`
        *,
        provider_profiles!inner(
          id,
          business_name,
          city,
          state,
          phone
        ),
        order_items(
          id,
          quantity,
          unit_price,
          total_price,
          products(
            id,
            name,
            images,
            unit
          )
        )
      `)
      .eq('farmer_id', userId)
      .order('created_at', { ascending: false })

    if (status) {
      query = query.eq('status', status)
    }

    query = query.range(offset, offset + limit - 1)

    const { data: orders, error, count } = await query

    if (error) {
      console.error('Error fetching orders:', error)
      return NextResponse.json({ error: 'Failed to fetch orders' }, { status: 500 })
    }

    return NextResponse.json({
      orders: orders || [],
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit)
      }
    })
  } catch (error) {
    console.error('Orders API error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/marketplace/orders - Create new order
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { 
      provider_id, 
      items, 
      shipping_address, 
      notes 
    } = body

    // Get user from auth header (you'll need to implement this)
    const userId = 'placeholder-user-id' // TODO: Get from auth

    // Validate items
    if (!items || items.length === 0) {
      return NextResponse.json({ error: 'Order must contain at least one item' }, { status: 400 })
    }

    // Calculate total amount
    let totalAmount = 0
    for (const item of items) {
      totalAmount += item.quantity * item.unit_price
    }

    // Generate order number
    const orderNumber = `ORD-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`

    // Create order
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert({
        farmer_id: userId,
        provider_id,
        order_number: orderNumber,
        total_amount: totalAmount,
        shipping_address,
        notes
      })
      .select()
      .single()

    if (orderError) {
      console.error('Error creating order:', orderError)
      return NextResponse.json({ error: 'Failed to create order' }, { status: 500 })
    }

    // Create order items
    const orderItems = items.map((item: { product_id: string; quantity: number; unit_price: number }) => ({
      order_id: order.id,
      product_id: item.product_id,
      quantity: item.quantity,
      unit_price: item.unit_price,
      total_price: item.quantity * item.unit_price
    }))

    const { error: itemsError } = await supabase
      .from('order_items')
      .insert(orderItems)

    if (itemsError) {
      console.error('Error creating order items:', itemsError)
      // Rollback order creation
      await supabase.from('orders').delete().eq('id', order.id)
      return NextResponse.json({ error: 'Failed to create order items' }, { status: 500 })
    }

    // Update product stock
    for (const item of items) {
      // Get current stock quantity
      const { data: product } = await supabase
        .from('products')
        .select('stock_quantity')
        .eq('id', item.product_id)
        .single()
      
      if (product) {
        await supabase
          .from('products')
          .update({ 
            stock_quantity: product.stock_quantity - item.quantity
          })
          .eq('id', item.product_id)
      }
    }

    return NextResponse.json({ order }, { status: 201 })
  } catch (error) {
    console.error('Create order error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
