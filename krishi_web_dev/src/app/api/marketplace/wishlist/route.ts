import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

// GET /api/marketplace/wishlist - Get user's wishlist
export async function GET() {
  try {
    // Get user from auth header (you'll need to implement this)
    const userId = 'placeholder-user-id' // TODO: Get from auth

    const { data: wishlist, error } = await supabase
      .from('wishlist')
      .select(`
        *,
        products!inner(
          id,
          name,
          price,
          discount_price,
          images,
          rating_avg,
          review_count,
          provider_profiles!inner(
            business_name,
            city,
            state
          )
        )
      `)
      .eq('farmer_id', userId)
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error fetching wishlist:', error)
      return NextResponse.json({ error: 'Failed to fetch wishlist' }, { status: 500 })
    }

    return NextResponse.json({ wishlist: wishlist || [] })
  } catch (error) {
    console.error('Wishlist API error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/marketplace/wishlist - Add item to wishlist
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { product_id } = body

    // Get user from auth header (you'll need to implement this)
    const userId = 'placeholder-user-id' // TODO: Get from auth

    // Check if item already exists in wishlist
    const { data: existingItem } = await supabase
      .from('wishlist')
      .select('id')
      .eq('farmer_id', userId)
      .eq('product_id', product_id)
      .single()

    if (existingItem) {
      return NextResponse.json({ error: 'Item already in wishlist' }, { status: 400 })
    }

    const { data: wishlistItem, error } = await supabase
      .from('wishlist')
      .insert({
        farmer_id: userId,
        product_id
      })
      .select()
      .single()

    if (error) {
      console.error('Error adding to wishlist:', error)
      return NextResponse.json({ error: 'Failed to add to wishlist' }, { status: 500 })
    }

    return NextResponse.json({ wishlistItem }, { status: 201 })
  } catch (error) {
    console.error('Add to wishlist error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// DELETE /api/marketplace/wishlist - Remove item from wishlist
export async function DELETE(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const product_id = searchParams.get('product_id')

    if (!product_id) {
      return NextResponse.json({ error: 'Product ID is required' }, { status: 400 })
    }

    // Get user from auth header (you'll need to implement this)
    const userId = 'placeholder-user-id' // TODO: Get from auth

    const { error } = await supabase
      .from('wishlist')
      .delete()
      .eq('farmer_id', userId)
      .eq('product_id', product_id)

    if (error) {
      console.error('Error removing from wishlist:', error)
      return NextResponse.json({ error: 'Failed to remove from wishlist' }, { status: 500 })
    }

    return NextResponse.json({ message: 'Item removed from wishlist' })
  } catch (error) {
    console.error('Remove from wishlist error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
