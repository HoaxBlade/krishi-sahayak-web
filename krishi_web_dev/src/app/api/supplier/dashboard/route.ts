/* eslint-disable @typescript-eslint/no-explicit-any */
import { NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

export async function GET() {
  try {
    // TODO: Get supplier_id from authentication
    const supplierId = 'placeholder-supplier-id' // Replace with actual auth

    // Try to get dashboard stats, but handle missing tables gracefully
    let stats = null
    try {
      const { data: statsData, error: statsError } = await supabase
        .from('supplier_dashboard_stats')
        .select('*')
        .eq('supplier_id', supplierId)
        .single()

      if (statsError && statsError.code !== 'PGRST116') {
        console.error('Error fetching dashboard stats:', statsError)
        // Continue with fallback data instead of failing
      } else {
        stats = statsData
      }
    } catch (error) {
      console.error('Dashboard stats table may not exist:', error)
      // Continue with fallback data
    }

    // If no stats exist or table doesn't exist, use empty data
    if (!stats) {
      stats = {
        total_orders: 0,
        pending_orders: 0,
        completed_orders: 0,
        total_revenue: 0,
        monthly_revenue: 0,
        total_products: 0,
        active_products: 0,
        low_stock_products: 0,
        total_customers: 0,
        new_customers_this_month: 0,
        average_order_value: 0
      }
    }

    // Get recent orders with error handling
    let recentOrders: any[] = []
    try {
      const { data: ordersData, error: ordersError } = await supabase
        .from('orders')
        .select(`
          id,
          order_number,
          status,
          total_amount,
          created_at,
          farmer_id,
          order_items(
            id,
            quantity,
            unit_price,
            products(
              id,
              name,
              images
            )
          )
        `)
        .eq('provider_id', supplierId)
        .order('created_at', { ascending: false })
        .limit(5)

      if (ordersError) {
        console.error('Error fetching recent orders:', ordersError)
      } else {
        recentOrders = ordersData || []
      }
    } catch (error) {
      console.error('Orders table may not exist:', error)
    }

    // recentOrders will be empty array if no data found

    // Get pending requests with error handling
    let pendingRequests: any[] = []
    try {
      const { data: requestsData, error: requestsError } = await supabase
        .from('supplier_requests')
        .select(`
          id,
          request_type,
          subject,
          status,
          priority,
          created_at,
          farmer_id
        `)
        .eq('supplier_id', supplierId)
        .eq('status', 'pending')
        .order('created_at', { ascending: false })
        .limit(5)

      if (requestsError) {
        console.error('Error fetching pending requests:', requestsError)
      } else {
        pendingRequests = requestsData || []
      }
    } catch (error) {
      console.error('Supplier requests table may not exist:', error)
    }

    // pendingRequests will be empty array if no data found

    // Get notifications with error handling
    let notifications: any[] = []
    try {
      const { data: notificationsData, error: notificationsError } = await supabase
        .from('supplier_notifications')
        .select('*')
        .eq('supplier_id', supplierId)
        .eq('is_read', false)
        .order('created_at', { ascending: false })
        .limit(10)

      if (notificationsError) {
        console.error('Error fetching notifications:', notificationsError)
      } else {
        notifications = notificationsData || []
      }
    } catch (error) {
      console.error('Supplier notifications table may not exist:', error)
    }

    // notifications will be empty array if no data found

    // Get low stock products with error handling
    let lowStockProducts: any[] = []
    try {
      const { data: lowStockData, error: lowStockError } = await supabase
        .from('products')
        .select('id, name, stock_quantity, images')
        .eq('provider_id', supplierId)
        .lte('stock_quantity', 10)
        .order('stock_quantity', { ascending: true })
        .limit(5)

      if (lowStockError) {
        console.error('Error fetching low stock products:', lowStockError)
      } else {
        lowStockProducts = lowStockData || []
      }
    } catch (error) {
      console.error('Products table may not exist:', error)
    }

    // lowStockProducts will be empty array if no data found

    // Get rental bookings with error handling
    let rentalBookings: any[] = []
    try {
      const { data: rentalsData, error: rentalsError } = await supabase
        .from('rental_bookings')
        .select(`
          id,
          start_date,
          end_date,
          status,
          total_amount,
          total_days,
          rental_rate_type,
          created_at,
          farmer_id,
          products(
            id,
            name,
            images
          )
        `)
        .eq('provider_id', supplierId)
        .order('created_at', { ascending: false })
        .limit(5)

      if (rentalsError) {
        console.error('Error fetching rental bookings:', rentalsError)
      } else {
        rentalBookings = rentalsData || []
      }
    } catch (error) {
      console.error('Rental bookings table may not exist:', error)
    }

    // Get rental stats
    let rentalStats = {
      total_rentals: 0,
      active_rentals: 0,
      pending_rentals: 0,
      completed_rentals: 0,
      total_rental_revenue: 0,
      monthly_rental_revenue: 0
    }

    try {
      const { data: rentalStatsData, error: rentalStatsError } = await supabase
        .from('rental_bookings')
        .select('status, total_amount, created_at')
        .eq('provider_id', supplierId)

      if (!rentalStatsError && rentalStatsData) {
        const now = new Date()
        const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1)
        
        rentalStats = {
          total_rentals: rentalStatsData.length,
          active_rentals: rentalStatsData.filter(r => r.status === 'active').length,
          pending_rentals: rentalStatsData.filter(r => r.status === 'pending').length,
          completed_rentals: rentalStatsData.filter(r => r.status === 'completed').length,
          total_rental_revenue: rentalStatsData.reduce((sum, r) => sum + (r.total_amount || 0), 0),
          monthly_rental_revenue: rentalStatsData
            .filter(r => new Date(r.created_at) >= thisMonth)
            .reduce((sum, r) => sum + (r.total_amount || 0), 0)
        }
      }
    } catch (error) {
      console.error('Error calculating rental stats:', error)
    }

    return NextResponse.json({
      stats: {
        ...stats,
        ...rentalStats
      },
      recentOrders,
      pendingRequests,
      notifications,
      lowStockProducts,
      rentalBookings
    })

  } catch (error) {
    console.error('Dashboard API error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
