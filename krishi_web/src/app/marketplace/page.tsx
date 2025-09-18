/* eslint-disable @typescript-eslint/no-unused-vars */
'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { 
  ShoppingCart, 
  Search, 
  Star, 
  MapPin, 
  Phone,
  Heart,
  Share2,
  Calendar,
  CreditCard,
  Filter,
  X,
  ChevronDown
} from 'lucide-react'
import ProtectedRoute from '@/components/ProtectedRoute'
import { useAuth } from '@/contexts/AuthContext'
import { MarketplaceService, Product, Category } from '@/lib/marketplaceService'
import AddProductModal from '@/components/AddProductModal'

export default function MarketplacePage() {
  const { user } = useAuth()
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('all')
  const [products, setProducts] = useState<Product[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null)
  const [showRentalModal, setShowRentalModal] = useState(false)
  const [showAddProductModal, setShowAddProductModal] = useState(false)
  
  // Advanced filter states
  const [showFilters, setShowFilters] = useState(false)
  const [priceRange, setPriceRange] = useState({ min: '', max: '' })
  const [location, setLocation] = useState('')
  const [sortBy, setSortBy] = useState('created_at')
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc')
  const [activeFilters, setActiveFilters] = useState<string[]>([])
  const [pagination, setPagination] = useState({ page: 1, totalPages: 1, total: 0 })

  const marketplaceService = MarketplaceService.getInstance()

  // Load products and categories
  useEffect(() => {
    const loadData = async () => {
      try {
        setLoading(true)
        const [productsResponse, categoriesResponse] = await Promise.all([
          marketplaceService.getProducts({
            category: selectedCategory === 'all' ? undefined : selectedCategory,
            search: searchQuery || undefined,
            minPrice: priceRange.min ? parseFloat(priceRange.min) : undefined,
            maxPrice: priceRange.max ? parseFloat(priceRange.max) : undefined,
            location: location || undefined,
            sortBy,
            sortOrder,
            page: pagination.page,
            limit: 12
          }),
          marketplaceService.getCategories()
        ])
        
        setProducts(productsResponse.products || [])
        setCategories(categoriesResponse.categories || [])
        setPagination({
          page: productsResponse.pagination?.page || 1,
          totalPages: productsResponse.pagination?.totalPages || 1,
          total: productsResponse.pagination?.total || 0
        })
        setError(null)
      } catch (err) {
        console.error('Error loading marketplace data:', err)
        setError('Failed to load products. Please try again.')
      } finally {
        setLoading(false)
      }
    }

    loadData()
  }, [selectedCategory, searchQuery, priceRange, location, sortBy, sortOrder, pagination.page, marketplaceService])

  // Handle search with debouncing
  useEffect(() => {
    const timeoutId = setTimeout(() => {
      // Reset to first page when searching
      setPagination(prev => ({ ...prev, page: 1 }))
    }, 500)

    return () => clearTimeout(timeoutId)
  }, [searchQuery])

  // Update active filters
  useEffect(() => {
    const filters: string[] = []
    if (selectedCategory !== 'all') {
      const categoryName = categories.find(c => c.id === selectedCategory)?.name || selectedCategory
      filters.push(`Category: ${categoryName}`)
    }
    if (priceRange.min) filters.push(`Min Price: ₹${priceRange.min}`)
    if (priceRange.max) filters.push(`Max Price: ₹${priceRange.max}`)
    if (location) filters.push(`Location: ${location}`)
    if (searchQuery) filters.push(`Search: "${searchQuery}"`)
    setActiveFilters(filters)
  }, [selectedCategory, priceRange, location, searchQuery, categories])

  // Clear all filters
  const clearAllFilters = () => {
    setSearchQuery('')
    setSelectedCategory('all')
    setPriceRange({ min: '', max: '' })
    setLocation('')
    setSortBy('created_at')
    setSortOrder('desc')
    setPagination(prev => ({ ...prev, page: 1 }))
  }

  // Remove specific filter
  const removeFilter = (filterToRemove: string) => {
    if (filterToRemove.startsWith('Category:')) {
      setSelectedCategory('all')
    } else if (filterToRemove.startsWith('Min Price:')) {
      setPriceRange(prev => ({ ...prev, min: '' }))
    } else if (filterToRemove.startsWith('Max Price:')) {
      setPriceRange(prev => ({ ...prev, max: '' }))
    } else if (filterToRemove.startsWith('Location:')) {
      setLocation('')
    } else if (filterToRemove.startsWith('Search:')) {
      setSearchQuery('')
    }
  }

  // Handle rental booking
  const handleRentalBooking = (product: Product) => {
    setSelectedProduct(product)
    setShowRentalModal(true)
  }

  // Handle buy now
  const handleBuyNow = (product: Product) => {
    // TODO: Implement buy now functionality
    console.log('Buy now:', product)
  }

  return (
    <ProtectedRoute>
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {/* Header */}
          <div className="mb-8">
            <div className="flex justify-between items-center mb-4">
              <div>
                <h1 className="text-3xl font-bold text-gray-900 mb-3">
                  Agricultural Marketplace
                </h1>
                <p className="text-lg text-gray-600">
                  Buy and sell agricultural products, seeds, fertilizers, and equipment
                </p>
              </div>
              <button 
                onClick={() => setShowAddProductModal(true)}
                className="bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 transition-colors flex items-center"
              >
                <ShoppingCart className="w-5 h-5 mr-2" />
                Add Your Product
              </button>
            </div>
          </div>

          {/* Search and Filter Bar */}
          <div className="bg-white rounded-xl shadow-lg p-6 mb-8">
            {/* Main Search Row */}
            <div className="flex flex-col lg:flex-row gap-4 mb-4">
              {/* Search Input */}
              <div className="flex-1 relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                <input
                  type="text"
                  placeholder="Search products, farmers, or locations..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-10 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent text-sm placeholder:text-sm text-black placeholder:text-gray-400"
                />
                {searchQuery && (
                  <button
                    onClick={() => setSearchQuery('')}
                    className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  >
                    <X className="w-4 h-4" />
                  </button>
                )}
              </div>

              {/* Filter and Sort Controls */}
              <div className="flex gap-3">
                <button
                  onClick={() => setShowFilters(!showFilters)}
                  className={`px-4 py-3 rounded-lg font-medium transition-colors text-sm flex items-center gap-2 ${
                    showFilters || activeFilters.length > 0
                      ? 'bg-green-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  <Filter className="w-4 h-4" />
                  Filters
                  {activeFilters.length > 0 && (
                    <span className="bg-white text-green-600 text-xs px-2 py-1 rounded-full">
                      {activeFilters.length}
                    </span>
                  )}
                </button>

                <div className="relative">
                  <select
                    value={`${sortBy}-${sortOrder}`}
                    onChange={(e) => {
                      const [newSortBy, newSortOrder] = e.target.value.split('-')
                      setSortBy(newSortBy)
                      setSortOrder(newSortOrder as 'asc' | 'desc')
                    }}
                    className="appearance-none bg-gray-100 text-gray-700 px-4 py-3 pr-8 rounded-lg font-medium text-sm hover:bg-gray-200 transition-colors cursor-pointer"
                  >
                    <option value="created_at-desc">Newest First</option>
                    <option value="created_at-asc">Oldest First</option>
                    <option value="price-asc">Price: Low to High</option>
                    <option value="price-desc">Price: High to Low</option>
                    <option value="rating_avg-desc">Highest Rated</option>
                    <option value="rating_avg-asc">Lowest Rated</option>
                    <option value="name-asc">Name: A to Z</option>
                    <option value="name-desc">Name: Z to A</option>
                  </select>
                  <ChevronDown className="absolute right-2 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-500 pointer-events-none" />
                </div>
              </div>
            </div>

            {/* Active Filters */}
            {activeFilters.length > 0 && (
              <div className="flex flex-wrap gap-2 mb-4">
                <span className="text-sm text-gray-600 font-medium">Active filters:</span>
                {activeFilters.map((filter, index) => (
                  <span
                    key={index}
                    className="bg-green-100 text-green-800 px-3 py-1 rounded-full text-sm flex items-center gap-2"
                  >
                    {filter}
                    <button
                      onClick={() => removeFilter(filter)}
                      className="hover:text-green-600"
                    >
                      <X className="w-3 h-3" />
                    </button>
                  </span>
                ))}
                <button
                  onClick={clearAllFilters}
                  className="text-sm text-gray-500 hover:text-gray-700 underline"
                >
                  Clear all
                </button>
              </div>
            )}

            {/* Advanced Filters Panel */}
            {showFilters && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="border-t pt-4 mt-4 mb-4"
              >
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {/* Price Range */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Price Range (₹)
                    </label>
                    <div className="flex gap-2">
                      <input
                        type="number"
                        placeholder="Min"
                        value={priceRange.min}
                        onChange={(e) => setPriceRange(prev => ({ ...prev, min: e.target.value }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-500 focus:border-transparent text-black"
                      />
                      <input
                        type="number"
                        placeholder="Max"
                        value={priceRange.max}
                        onChange={(e) => setPriceRange(prev => ({ ...prev, max: e.target.value }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-500 focus:border-transparent text-black"
                      />
                    </div>
                  </div>

                  {/* Location */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Location
                    </label>
                    <input
                      type="text"
                      placeholder="City or State"
                      value={location}
                      onChange={(e) => setLocation(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-500 focus:border-transparent text-black"
                    />
                  </div>

                  {/* Category Filter */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Category
                    </label>
                    <select
                      value={selectedCategory}
                      onChange={(e) => setSelectedCategory(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-green-500 focus:border-transparent text-black"
                    >
                      <option value="all">All Categories</option>
                      {categories.map((category) => (
                        <option key={category.id} value={category.id}>
                          {category.name}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </motion.div>
            )}

            {/* Category Pills */}
            <div className="flex gap-2 overflow-x-auto">
              <button
                onClick={() => setSelectedCategory('all')}
                className={`px-3 py-2 rounded-lg font-medium whitespace-nowrap transition-colors text-sm ${
                  selectedCategory === 'all'
                    ? 'bg-green-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                All Products
              </button>
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

          {/* Loading State */}
          {loading && (
            <div className="text-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600 mx-auto mb-4"></div>
              <p className="text-gray-600">Loading products...</p>
            </div>
          )}

          {/* Error State */}
          {error && (
            <div className="text-center py-12">
              <div className="text-red-600 mb-4">{error}</div>
              <button 
                onClick={() => window.location.reload()}
                className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors"
              >
                Try Again
              </button>
            </div>
          )}

          {/* Products Grid */}
          {!loading && !error && (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {products.map((product) => (
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
                    {/* Product Type Badge */}
                    <div className="absolute top-3 left-3">
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                        product.product_type === 'rentable' 
                          ? 'bg-blue-100 text-blue-800' 
                          : 'bg-green-100 text-green-800'
                      }`}>
                        {product.product_type === 'rentable' ? 'Rent' : 'Buy'}
                      </span>
                    </div>
                  </div>

                  {/* Product Info */}
                  <div className="p-5">
                    <div className="flex justify-between items-start mb-2">
                      <h3 className="text-base font-semibold text-gray-900 line-clamp-2">
                        {product.name}
                      </h3>
                      <span className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                        {product.stock_quantity} left
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
                              i < Math.floor(product.rating_avg)
                                ? 'text-yellow-400 fill-current'
                                : 'text-gray-300'
                            }`}
                          />
                        ))}
                      </div>
                      <span className="text-xs text-gray-600 ml-2">
                        {product.rating_avg.toFixed(1)} ({product.review_count} reviews)
                      </span>
                    </div>

                    <div className="flex items-center text-xs text-gray-600 mb-3">
                      <MapPin className="w-3 h-3 mr-1" />
                      <span>{product.provider_profiles.city}, {product.provider_profiles.state}</span>
                    </div>

                    <div className="flex items-center text-xs text-gray-600 mb-4">
                      <span className="font-medium">Seller:</span>
                      <span className="ml-1">{product.provider_profiles.business_name}</span>
                    </div>

                    {/* Pricing */}
                    <div className="mb-4">
                      {product.product_type === 'rentable' ? (
                        <div className="space-y-1">
                          <div className="text-sm font-semibold text-gray-900">Rental Rates:</div>
                          {product.rental_price_per_day && (
                            <div className="text-xs text-gray-600">
                              Daily: ₹{product.rental_price_per_day}
                            </div>
                          )}
                          {product.rental_price_per_week && (
                            <div className="text-xs text-gray-600">
                              Weekly: ₹{product.rental_price_per_week}
                            </div>
                          )}
                          {product.rental_price_per_month && (
                            <div className="text-xs text-gray-600">
                              Monthly: ₹{product.rental_price_per_month}
                            </div>
                          )}
                        </div>
                      ) : (
                        <div>
                          <span className="text-lg font-bold text-green-600">
                            ₹{product.price}
                          </span>
                          <span className="text-gray-500 text-xs ml-1">
                            {product.unit}
                          </span>
                        </div>
                      )}
                    </div>

                    {/* Action Buttons */}
                    <div className="flex gap-2">
                      {product.product_type === 'rentable' ? (
                        <button 
                          onClick={() => handleRentalBooking(product)}
                          className="flex-1 bg-blue-600 text-white px-3 py-2 rounded-lg hover:bg-blue-700 transition-colors flex items-center justify-center text-sm"
                        >
                          <Calendar className="w-3 h-3 mr-1" />
                          Rent Now
                        </button>
                      ) : (
                        <button 
                          onClick={() => handleBuyNow(product)}
                          className="flex-1 bg-green-600 text-white px-3 py-2 rounded-lg hover:bg-green-700 transition-colors flex items-center justify-center text-sm"
                        >
                          <CreditCard className="w-3 h-3 mr-1" />
                          Buy Now
                        </button>
                      )}
                      <button className="bg-gray-100 text-gray-700 px-3 py-2 rounded-lg hover:bg-gray-200 transition-colors flex items-center text-sm">
                        <Phone className="w-3 h-3" />
                      </button>
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          )}

          {/* Pagination */}
          {!loading && !error && products.length > 0 && pagination.totalPages > 1 && (
            <div className="flex justify-center items-center gap-4 mt-8">
              <button
                onClick={() => setPagination(prev => ({ ...prev, page: Math.max(1, prev.page - 1) }))}
                disabled={pagination.page === 1}
                className="px-4 py-2 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Previous
              </button>
              
              <div className="flex items-center gap-2">
                {Array.from({ length: Math.min(5, pagination.totalPages) }, (_, i) => {
                  const pageNum = i + 1
                  return (
                    <button
                      key={pageNum}
                      onClick={() => setPagination(prev => ({ ...prev, page: pageNum }))}
                      className={`px-3 py-2 rounded-lg text-sm font-medium ${
                        pagination.page === pageNum
                          ? 'bg-green-600 text-white'
                          : 'text-gray-700 hover:bg-gray-100'
                      }`}
                    >
                      {pageNum}
                    </button>
                  )
                })}
                {pagination.totalPages > 5 && (
                  <>
                    <span className="text-gray-500">...</span>
                    <button
                      onClick={() => setPagination(prev => ({ ...prev, page: pagination.totalPages }))}
                      className={`px-3 py-2 rounded-lg text-sm font-medium ${
                        pagination.page === pagination.totalPages
                          ? 'bg-green-600 text-white'
                          : 'text-gray-700 hover:bg-gray-100'
                      }`}
                    >
                      {pagination.totalPages}
                    </button>
                  </>
                )}
              </div>
              
              <button
                onClick={() => setPagination(prev => ({ ...prev, page: Math.min(pagination.totalPages, prev.page + 1) }))}
                disabled={pagination.page === pagination.totalPages}
                className="px-4 py-2 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Next
              </button>
            </div>
          )}

          {/* Results Summary */}
          {!loading && !error && products.length > 0 && (
            <div className="text-center text-sm text-gray-600 mt-4">
              Showing {((pagination.page - 1) * 12) + 1} to {Math.min(pagination.page * 12, pagination.total)} of {pagination.total} products
            </div>
          )}

          {/* No Results */}
          {!loading && !error && products.length === 0 && (
            <div className="text-center py-12">
              <Search className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-semibold text-gray-600 mb-2">
                No products found
              </h3>
              <p className="text-sm text-gray-500 mb-4">
                Try adjusting your search or filter criteria
              </p>
              <button
                onClick={clearAllFilters}
                className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors"
              >
                Clear all filters
              </button>
            </div>
          )}
        </div>

        {/* Rental Booking Modal */}
        {showRentalModal && selectedProduct && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
              <div className="p-6">
                <div className="flex justify-between items-center mb-4">
                  <h3 className="text-lg font-semibold text-gray-900">
                    Rent {selectedProduct.name}
                  </h3>
                  <button
                    onClick={() => setShowRentalModal(false)}
                    className="text-gray-400 hover:text-gray-600"
                  >
                    ×
                  </button>
                </div>

                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Rental Period
                    </label>
                    <select className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm text-black">
                      <option value="daily">Daily</option>
                      <option value="weekly">Weekly</option>
                      <option value="monthly">Monthly</option>
                    </select>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Start Date
                      </label>
                      <input
                        type="date"
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm text-black"
                        min={new Date().toISOString().split('T')[0]}
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        End Date
                      </label>
                      <input
                        type="date"
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm text-black"
                        min={new Date().toISOString().split('T')[0]}
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Delivery Address
                    </label>
                    <textarea
                      className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm text-black"
                      rows={3}
                      placeholder="Enter your delivery address"
                    />
                  </div>

                  <div className="bg-gray-50 p-4 rounded-lg">
                    <div className="flex justify-between text-sm">
                      <span>Rental Rate:</span>
                      <span className="font-semibold">₹500/day</span>
                    </div>
                    <div className="flex justify-between text-sm mt-1">
                      <span>Duration:</span>
                      <span>3 days</span>
                    </div>
                    <div className="flex justify-between text-sm mt-1">
                      <span>Deposit:</span>
                      <span>₹2,000</span>
                    </div>
                    <div className="border-t pt-2 mt-2">
                      <div className="flex justify-between font-semibold">
                        <span>Total Amount:</span>
                        <span>₹3,500</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex gap-3">
                    <button
                      onClick={() => setShowRentalModal(false)}
                      className="flex-1 bg-gray-100 text-gray-700 py-2 px-4 rounded-lg hover:bg-gray-200 transition-colors"
                    >
                      Cancel
                    </button>
                    <button className="flex-1 bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors">
                      Confirm Rental
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Add Product Modal */}
        <AddProductModal 
          isOpen={showAddProductModal}
          onClose={() => setShowAddProductModal(false)}
        />
      </div>
    </ProtectedRoute>
  )
}
