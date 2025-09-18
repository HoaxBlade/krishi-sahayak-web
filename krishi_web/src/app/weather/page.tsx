'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { 
  MapPin,
  TrendingUp, 
  Package,
  Users,
  Calendar,
  Filter,
  Search,
  Target
} from 'lucide-react'

interface RegionalRequirement {
  id: string
  region: string
  state: string
  cropType: string
  demandLevel: 'High' | 'Medium' | 'Low'
  quantity: number
  unit: string
  season: string
  priority: 'Urgent' | 'Normal' | 'Low'
  lastUpdated: string
  farmerCount: number
}

interface EquipmentRequirement {
  id: string
  equipment: string
  region: string
  demandLevel: 'High' | 'Medium' | 'Low'
  rentalPrice: number
  availability: 'Available' | 'Limited' | 'Out of Stock'
  season: string
}

export default function RequirementsPage() {
  const [selectedRegion, setSelectedRegion] = useState('All')
  const [selectedSeason, setSelectedSeason] = useState('All')
  const [searchQuery, setSearchQuery] = useState('')

  // Sample data for regional requirements
  const requirements: RegionalRequirement[] = [
    {
      id: '1',
      region: 'Punjab',
      state: 'Punjab',
      cropType: 'Wheat',
      demandLevel: 'High',
      quantity: 1500,
      unit: 'quintals',
      season: 'Rabi',
      priority: 'Urgent',
      lastUpdated: new Date().toISOString(),
      farmerCount: 245
    },
    {
      id: '2',
      region: 'Haryana',
      state: 'Haryana',
      cropType: 'Rice',
      demandLevel: 'High',
      quantity: 1200,
      unit: 'quintals',
      season: 'Kharif',
      priority: 'Urgent',
      lastUpdated: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
      farmerCount: 189
    },
    {
      id: '3',
      region: 'Uttar Pradesh',
      state: 'Uttar Pradesh',
      cropType: 'Sugarcane',
      demandLevel: 'Medium',
      quantity: 800,
      unit: 'tons',
      season: 'Kharif',
      priority: 'Normal',
      lastUpdated: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
      farmerCount: 156
    },
    {
      id: '4',
      region: 'Maharashtra',
      state: 'Maharashtra',
      cropType: 'Cotton',
      demandLevel: 'High',
      quantity: 900,
      unit: 'bales',
      season: 'Kharif',
      priority: 'Urgent',
      lastUpdated: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString(),
      farmerCount: 203
    },
    {
      id: '5',
      region: 'Karnataka',
      state: 'Karnataka',
      cropType: 'Coffee',
      demandLevel: 'Medium',
      quantity: 600,
      unit: 'kg',
      season: 'Rabi',
      priority: 'Normal',
      lastUpdated: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString(),
      farmerCount: 98
    }
  ]

  const equipmentRequirements: EquipmentRequirement[] = [
    {
      id: '1',
      equipment: 'Tractor',
      region: 'Punjab',
      demandLevel: 'High',
      rentalPrice: 2500,
      availability: 'Available',
      season: 'Rabi'
    },
    {
      id: '2',
      equipment: 'Harvester',
      region: 'Haryana',
      demandLevel: 'High',
      rentalPrice: 5000,
      availability: 'Limited',
      season: 'Kharif'
    },
    {
      id: '3',
      equipment: 'Irrigation Pump',
      region: 'Uttar Pradesh',
      demandLevel: 'Medium',
      rentalPrice: 800,
      availability: 'Available',
      season: 'Kharif'
    },
    {
      id: '4',
      equipment: 'Sprayer',
      region: 'Maharashtra',
      demandLevel: 'High',
      rentalPrice: 1200,
      availability: 'Out of Stock',
      season: 'Kharif'
    }
  ]

  const regions = ['All', 'Punjab', 'Haryana', 'Uttar Pradesh', 'Maharashtra', 'Karnataka', 'Tamil Nadu', 'Gujarat']
  const seasons = ['All', 'Kharif', 'Rabi', 'Zaid']

  const getDemandColor = (level: string) => {
    switch (level) {
      case 'High': return 'text-red-600 bg-red-100'
      case 'Medium': return 'text-yellow-600 bg-yellow-100'
      case 'Low': return 'text-green-600 bg-green-100'
      default: return 'text-gray-600 bg-gray-100'
    }
  }

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'Urgent': return 'text-red-600 bg-red-100'
      case 'Normal': return 'text-blue-600 bg-blue-100'
      case 'Low': return 'text-gray-600 bg-gray-100'
      default: return 'text-gray-600 bg-gray-100'
    }
  }

  const getAvailabilityColor = (availability: string) => {
    switch (availability) {
      case 'Available': return 'text-green-600 bg-green-100'
      case 'Limited': return 'text-yellow-600 bg-yellow-100'
      case 'Out of Stock': return 'text-red-600 bg-red-100'
      default: return 'text-gray-600 bg-gray-100'
    }
  }

  const filteredRequirements = requirements.filter(req => {
    const matchesRegion = selectedRegion === 'All' || req.region === selectedRegion
    const matchesSeason = selectedSeason === 'All' || req.season === selectedSeason
    const matchesSearch = searchQuery === '' || 
      req.cropType.toLowerCase().includes(searchQuery.toLowerCase()) ||
      req.region.toLowerCase().includes(searchQuery.toLowerCase())
    
    return matchesRegion && matchesSeason && matchesSearch
  })

  const filteredEquipment = equipmentRequirements.filter(eq => {
    const matchesRegion = selectedRegion === 'All' || eq.region === selectedRegion
    const matchesSeason = selectedSeason === 'All' || eq.season === selectedSeason
    const matchesSearch = searchQuery === '' || 
      eq.equipment.toLowerCase().includes(searchQuery.toLowerCase()) ||
      eq.region.toLowerCase().includes(searchQuery.toLowerCase())
    
    return matchesRegion && matchesSeason && matchesSearch
  })

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="text-center mb-10">
          <h1 className="text-3xl font-bold text-gray-900 mb-3">
            Regional Requirements
          </h1>
          <p className="text-lg text-gray-600">
            Discover what farmers need in different regions to plan your inventory
          </p>
        </div>

        {/* Filters and Search */}
        <motion.div
          className="bg-white rounded-xl shadow-lg p-6 mb-8"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            {/* Search */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
              <input
                type="text"
                placeholder="Search crops or regions..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent text-black"
              />
            </div>

            {/* Region Filter */}
            <select
              value={selectedRegion}
              onChange={(e) => setSelectedRegion(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent text-black"
            >
              {regions.map(region => (
                <option key={region} value={region}>{region}</option>
              ))}
            </select>

            {/* Season Filter */}
            <select
              value={selectedSeason}
              onChange={(e) => setSelectedSeason(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent text-black"
            >
              {seasons.map(season => (
                <option key={season} value={season}>{season}</option>
              ))}
            </select>

            {/* Clear Filters */}
              <button
                onClick={() => {
                setSelectedRegion('All')
                setSelectedSeason('All')
                setSearchQuery('')
              }}
              className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors flex items-center justify-center"
            >
              <Filter className="w-4 h-4 mr-2" />
              Clear
              </button>
          </div>
        </motion.div>

        {/* Crop Requirements */}
        <motion.div
          className="bg-white rounded-xl shadow-lg p-6 mb-8"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
        >
          <h2 className="text-xl font-semibold text-gray-900 mb-6 flex items-center">
            <Target className="w-6 h-6 mr-2 text-green-600" />
            Crop Requirements by Region
          </h2>
          
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="text-left py-3 px-4 font-medium text-gray-700">Region</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-700">Crop</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-700">Demand</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-700">Quantity</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-700">Season</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-700">Priority</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-700">Farmers</th>
                </tr>
              </thead>
              <tbody>
                {filteredRequirements.map((req) => (
                  <motion.tr
                    key={req.id}
                    className="border-b border-gray-100 hover:bg-gray-50"
                    whileHover={{ scale: 1.01 }}
                    transition={{ type: "spring", stiffness: 400, damping: 10 }}
                  >
                    <td className="py-4 px-4">
                      <div className="flex items-center">
                        <MapPin className="w-4 h-4 text-gray-400 mr-2" />
                        <span className="font-medium text-gray-900">{req.region}</span>
        </div>
                    </td>
                    <td className="py-4 px-4">
                      <span className="text-gray-900">{req.cropType}</span>
                    </td>
                    <td className="py-4 px-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getDemandColor(req.demandLevel)}`}>
                        {req.demandLevel}
                      </span>
                    </td>
                    <td className="py-4 px-4">
                      <span className="text-gray-900">{req.quantity.toLocaleString()} {req.unit}</span>
                    </td>
                    <td className="py-4 px-4">
                      <span className="text-gray-600">{req.season}</span>
                    </td>
                    <td className="py-4 px-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getPriorityColor(req.priority)}`}>
                        {req.priority}
                      </span>
                    </td>
                    <td className="py-4 px-4">
                      <div className="flex items-center">
                        <Users className="w-4 h-4 text-gray-400 mr-1" />
                        <span className="text-gray-900">{req.farmerCount}</span>
          </div>
                    </td>
                  </motion.tr>
                ))}
              </tbody>
            </table>
          </div>
        </motion.div>

        {/* Equipment Requirements */}
            <motion.div 
          className="bg-white rounded-xl shadow-lg p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
        >
          <h2 className="text-xl font-semibold text-gray-900 mb-6 flex items-center">
            <Package className="w-6 h-6 mr-2 text-blue-600" />
            Equipment Requirements
                  </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredEquipment.map((equipment) => (
              <motion.div
                key={equipment.id}
                className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
                whileHover={{ scale: 1.02 }}
                transition={{ type: "spring", stiffness: 400, damping: 10 }}
              >
                <div className="flex items-center justify-between mb-3">
                  <h3 className="font-semibold text-gray-900">{equipment.equipment}</h3>
                  <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getDemandColor(equipment.demandLevel)}`}>
                    {equipment.demandLevel}
                  </span>
              </div>

                <div className="space-y-2">
                  <div className="flex items-center text-sm text-gray-600">
                    <MapPin className="w-4 h-4 mr-2" />
                    {equipment.region}
                </div>

                  <div className="flex items-center text-sm text-gray-600">
                    <Calendar className="w-4 h-4 mr-2" />
                    {equipment.season}
                </div>

                  <div className="flex items-center text-sm text-gray-600">
                    <TrendingUp className="w-4 h-4 mr-2" />
                    ₹{equipment.rentalPrice.toLocaleString()}/day
                </div>

                  <div className="flex items-center text-sm">
                    <span className="mr-2">Availability:</span>
                    <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getAvailabilityColor(equipment.availability)}`}>
                      {equipment.availability}
                    </span>
                </div>
              </div>
            </motion.div>
            ))}
          </div>
        </motion.div>
      </div>
    </div>
  )
}