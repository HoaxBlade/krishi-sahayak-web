import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

// GET /api/marketplace/categories - Get all categories
export async function GET() {
  try {
    const { data: categories, error } = await supabase
      .from('categories')
      .select('*')
      .eq('is_active', true)
      .order('name', { ascending: true })

    if (error) {
      console.error('Error fetching categories:', error)
      return NextResponse.json({ error: 'Failed to fetch categories' }, { status: 500 })
    }

    return NextResponse.json({ categories: categories || [] })
  } catch (error) {
    console.error('Categories API error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/marketplace/categories - Create new category (Admin only)
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { name, description, parent_id, image_url } = body

    const { data: category, error } = await supabase
      .from('categories')
      .insert({
        name,
        description,
        parent_id: parent_id || null,
        image_url
      })
      .select()
      .single()

    if (error) {
      console.error('Error creating category:', error)
      return NextResponse.json({ error: 'Failed to create category' }, { status: 500 })
    }

    return NextResponse.json({ category }, { status: 201 })
  } catch (error) {
    console.error('Create category error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
