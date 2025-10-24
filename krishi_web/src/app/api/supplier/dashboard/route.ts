/* eslint-disable @typescript-eslint/no-explicit-any */
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
  }
  
  // Fallback to placeholder for now
  return '00000000-0000-0000-0000-000000000001'
}

export async function GET(request: NextRequest) {
  try {
    // Get actual user ID from request
    const userId = await getUserIdFromRequest(request)

    // Fetch real data from database

    // Calculate stats dynamically from actual data
    // eslint-disable-next-line prefer-const
    let stats = {
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

    // Calculate order stats
    try {
      const { data: ordersData, error: ordersError } = await supabase
        .from('orders')
        .select('status, total_amount, created_at')
        .eq('provider_id', userId)

      if (!ordersError && ordersData) {
        const now = new Date()
        const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1)
        
        stats.total_orders = ordersData.length
        stats.pending_orders = ordersData.filter(o => o.status === 'pending').length
        stats.completed_orders = ordersData.filter(o => o.status === 'delivered').length
        stats.total_revenue = ordersData.reduce((sum, o) => sum + (o.total_amount || 0), 0)
        stats.monthly_revenue = ordersData
          .filter(o => new Date(o.created_at) >= thisMonth)
          .reduce((sum, o) => sum + (o.total_amount || 0), 0)
        stats.average_order_value = stats.total_orders > 0 ? stats.total_revenue / stats.total_orders : 0
      }
    } catch (error) {
      console.error('Error calculating order stats:', error)
    }

    // Calculate product stats (including both products and drone services)
    try {
      // Get regular products
      const { data: productsData, error: productsError } = await supabase
        .from('products')
        .select('stock_quantity, status')
        .eq('provider_id', userId)

      // Get drone services for this user
      const { data: droneServicesData, error: droneServicesError } = await supabase
        .from('drone_services')
        .select('is_active')
        .eq('user_id', userId)

      let totalProducts = 0
      let activeProducts = 0
      let lowStockProducts = 0

      // Count regular products
      if (!productsError && productsData) {
        totalProducts += productsData.length
        activeProducts += productsData.filter(p => p.status === 'active').length
        lowStockProducts += productsData.filter(p => p.stock_quantity <= 10).length
      }

      // Count drone services
      if (!droneServicesError && droneServicesData) {
        totalProducts += droneServicesData.length
        activeProducts += droneServicesData.filter(d => d.is_active === true).length
        // Drone services don't have stock, so no low stock count
      }

      stats.total_products = totalProducts
      stats.active_products = activeProducts
      stats.low_stock_products = lowStockProducts
    } catch (error) {
      console.error('Error calculating product stats:', error)
    }

    // Calculate customer stats
    try {
      const { data: customersData, error: customersError } = await supabase
        .from('orders')
        .select('farmer_id, created_at')
        .eq('provider_id', userId)

      if (!customersError && customersData) {
        const uniqueCustomers = new Set(customersData.map(o => o.farmer_id))
        stats.total_customers = uniqueCustomers.size
        
        const now = new Date()
        const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1)
        const thisMonthCustomers = new Set(
          customersData
            .filter(o => new Date(o.created_at) >= thisMonth)
            .map(o => o.farmer_id)
        )
        stats.new_customers_this_month = thisMonthCustomers.size
      }
    } catch (error) {
      console.error('Error calculating customer stats:', error)
    }

    // Stats will remain as zeros if no real data found

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
        .eq('provider_id', userId)
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
        .eq('supplier_id', userId)
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
        .eq('supplier_id', userId)
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

    // Get low stock products (including both products and drone services)
    let lowStockProducts: any[] = []
    try {
      // Get low stock regular products
      const { data: lowStockData, error: lowStockError } = await supabase
        .from('products')
        .select('id, name, stock_quantity, images')
        .eq('provider_id', userId)
        .lte('stock_quantity', 10)
        .order('stock_quantity', { ascending: true })
        .limit(5)

      if (lowStockError) {
        console.error('Error fetching low stock products:', lowStockError)
      } else {
        lowStockProducts = lowStockData || []
      }

      // Note: Drone services don't have stock quantities, so they don't appear in low stock alerts
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
        .eq('provider_id', userId)
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

    // Get recent drone services
    let recentDroneServices: any[] = []
    try {
      const { data: droneServicesData, error: droneServicesError } = await supabase
        .from('drone_services')
        .select(`
          id,
          name,
          service_type,
          price_per_hour,
          availability,
          is_active,
          created_at
        `)
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(5)

      if (droneServicesError) {
        console.error('Error fetching recent drone services:', droneServicesError)
      } else {
        recentDroneServices = droneServicesData || []
      }
    } catch (error) {
      console.error('Drone services table may not exist:', error)
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
        .eq('provider_id', userId)

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
      rentalBookings,
      recentDroneServices
    })

  } catch (error) {
    console.error('Dashboard API error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
