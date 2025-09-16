/* eslint-disable @typescript-eslint/no-unused-vars */
'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { 
  ShoppingCart, 
  Search, 
  Filter, 
  Star, 
  MapPin, 
  Phone,
  Heart,
  Share2
} from 'lucide-react'
import ProtectedRoute from '@/components/ProtectedRoute'
import { useAuth } from '@/contexts/AuthContext'

export default function MarketplacePage() {
  const { user } = useAuth()
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('all')

  const categories = [
    { id: 'all', name: 'All Products' },
    { id: 'crops', name: 'Fresh Crops' },
    { id: 'seeds', name: 'Seeds' },
    { id: 'fertilizers', name: 'Fertilizers' },
    { id: 'equipment', name: 'Equipment' },
    { id: 'tools', name: 'Tools' }
  ]

  // Sample products data
  const products = [
    {
      id: 1,
      name: 'Organic Tomatoes',
      price: 120,
      unit: 'per kg',
      seller: 'Rajesh Kumar',
      location: 'Punjab, India',
      rating: 4.8,
      reviews: 24,
      image: '/api/placeholder/300/200',
      category: 'crops',
      description: 'Fresh organic tomatoes grown without pesticides',
      available: 50
    },
    {
      id: 2,
      name: 'Wheat Seeds - Premium Quality',
      price: 450,
      unit: 'per 10kg bag',
      seller: 'Green Fields Farm',
      location: 'Haryana, India',
      rating: 4.9,
      reviews: 18,
      image: '/api/placeholder/300/200',
      category: 'seeds',
      description: 'High-yield wheat seeds for better harvest',
      available: 25
    },
    {
      id: 3,
      name: 'NPK Fertilizer 19-19-19',
      price: 800,
      unit: 'per 50kg bag',
      seller: 'Agro Solutions',
      location: 'Gujarat, India',
      rating: 4.7,
      reviews: 32,
      image: '/api/placeholder/300/200',
      category: 'fertilizers',
      description: 'Balanced NPK fertilizer for all crops',
      available: 15
    },
    {
      id: 4,
      name: 'Tractor Tiller Attachment',
      price: 25000,
      unit: 'per piece',
      seller: 'Farm Equipment Co.',
      location: 'Maharashtra, India',
      rating: 4.6,
      reviews: 12,
      image: '/api/placeholder/300/200',
      category: 'equipment',
      description: 'Heavy-duty tiller for soil preparation',
      available: 3
    },
    {
      id: 5,
      name: 'Pruning Shears Set',
      price: 1200,
      unit: 'per set',
      seller: 'Garden Tools Pro',
      location: 'Karnataka, India',
      rating: 4.5,
      reviews: 28,
      image: '/api/placeholder/300/200',
      category: 'tools',
      description: 'Professional pruning shears for garden maintenance',
      available: 40
    },
    {
      id: 6,
      name: 'Fresh Spinach',
      price: 80,
      unit: 'per kg',
      seller: 'Organic Valley',
      location: 'Uttarakhand, India',
      rating: 4.9,
      reviews: 35,
      image: '/api/placeholder/300/200',
      category: 'crops',
      description: 'Fresh organic spinach leaves',
      available: 30
    }
  ]

  // Filter products based on search and category
  const filteredProducts = products.filter(product => {
    const matchesSearch = product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         product.seller.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         product.location.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesCategory = selectedCategory === 'all' || product.category === selectedCategory
    return matchesSearch && matchesCategory
  })

  return (
    <ProtectedRoute>
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-gray-900 mb-3">
              Agricultural Marketplace
            </h1>
            <p className="text-lg text-gray-600">
              Buy and sell agricultural products, seeds, fertilizers, and equipment
            </p>
          </div>

          {/* Search and Filter Bar */}
          <div className="bg-white rounded-xl shadow-lg p-6 mb-8">
            <div className="flex flex-col md:flex-row gap-4">
              {/* Search Input */}
              <div className="flex-1 relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                <input
                  type="text"
                  placeholder="Search products, farmers, or locations..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent text-sm placeholder:text-sm text-black placeholder:text-black"
                />
              </div>

              {/* Category Filter */}
              <div className="flex gap-2 overflow-x-auto">
                {categories.map((category) => (
                  <button
                    key={category.id}
                    onClick={() => setSelectedCategory(category.id)}
                    className={`px-3 py-2 rounded-lg font-medium whitespace-nowrap transition-colors text-sm ${
                      selectedCategory === category.id
                        ? 'bg-green-600 text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    }`}
                  >
                    {category.name}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Products Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredProducts.map((product) => (
              <motion.div
                key={product.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5 }}
                className="bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-shadow"
              >
                {/* Product Image */}
                <div className="h-48 bg-gray-200 relative">
                  <div className="absolute top-3 right-3 flex gap-2">
                    <button className="p-2 bg-white rounded-full shadow-md hover:bg-gray-50 transition-colors">
                      <Heart className="w-4 h-4 text-gray-600" />
                    </button>
                    <button className="p-2 bg-white rounded-full shadow-md hover:bg-gray-50 transition-colors">
                      <Share2 className="w-4 h-4 text-gray-600" />
                    </button>
                  </div>
                  <div className="w-full h-full flex items-center justify-center text-gray-400">
                    <ShoppingCart className="w-12 h-12" />
                  </div>
                </div>

                {/* Product Info */}
                <div className="p-5">
                  <div className="flex justify-between items-start mb-2">
                    <h3 className="text-base font-semibold text-gray-900 line-clamp-2">
                      {product.name}
                    </h3>
                    <span className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                      {product.available} left
                    </span>
                  </div>

                  <p className="text-gray-600 text-xs mb-3 line-clamp-2">
                    {product.description}
                  </p>

                  <div className="flex items-center mb-3">
                    <div className="flex items-center">
                      {[...Array(5)].map((_, i) => (
                        <Star
                          key={i}
                          className={`w-3 h-3 ${
                            i < Math.floor(product.rating)
                              ? 'text-yellow-400 fill-current'
                              : 'text-gray-300'
                          }`}
                        />
                      ))}
                    </div>
                    <span className="text-xs text-gray-600 ml-2">
                      {product.rating} ({product.reviews} reviews)
                    </span>
                  </div>

                  <div className="flex items-center text-xs text-gray-600 mb-3">
                    <MapPin className="w-3 h-3 mr-1" />
                    <span>{product.location}</span>
                  </div>

                  <div className="flex items-center text-xs text-gray-600 mb-4">
                    <span className="font-medium">Seller:</span>
                    <span className="ml-1">{product.seller}</span>
                  </div>

                  <div className="flex justify-between items-center">
                    <div>
                      <span className="text-lg font-bold text-green-600">
                        ₹{product.price}
                      </span>
                      <span className="text-gray-500 text-xs ml-1">
                        {product.unit}
                      </span>
                    </div>
                    <button className="bg-green-600 text-white px-3 py-2 rounded-lg hover:bg-green-700 transition-colors flex items-center text-sm">
                      <Phone className="w-3 h-3 mr-1" />
                      Contact
                    </button>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          {/* No Results */}
          {filteredProducts.length === 0 && (
            <div className="text-center py-12">
              <Search className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-semibold text-gray-600 mb-2">
                No products found
              </h3>
              <p className="text-sm text-gray-500">
                Try adjusting your search or filter criteria
              </p>
            </div>
          )}
        </div>
      </div>
    </ProtectedRoute>
  )
}
