import axios from 'axios'

const API_BASE_URL = '/api/marketplace'

export interface Product {
  id: string
  name: string
  description: string
  price: number
  discount_price?: number
  stock_quantity: number
  min_order_quantity: number
  unit: string
  images: string[]
  specifications: Record<string, unknown>
  is_active: boolean
  is_featured: boolean
  rating_avg: number
  review_count: number
  product_type: 'buyable' | 'rentable'
  rental_price_per_day?: number
  rental_price_per_week?: number
  rental_price_per_month?: number
  min_rental_days?: number
  max_rental_days?: number
  requires_deposit?: boolean
  deposit_amount?: number
  created_at: string
  updated_at: string
  provider_profiles: {
    id: string
    business_name: string
    city: string
    state: string
    rating_avg: number
    verification_status: string
  }
  categories: {
    id: string
    name: string
  }
}

export interface Category {
  id: string
  name: string
  description: string
  parent_id?: string
  image_url?: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface Order {
  id: string
  farmer_id: string
  provider_id: string
  order_number: string
  status: 'pending' | 'confirmed' | 'shipped' | 'delivered' | 'cancelled'
  total_amount: number
  payment_status: 'pending' | 'paid' | 'failed' | 'refunded'
  payment_method?: string
  shipping_address: Record<string, unknown>
  delivery_date?: string
  notes?: string
  created_at: string
  updated_at: string
  provider_profiles: {
    id: string
    business_name: string
    city: string
    state: string
    phone: string
  }
  order_items: Array<{
    id: string
    quantity: number
    unit_price: number
    total_price: number
    products: {
      id: string
      name: string
      images: string[]
      unit: string
    }
  }>
}

export interface Provider {
  id: string
  user_id: string
  business_name: string
  description: string
  business_type: 'individual' | 'company' | 'cooperative'
  address: string
  city: string
  state: string
  pincode: string
  phone: string
  gst_number?: string
  license_number?: string
  rating_avg: number
  total_orders: number
  verification_status: 'pending' | 'verified' | 'rejected'
  created_at: string
  updated_at: string
  products: Product[]
}

export interface WishlistItem {
  id: string
  farmer_id: string
  product_id: string
  created_at: string
  products: Product
}

export interface RentalBooking {
  id: string
  farmer_id: string
  provider_id: string
  product_id: string
  start_date: string
  end_date: string
  total_days: number
  rental_rate_type: 'daily' | 'weekly' | 'monthly'
  rate_per_period: number
  total_amount: number
  deposit_amount: number
  status: 'pending' | 'confirmed' | 'active' | 'completed' | 'cancelled'
  payment_status: 'pending' | 'paid' | 'failed' | 'refunded'
  delivery_address?: Record<string, unknown>
  pickup_address?: Record<string, unknown>
  notes?: string
  created_at: string
  updated_at: string
  provider_profiles: {
    id: string
    business_name: string
    city: string
    state: string
    phone: string
  }
  products: {
    id: string
    name: string
    images: string[]
    product_type: string
  }
}

export interface RentalAvailability {
  id: string
  product_id: string
  date: string
  is_available: boolean
  created_at: string
}

export class MarketplaceService {
  private static instance: MarketplaceService

  private constructor() {}

  public static getInstance(): MarketplaceService {
    if (!MarketplaceService.instance) {
      MarketplaceService.instance = new MarketplaceService()
    }
    return MarketplaceService.instance
  }

  // Products
  async getProducts(params?: {
    category?: string
    search?: string
    minPrice?: number
    maxPrice?: number
    location?: string
    sortBy?: string
    sortOrder?: 'asc' | 'desc'
    page?: number
    limit?: number
  }) {
    try {
      const searchParams = new URLSearchParams()
      if (params) {
        Object.entries(params).forEach(([key, value]) => {
          if (value !== undefined && value !== null) {
            searchParams.append(key, value.toString())
          }
        })
      }

      const response = await axios.get(`${API_BASE_URL}/products?${searchParams}`)
      return response.data
    } catch (error) {
      console.error('Error fetching products:', error)
      throw error
    }
  }

  async getProduct(id: string) {
    try {
      const response = await axios.get(`${API_BASE_URL}/products/${id}`)
      return response.data
    } catch (error) {
      console.error('Error fetching product:', error)
      throw error
    }
  }

  async createProduct(productData: Partial<Product>) {
    try {
      const response = await axios.post(`${API_BASE_URL}/products`, productData)
      return response.data
    } catch (error) {
      console.error('Error creating product:', error)
      throw error
    }
  }

  async updateProduct(id: string, productData: Partial<Product>) {
    try {
      const response = await axios.put(`${API_BASE_URL}/products/${id}`, productData)
      return response.data
    } catch (error) {
      console.error('Error updating product:', error)
      throw error
    }
  }

  async deleteProduct(id: string) {
    try {
      const response = await axios.delete(`${API_BASE_URL}/products/${id}`)
      return response.data
    } catch (error) {
      console.error('Error deleting product:', error)
      throw error
    }
  }

  // Categories
  async getCategories() {
    try {
      const response = await axios.get(`${API_BASE_URL}/categories`)
      return response.data
    } catch (error) {
      console.error('Error fetching categories:', error)
      throw error
    }
  }

  async createCategory(categoryData: Partial<Category>) {
    try {
      const response = await axios.post(`${API_BASE_URL}/categories`, categoryData)
      return response.data
    } catch (error) {
      console.error('Error creating category:', error)
      throw error
    }
  }

  // Orders
  async getOrders(params?: {
    status?: string
    page?: number
    limit?: number
  }) {
    try {
      const searchParams = new URLSearchParams()
      if (params) {
        Object.entries(params).forEach(([key, value]) => {
          if (value !== undefined && value !== null) {
            searchParams.append(key, value.toString())
          }
        })
      }

      const response = await axios.get(`${API_BASE_URL}/orders?${searchParams}`)
      return response.data
    } catch (error) {
      console.error('Error fetching orders:', error)
      throw error
    }
  }

  async createOrder(orderData: {
    provider_id: string
    items: Array<{
      product_id: string
      quantity: number
      unit_price: number
    }>
    shipping_address: Record<string, unknown>
    notes?: string
  }) {
    try {
      const response = await axios.post(`${API_BASE_URL}/orders`, orderData)
      return response.data
    } catch (error) {
      console.error('Error creating order:', error)
      throw error
    }
  }

  // Providers
  async getProviders(params?: {
    location?: string
    verified?: boolean
    page?: number
    limit?: number
  }) {
    try {
      const searchParams = new URLSearchParams()
      if (params) {
        Object.entries(params).forEach(([key, value]) => {
          if (value !== undefined && value !== null) {
            searchParams.append(key, value.toString())
          }
        })
      }

      const response = await axios.get(`${API_BASE_URL}/providers?${searchParams}`)
      return response.data
    } catch (error) {
      console.error('Error fetching providers:', error)
      throw error
    }
  }

  async createProvider(providerData: Partial<Provider>) {
    try {
      const response = await axios.post(`${API_BASE_URL}/providers`, providerData)
      return response.data
    } catch (error) {
      console.error('Error creating provider:', error)
      throw error
    }
  }

  // Wishlist
  async getWishlist() {
    try {
      const response = await axios.get(`${API_BASE_URL}/wishlist`)
      return response.data
    } catch (error) {
      console.error('Error fetching wishlist:', error)
      throw error
    }
  }

  async addToWishlist(productId: string) {
    try {
      const response = await axios.post(`${API_BASE_URL}/wishlist`, {
        product_id: productId
      })
      return response.data
    } catch (error) {
      console.error('Error adding to wishlist:', error)
      throw error
    }
  }

  async removeFromWishlist(productId: string) {
    try {
      const response = await axios.delete(`${API_BASE_URL}/wishlist?product_id=${productId}`)
      return response.data
    } catch (error) {
      console.error('Error removing from wishlist:', error)
      throw error
    }
  }

  // Rental Bookings
  async getRentals(params?: {
    status?: string
    page?: number
    limit?: number
  }) {
    try {
      const searchParams = new URLSearchParams()
      if (params) {
        Object.entries(params).forEach(([key, value]) => {
          if (value !== undefined && value !== null) {
            searchParams.append(key, value.toString())
          }
        })
      }

      const response = await axios.get(`${API_BASE_URL}/rentals?${searchParams}`)
      return response.data
    } catch (error) {
      console.error('Error fetching rentals:', error)
      throw error
    }
  }

  async createRental(rentalData: {
    product_id: string
    start_date: string
    end_date: string
    rental_rate_type: 'daily' | 'weekly' | 'monthly'
    delivery_address?: Record<string, unknown>
    pickup_address?: Record<string, unknown>
    notes?: string
  }) {
    try {
      const response = await axios.post(`${API_BASE_URL}/rentals`, rentalData)
      return response.data
    } catch (error) {
      console.error('Error creating rental:', error)
      throw error
    }
  }

  // Rental Availability
  async getRentalAvailability(params: {
    product_id: string
    start_date?: string
    end_date?: string
  }) {
    try {
      const searchParams = new URLSearchParams()
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          searchParams.append(key, value.toString())
        }
      })

      const response = await axios.get(`${API_BASE_URL}/rentals/availability?${searchParams}`)
      return response.data
    } catch (error) {
      console.error('Error fetching rental availability:', error)
      throw error
    }
  }

  async updateRentalAvailability(availabilityData: {
    product_id: string
    date: string
    is_available: boolean
  }) {
    try {
      const response = await axios.post(`${API_BASE_URL}/rentals/availability`, availabilityData)
      return response.data
    } catch (error) {
      console.error('Error updating rental availability:', error)
      throw error
    }
  }
}
