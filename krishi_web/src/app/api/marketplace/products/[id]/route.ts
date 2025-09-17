import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

// GET /api/marketplace/products/[id] - Get single product
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const { data: product, error } = await supabase
      .from('products')
      .select(`
        *,
        provider_profiles!inner(
          id,
          business_name,
          description,
          city,
          state,
          phone,
          rating_avg,
          total_orders,
          verification_status
        ),
        categories!inner(
          id,
          name,
          description
        )
      `)
      .eq('id', id)
      .eq('is_active', true)
      .single()

    if (error) {
      console.error('Error fetching product:', error)
      return NextResponse.json({ error: 'Product not found' }, { status: 404 })
    }

    return NextResponse.json({ product })
  } catch (error) {
    console.error('Product API error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// PUT /api/marketplace/products/[id] - Update product (Provider only)
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
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
      specifications,
      is_active 
    } = body

    // Get user from auth header (you'll need to implement this)
    const userId = 'placeholder-user-id' // TODO: Get from auth

    // Verify user owns this product
    const { data: product, error: productError } = await supabase
      .from('products')
      .select(`
        *,
        provider_profiles!inner(user_id)
      `)
      .eq('id', id)
      .single()

    if (productError || !product) {
      return NextResponse.json({ error: 'Product not found' }, { status: 404 })
    }

    if (product.provider_profiles.user_id !== userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })
    }

    const { data: updatedProduct, error } = await supabase
      .from('products')
      .update({
        name,
        description,
        price: price ? parseFloat(price) : undefined,
        discount_price: discount_price ? parseFloat(discount_price) : null,
        category_id,
        stock_quantity: stock_quantity ? parseInt(stock_quantity) : undefined,
        min_order_quantity: min_order_quantity ? parseInt(min_order_quantity) : undefined,
        unit,
        images: images || undefined,
        specifications: specifications || undefined,
        is_active: is_active !== undefined ? is_active : undefined
      })
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Error updating product:', error)
      return NextResponse.json({ error: 'Failed to update product' }, { status: 500 })
    }

    return NextResponse.json({ product: updatedProduct })
  } catch (error) {
    console.error('Update product error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// DELETE /api/marketplace/products/[id] - Delete product (Provider only)
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    // Get user from auth header (you'll need to implement this)
    const userId = 'placeholder-user-id' // TODO: Get from auth

    // Verify user owns this product
    const { data: product, error: productError } = await supabase
      .from('products')
      .select(`
        *,
        provider_profiles!inner(user_id)
      `)
      .eq('id', id)
      .single()

    if (productError || !product) {
      return NextResponse.json({ error: 'Product not found' }, { status: 404 })
    }

    if (product.provider_profiles.user_id !== userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })
    }

    // Soft delete by setting is_active to false
    const { error } = await supabase
      .from('products')
      .update({ is_active: false })
      .eq('id', id)

    if (error) {
      console.error('Error deleting product:', error)
      return NextResponse.json({ error: 'Failed to delete product' }, { status: 500 })
    }

    return NextResponse.json({ message: 'Product deleted successfully' })
  } catch (error) {
    console.error('Delete product error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
