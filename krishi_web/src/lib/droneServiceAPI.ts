import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

const supabase = createClient(supabaseUrl, supabaseAnonKey)

export interface DroneService {
  id?: string
  name: string
  description: string
  serviceType: string
  pricePerHour: number
  coverageArea: string
  availability: string
  features: string[]
  images: string[] | File[]
  contactInfo: {
    phone: string
    email: string
  }
  location: {
    address: string
    city: string
    state: string
    pincode: string
  }
  isActive?: boolean
  createdAt?: string
  updatedAt?: string
  user?: {
    id: string
    email: string
    user_metadata: Record<string, unknown>
  }
}

export interface DroneServiceFilters {
  serviceType?: string
  city?: string
  state?: string
  limit?: number
  offset?: number
}

class DroneServiceAPI {
  private static instance: DroneServiceAPI

  static getInstance(): DroneServiceAPI {
    if (!DroneServiceAPI.instance) {
      DroneServiceAPI.instance = new DroneServiceAPI()
    }
    return DroneServiceAPI.instance
  }

  private async getAuthHeaders() {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session?.access_token) {
      throw new Error('No active session')
    }
    return {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json'
    }
  }

  async createService(serviceData: DroneService): Promise<DroneService> {
    try {
      const headers = await this.getAuthHeaders()
      
      const response = await fetch('/api/drone/services', {
        method: 'POST',
        headers,
        body: JSON.stringify(serviceData)
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to create drone service')
      }

      const result = await response.json()
      return result.service
    } catch (error) {
      console.error('Error creating drone service:', error)
      throw error
    }
  }

  async getServices(filters?: DroneServiceFilters): Promise<DroneService[]> {
    try {
      const params = new URLSearchParams()
      
      if (filters?.serviceType) params.append('service_type', filters.serviceType)
      if (filters?.city) params.append('city', filters.city)
      if (filters?.state) params.append('state', filters.state)
      if (filters?.limit) params.append('limit', filters.limit.toString())
      if (filters?.offset) params.append('offset', filters.offset.toString())

      const response = await fetch(`/api/drone/services?${params.toString()}`)
      
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to fetch drone services')
      }

      const result = await response.json()
      return result.services
    } catch (error) {
      console.error('Error fetching drone services:', error)
      throw error
    }
  }

  async updateService(id: string, updateData: Partial<DroneService>): Promise<DroneService> {
    try {
      const headers = await this.getAuthHeaders()
      
      const response = await fetch('/api/drone/services', {
        method: 'PUT',
        headers,
        body: JSON.stringify({ id, ...updateData })
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to update drone service')
      }

      const result = await response.json()
      return result.service
    } catch (error) {
      console.error('Error updating drone service:', error)
      throw error
    }
  }

  async deleteService(id: string): Promise<void> {
    try {
      const headers = await this.getAuthHeaders()
      
      const response = await fetch(`/api/drone/services?id=${id}`, {
        method: 'DELETE',
        headers
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to delete drone service')
      }
    } catch (error) {
      console.error('Error deleting drone service:', error)
      throw error
    }
  }

  async getUserServices(): Promise<DroneService[]> {
    try {
      const headers = await this.getAuthHeaders()
      
      const response = await fetch('/api/drone/services', {
        method: 'GET',
        headers
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to fetch user services')
      }

      const result = await response.json()
      return result.services
    } catch (error) {
      console.error('Error fetching user services:', error)
      throw error
    }
  }
}

export default DroneServiceAPI
