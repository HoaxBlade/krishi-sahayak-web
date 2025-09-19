'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { 
  Package, 
  ShoppingCart, 
  Users, 
  AlertTriangle,
  IndianRupee,
  MessageSquare,
  Bell,
  Plus,
  ArrowUpRight,
  Calendar,
  Clock,
  Wrench
} from 'lucide-react'
import Link from 'next/link'
import ProtectedRoute from '@/components/ProtectedRoute'
import { useAuth } from '@/contexts/AuthContext'
import AddProductModal from '@/components/AddProductModal'

interface DashboardStats {
  total_orders: number
  pending_orders: number
  completed_orders: number
  total_revenue: number
  monthly_revenue: number
  total_products: number
  active_products: number
  low_stock_products: number
  total_customers: number
  new_customers_this_month: number
  average_order_value: number
  total_rentals: number
  active_rentals: number
  pending_rentals: number
  completed_rentals: number
  total_rental_revenue: number
  monthly_rental_revenue: number
}

interface RecentOrder {
  id: string
  order_number: string
  status: string
  total_amount: number
  created_at: string
  order_items: Array<{
    id: string
    quantity: number
    unit_price: number
    products: {
      id: string
      name: string
      images: string[]
    }
  }>
}

interface PendingRequest {
  id: string
  request_type: string
  subject: string
  status: string
  priority: string
  created_at: string
}

interface Notification {
  id: string
  type: string
  title: string
  message: string
  is_read: boolean
  action_url?: string
  created_at: string
}

interface LowStockProduct {
  id: string
  name: string
  stock_quantity: number
  images: string[]
}

interface RentalBooking {
  id: string
  start_date: string
  end_date: string
  status: string
  total_amount: number
  total_days: number
  rental_rate_type: string
  created_at: string
  products: {
    id: string
    name: string
    images: string[]
  }
}

export default function DashboardPage() {
  const { user } = useAuth()
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [recentOrders, setRecentOrders] = useState<RecentOrder[]>([])
  const [pendingRequests, setPendingRequests] = useState<PendingRequest[]>([])
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [lowStockProducts, setLowStockProducts] = useState<LowStockProduct[]>([])
  const [rentalBookings, setRentalBookings] = useState<RentalBooking[]>([])
  const [loading, setLoading] = useState(true)
  const [showAddProductModal, setShowAddProductModal] = useState(false)

  useEffect(() => {
    fetchDashboardData()
  }, [])

  const fetchDashboardData = async () => {
    try {
      setLoading(true)
      const response = await fetch('/api/supplier/dashboard')
      if (!response.ok) {
        throw new Error('Failed to fetch dashboard data')
      }
      const data = await response.json()
      
      setStats(data.stats)
      setRecentOrders(data.recentOrders)
      setPendingRequests(data.pendingRequests)
      setNotifications(data.notifications)
      setLowStockProducts(data.lowStockProducts)
      setRentalBookings(data.rentalBookings)
    } catch (error) {
      console.error('Error fetching dashboard data:', error)
    } finally {
      setLoading(false)
    }
  }

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'pending': return 'text-yellow-600 bg-yellow-100'
      case 'confirmed': return 'text-blue-600 bg-blue-100'
      case 'shipped': return 'text-purple-600 bg-purple-100'
      case 'delivered': return 'text-green-600 bg-green-100'
      case 'cancelled': return 'text-red-600 bg-red-100'
      default: return 'text-gray-600 bg-gray-100'
    }
  }

  const getPriorityColor = (priority: string) => {
    switch (priority.toLowerCase()) {
      case 'urgent': return 'text-red-600 bg-red-100'
      case 'high': return 'text-orange-600 bg-orange-100'
      case 'medium': return 'text-yellow-600 bg-yellow-100'
      case 'low': return 'text-green-600 bg-green-100'
      default: return 'text-gray-600 bg-gray-100'
    }
  }

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'new_order': return <ShoppingCart className="w-4 h-4" />
      case 'low_stock': return <AlertTriangle className="w-4 h-4" />
      case 'new_request': return <MessageSquare className="w-4 h-4" />
      case 'payment_received': return <IndianRupee className="w-4 h-4" />
      default: return <Bell className="w-4 h-4" />
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    )
  }

  return (
    <ProtectedRoute>
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          {/* Header */}
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-8 space-y-4 sm:space-y-0">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 mb-2">
                Supplier Dashboard
              </h1>
              <p className="text-lg text-gray-600">
                Manage your agricultural supply business
              </p>
            </div>
            <div className="flex flex-col sm:flex-row items-start sm:items-center space-y-2 sm:space-y-0 sm:space-x-4 w-full sm:w-auto">
              <span className="text-gray-600 text-sm sm:text-base">Hi {user?.user_metadata?.full_name || user?.email?.split('@')[0] || 'Supplier'}</span>
              <button
                onClick={() => setShowAddProductModal(true)}
                className="w-full sm:w-auto bg-green-600 text-white px-6 py-2 rounded-lg font-medium hover:bg-green-700 transition-colors flex items-center justify-center space-x-2"
              >
                <Plus className="w-4 h-4" />
                <span>Add Product</span>
              </button>
            </div>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-3 gap-6 mb-8">
            <motion.div
              className="bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Total Orders</p>
                  <p className="text-3xl font-bold text-gray-900">{stats?.total_orders || 0}</p>
                </div>
                <div className="p-3 bg-blue-100 rounded-lg">
                  <ShoppingCart className="w-6 h-6 text-blue-600" />
                </div>
              </div>
              <div className="mt-4 flex items-center">
                <ArrowUpRight className="w-4 h-4 text-green-500 mr-1" />
                <span className="text-sm text-green-600">{stats?.pending_orders || 0} pending</span>
              </div>
            </motion.div>

            <motion.div
              className="bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Total Revenue</p>
                  <p className="text-3xl font-bold text-gray-900">₹{(stats?.total_revenue || 0).toLocaleString()}</p>
                </div>
                <div className="p-3 bg-green-100 rounded-lg">
                  <IndianRupee className="w-6 h-6 text-green-600" />
                </div>
              </div>
              <div className="mt-4 flex items-center">
                <ArrowUpRight className="w-4 h-4 text-green-500 mr-1" />
                <span className="text-sm text-green-600">₹{(stats?.monthly_revenue || 0).toLocaleString()} this month</span>
              </div>
            </motion.div>

            <motion.div
              className="bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.2 }}
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Total Products</p>
                  <p className="text-3xl font-bold text-gray-900">{stats?.total_products || 0}</p>
                </div>
                <div className="p-3 bg-purple-100 rounded-lg">
                  <Package className="w-6 h-6 text-purple-600" />
                </div>
              </div>
              <div className="mt-4 flex items-center">
                <span className="text-sm text-gray-600">{stats?.active_products || 0} active</span>
              </div>
            </motion.div>

            <motion.div
              className="bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.3 }}
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Total Customers</p>
                  <p className="text-3xl font-bold text-gray-900">{stats?.total_customers || 0}</p>
                </div>
                <div className="p-3 bg-orange-100 rounded-lg">
                  <Users className="w-6 h-6 text-orange-600" />
                </div>
              </div>
              <div className="mt-4 flex items-center">
                <ArrowUpRight className="w-4 h-4 text-green-500 mr-1" />
                <span className="text-sm text-green-600">{stats?.new_customers_this_month || 0} new this month</span>
              </div>
            </motion.div>

            <motion.div
              className="bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.4 }}
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Total Rentals</p>
                  <p className="text-3xl font-bold text-gray-900">{stats?.total_rentals || 0}</p>
                </div>
                <div className="p-3 bg-purple-100 rounded-lg">
                  <Calendar className="w-6 h-6 text-purple-600" />
                </div>
              </div>
              <div className="mt-4 flex items-center">
                <ArrowUpRight className="w-4 h-4 text-green-500 mr-1" />
                <span className="text-sm text-green-600">{stats?.active_rentals || 0} active</span>
              </div>
            </motion.div>

            <motion.div
              className="bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.5 }}
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Rental Revenue</p>
                  <p className="text-3xl font-bold text-gray-900">₹{(stats?.total_rental_revenue || 0).toLocaleString()}</p>
                </div>
                <div className="p-3 bg-indigo-100 rounded-lg">
                  <Wrench className="w-6 h-6 text-indigo-600" />
                </div>
              </div>
              <div className="mt-4 flex items-center">
                <ArrowUpRight className="w-4 h-4 text-green-500 mr-1" />
                <span className="text-sm text-green-600">₹{(stats?.monthly_rental_revenue || 0).toLocaleString()} this month</span>
              </div>
            </motion.div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 lg:gap-8">
            {/* Recent Orders */}
            <motion.div
              className="lg:col-span-2 bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.4 }}
            >
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-semibold text-gray-900 flex items-center">
                  <ShoppingCart className="w-6 h-6 mr-2 text-blue-600" />
                  Recent Orders
                </h2>
                <Link href="/marketplace/orders" className="text-green-600 hover:text-green-700 text-sm font-medium">
                  View All
                </Link>
              </div>
              
              <div className="space-y-4">
                {recentOrders.length > 0 ? recentOrders.map((order) => (
                  <motion.div
                    key={order.id}
                    className="flex flex-col sm:flex-row items-start sm:items-center justify-between p-4 border border-gray-100 rounded-lg hover:bg-gray-50 space-y-2 sm:space-y-0"
                    whileHover={{ scale: 1.01 }}
                    transition={{ type: "spring", stiffness: 400, damping: 10 }}
                  >
                    <div className="flex items-center space-x-4">
                      <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center">
                        <ShoppingCart className="w-5 h-5 text-gray-600" />
                      </div>
                      <div>
                        <p className="font-medium text-gray-900">{order.order_number}</p>
                        <p className="text-sm text-gray-500">
                          {order.order_items.length} item{order.order_items.length !== 1 ? 's' : ''}
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="font-medium text-gray-900">₹{order.total_amount.toLocaleString()}</p>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(order.status)}`}>
                        {order.status}
                      </span>
                    </div>
                  </motion.div>
                )) : (
                  <div className="text-center py-8 text-gray-500">
                    <ShoppingCart className="w-12 h-12 mx-auto mb-4 text-gray-300" />
                    <p>No recent orders</p>
                  </div>
                )}
              </div>
            </motion.div>

            {/* Sidebar */}
            <div className="space-y-6">
              {/* Pending Requests */}
              <motion.div
                className="bg-white rounded-xl shadow-lg p-6"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.5 }}
              >
                <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                  <MessageSquare className="w-5 h-5 mr-2 text-orange-600" />
                  Pending Requests
                </h3>
                
                <div className="space-y-3">
                  {pendingRequests.length > 0 ? pendingRequests.map((request) => (
                    <div key={request.id} className="p-3 border border-gray-100 rounded-lg">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm font-medium text-gray-900">{request.subject}</span>
                        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getPriorityColor(request.priority)}`}>
                          {request.priority}
                        </span>
                      </div>
                      <p className="text-xs text-gray-500 capitalize">{request.request_type.replace('_', ' ')}</p>
                    </div>
                  )) : (
                    <p className="text-sm text-gray-500">No pending requests</p>
                  )}
                </div>
              </motion.div>

              {/* Low Stock Alert */}
              {lowStockProducts.length > 0 && (
                <motion.div
                  className="bg-white rounded-xl shadow-lg p-6"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.5, delay: 0.6 }}
                >
                  <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                    <AlertTriangle className="w-5 h-5 mr-2 text-red-600" />
                    Low Stock Alert
                  </h3>
                  
                  <div className="space-y-3">
                    {lowStockProducts.map((product) => (
                      <div key={product.id} className="p-3 border border-red-100 rounded-lg bg-red-50">
                        <p className="text-sm font-medium text-gray-900">{product.name}</p>
                        <p className="text-xs text-red-600">Only {product.stock_quantity} left</p>
                      </div>
                    ))}
                  </div>
                </motion.div>
              )}

              {/* Notifications */}
              <motion.div
                className="bg-white rounded-xl shadow-lg p-6"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.7 }}
              >
                <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                  <Bell className="w-5 h-5 mr-2 text-blue-600" />
                  Notifications
                </h3>
                
                <div className="space-y-3">
                  {notifications.length > 0 ? notifications.map((notification) => (
                    <div key={notification.id} className="p-3 border border-gray-100 rounded-lg">
                      <div className="flex items-start space-x-3">
                        <div className="flex-shrink-0">
                          {getNotificationIcon(notification.type)}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-gray-900">{notification.title}</p>
                          <p className="text-xs text-gray-500">{notification.message}</p>
                        </div>
                      </div>
                    </div>
                  )) : (
                    <p className="text-sm text-gray-500">No new notifications</p>
                  )}
                </div>
              </motion.div>

              {/* Rental Bookings */}
              <motion.div
                className="bg-white rounded-xl shadow-lg p-6"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.8 }}
              >
                <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                  <Calendar className="w-5 h-5 mr-2 text-purple-600" />
                  Recent Rentals
                </h3>
                
                <div className="space-y-3">
                  {rentalBookings.length > 0 ? rentalBookings.map((rental) => (
                    <div key={rental.id} className="p-3 border border-gray-100 rounded-lg">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm font-medium text-gray-900">{rental.products.name}</span>
                        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(rental.status)}`}>
                          {rental.status}
                        </span>
                      </div>
                      <div className="flex items-center justify-between text-xs text-gray-500">
                        <span>{rental.total_days} days</span>
                        <span>₹{rental.total_amount.toLocaleString()}</span>
                      </div>
                      <div className="flex items-center text-xs text-gray-500 mt-1">
                        <Clock className="w-3 h-3 mr-1" />
                        <span>{new Date(rental.start_date).toLocaleDateString()} - {new Date(rental.end_date).toLocaleDateString()}</span>
                      </div>
                    </div>
                  )) : (
                    <p className="text-sm text-gray-500">No recent rentals</p>
                  )}
                </div>
              </motion.div>
            </div>
          </div>

          {/* Add Product Modal */}
          <AddProductModal 
            isOpen={showAddProductModal}
            onClose={() => setShowAddProductModal(false)}
          />
        </div>
      </div>
    </ProtectedRoute>
  )
}