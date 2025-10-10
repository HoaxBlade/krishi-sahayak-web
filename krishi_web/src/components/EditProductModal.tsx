'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { X } from 'lucide-react'
import { MarketplaceService, Product } from '@/lib/marketplaceService'

interface EditProductModalProps {
  isOpen: boolean
  onClose: () => void
  product: Product | null
  onProductUpdated: () => void
}

export default function EditProductModal({ isOpen, onClose, product, onProductUpdated }: EditProductModalProps) {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    price: '',
    discountPrice: '',
    stockQuantity: '',
    minOrderQuantity: '1',
    unit: '',
    productType: 'buyable',
    category: '',
    // Rental fields
    rentalPricePerDay: '',
    rentalPricePerWeek: '',
    rentalPricePerMonth: '',
    minRentalDays: '1',
    maxRentalDays: '',
    requiresDeposit: false,
    depositAmount: '',
    // Images
    images: [] as string[],
    // Specifications
    specifications: {
      variety: '',
      color: '',
      size: '',
      organic: false,
      material: '',
      weight: '',
      dimensions: ''
    }
  })

  const [currentStep, setCurrentStep] = useState(1)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)

  const marketplaceService = MarketplaceService.getInstance()

  const categories = [
    'Fresh Crops',
    'Seeds', 
    'Fertilizers',
    'Tractors',
    'Drones',
    'Harvesters',
    'Irrigation Equipment',
    'Tillage Equipment',
    'Tools',
    'Pesticides'
  ]

  const units = [
    'per kg',
    'per bag',
    'per unit',
    'per liter',
    'per piece',
    'per set',
    'per acre',
    'per hour'
  ]

  // Initialize form data when product changes
  useEffect(() => {
    if (product) {
      setFormData({
        name: product.name || '',
        description: product.description || '',
        price: product.price?.toString() || '',
        discountPrice: product.discount_price?.toString() || '',
        stockQuantity: product.stock_quantity?.toString() || '',
        minOrderQuantity: product.min_order_quantity?.toString() || '1',
        unit: product.unit || '',
        productType: product.product_type || 'buyable',
        category: product.categories?.name || '',
        // Rental fields
        rentalPricePerDay: product.rental_price_per_day?.toString() || '',
        rentalPricePerWeek: product.rental_price_per_week?.toString() || '',
        rentalPricePerMonth: product.rental_price_per_month?.toString() || '',
        minRentalDays: product.min_rental_days?.toString() || '1',
        maxRentalDays: product.max_rental_days?.toString() || '',
        requiresDeposit: product.requires_deposit || false,
        depositAmount: product.deposit_amount?.toString() || '',
        // Images
        images: product.images || [],
        // Specifications
        specifications: {
          variety: (product.specifications as Record<string, unknown>)?.variety as string || '',
          color: (product.specifications as Record<string, unknown>)?.color as string || '',
          size: (product.specifications as Record<string, unknown>)?.size as string || '',
          organic: (product.specifications as Record<string, unknown>)?.organic as boolean || false,
          material: (product.specifications as Record<string, unknown>)?.material as string || '',
          weight: (product.specifications as Record<string, unknown>)?.weight as string || '',
          dimensions: (product.specifications as Record<string, unknown>)?.dimensions as string || ''
        }
      })
    }
  }, [product])

  const handleInputChange = (field: string, value: string | number | boolean) => {
    if (field.startsWith('specifications.')) {
      const specField = field.split('.')[1]
      setFormData(prev => ({
        ...prev,
        specifications: {
          ...prev.specifications,
          [specField]: value
        }
      }))
    } else {
      setFormData(prev => ({
        ...prev,
        [field]: value
      }))
    }
  }

  const handleSubmit = async () => {
    if (!product) return

    setLoading(true)
    setError(null)
    
    try {
      // Validate required fields
      if (!formData.name || !formData.description || !formData.price || !formData.category) {
        setError('Please fill in all required fields')
        return
      }

      // Prepare product data for API
      const productData = {
        name: formData.name,
        description: formData.description,
        price: parseFloat(formData.price),
        discount_price: formData.discountPrice ? parseFloat(formData.discountPrice) : undefined,
        category_id: formData.category,
        stock_quantity: parseInt(formData.stockQuantity),
        min_order_quantity: parseInt(formData.minOrderQuantity) || 1,
        unit: formData.unit,
        images: formData.images,
        specifications: formData.specifications,
        // Add rental fields if product type is rentable
        ...(formData.productType === 'rentable' && {
          product_type: 'rentable' as const,
          rental_price_per_day: formData.rentalPricePerDay ? parseFloat(formData.rentalPricePerDay) : undefined,
          rental_price_per_week: formData.rentalPricePerWeek ? parseFloat(formData.rentalPricePerWeek) : undefined,
          rental_price_per_month: formData.rentalPricePerMonth ? parseFloat(formData.rentalPricePerMonth) : undefined,
          min_rental_days: parseInt(formData.minRentalDays) || 1,
          max_rental_days: formData.maxRentalDays ? parseInt(formData.maxRentalDays) : undefined,
          requires_deposit: formData.requiresDeposit,
          deposit_amount: formData.depositAmount ? parseFloat(formData.depositAmount) : undefined,
        }),
        // Add buyable fields if product type is buyable
        ...(formData.productType === 'buyable' && {
          product_type: 'buyable' as const,
        })
      }

      // Call the update API
      await marketplaceService.updateProduct(product.id, productData)
      
      setSuccess(true)
      
      // Reset form and close modal after a short delay
      setTimeout(() => {
        onProductUpdated()
        onClose()
      }, 1500)

    } catch (error: unknown) {
      const errorMessage = error instanceof Error && 'response' in error
        ? (error as { response?: { data?: { error?: string } } }).response?.data?.error
        : 'Failed to update product. Please try again.'
      setError(errorMessage || 'Failed to update product. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const resetForm = () => {
    setFormData({
      name: '',
      description: '',
      price: '',
      discountPrice: '',
      stockQuantity: '',
      minOrderQuantity: '1',
      unit: '',
      productType: 'buyable',
      category: '',
      rentalPricePerDay: '',
      rentalPricePerWeek: '',
      rentalPricePerMonth: '',
      minRentalDays: '1',
      maxRentalDays: '',
      requiresDeposit: false,
      depositAmount: '',
      images: [],
      specifications: {
        variety: '',
        color: '',
        size: '',
        organic: false,
        material: '',
        weight: '',
        dimensions: ''
      }
    })
    setCurrentStep(1)
    setError(null)
    setSuccess(false)
  }

  const handleClose = () => {
    resetForm()
    onClose()
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        className="bg-white rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto"
      >
        {/* Header */}
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-xl font-semibold text-gray-900">Edit Product</h2>
          <button
            onClick={handleClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Progress Indicator */}
        <div className="px-6 py-4 border-b">
          <div className="flex items-center justify-center space-x-4">
            {[1, 2, 3].map((step) => (
              <div key={step} className="flex items-center">
                <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                  step <= currentStep ? 'bg-green-600 text-white' : 'bg-gray-200 text-gray-600'
                }`}>
                  {step}
                </div>
                {step < 3 && (
                  <div className={`w-8 h-0.5 mx-2 ${
                    step < currentStep ? 'bg-green-600' : 'bg-gray-200'
                  }`} />
                )}
              </div>
            ))}
          </div>
          <p className="text-center text-sm text-gray-600 mt-2">
            Step {currentStep} of 3: {currentStep === 1 ? 'Basic Information' : currentStep === 2 ? 'Pricing & Details' : 'Product Specifications'}
          </p>
        </div>

        {/* Form Content */}
        <div className="p-6">
          {error && (
            <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
              {error}
            </div>
          )}

          {success && (
            <div className="mb-4 p-3 bg-green-100 border border-green-400 text-green-700 rounded">
              Product updated successfully!
            </div>
          )}

          {/* Step 1: Basic Information */}
          {currentStep === 1 && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Product Name *
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => handleInputChange('name', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                  placeholder="Enter product name"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Description *
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) => handleInputChange('description', e.target.value)}
                  rows={3}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                  placeholder="Describe your product"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Category *
                </label>
                <select
                  value={formData.category}
                  onChange={(e) => handleInputChange('category', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                >
                  <option value="">Select a category</option>
                  {categories.map((category) => (
                    <option key={category} value={category}>
                      {category}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Product Type
                </label>
                <div className="flex space-x-4">
                  <label className="flex items-center">
                    <input
                      type="radio"
                      value="buyable"
                      checked={formData.productType === 'buyable'}
                      onChange={(e) => handleInputChange('productType', e.target.value)}
                      className="mr-2"
                    />
                    Buyable
                  </label>
                  <label className="flex items-center">
                    <input
                      type="radio"
                      value="rentable"
                      checked={formData.productType === 'rentable'}
                      onChange={(e) => handleInputChange('productType', e.target.value)}
                      className="mr-2"
                    />
                    Rentable
                  </label>
                </div>
              </div>
            </div>
          )}

          {/* Step 2: Pricing & Details */}
          {currentStep === 2 && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Price (₹) *
                  </label>
                  <input
                    type="number"
                    value={formData.price}
                    onChange={(e) => handleInputChange('price', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    placeholder="0.00"
                    min="0"
                    step="0.01"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Discount Price (₹)
                  </label>
                  <input
                    type="number"
                    value={formData.discountPrice}
                    onChange={(e) => handleInputChange('discountPrice', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    placeholder="0.00"
                    min="0"
                    step="0.01"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Stock Quantity *
                  </label>
                  <input
                    type="number"
                    value={formData.stockQuantity}
                    onChange={(e) => handleInputChange('stockQuantity', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    placeholder="0"
                    min="0"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Min Order Quantity
                  </label>
                  <input
                    type="number"
                    value={formData.minOrderQuantity}
                    onChange={(e) => handleInputChange('minOrderQuantity', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    placeholder="1"
                    min="1"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Unit
                </label>
                <select
                  value={formData.unit}
                  onChange={(e) => handleInputChange('unit', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                >
                  <option value="">Select unit</option>
                  {units.map((unit) => (
                    <option key={unit} value={unit}>
                      {unit}
                    </option>
                  ))}
                </select>
              </div>

              {/* Rental-specific fields */}
              {formData.productType === 'rentable' && (
                <div className="space-y-4 border-t pt-4">
                  <h3 className="text-lg font-medium text-gray-900">Rental Pricing</h3>
                  
                  <div className="grid grid-cols-3 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Daily Rate (₹)
                      </label>
                      <input
                        type="number"
                        value={formData.rentalPricePerDay}
                        onChange={(e) => handleInputChange('rentalPricePerDay', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                        placeholder="0.00"
                        min="0"
                        step="0.01"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Weekly Rate (₹)
                      </label>
                      <input
                        type="number"
                        value={formData.rentalPricePerWeek}
                        onChange={(e) => handleInputChange('rentalPricePerWeek', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                        placeholder="0.00"
                        min="0"
                        step="0.01"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Monthly Rate (₹)
                      </label>
                      <input
                        type="number"
                        value={formData.rentalPricePerMonth}
                        onChange={(e) => handleInputChange('rentalPricePerMonth', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                        placeholder="0.00"
                        min="0"
                        step="0.01"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Min Rental Days
                      </label>
                      <input
                        type="number"
                        value={formData.minRentalDays}
                        onChange={(e) => handleInputChange('minRentalDays', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                        placeholder="1"
                        min="1"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Max Rental Days
                      </label>
                      <input
                        type="number"
                        value={formData.maxRentalDays}
                        onChange={(e) => handleInputChange('maxRentalDays', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                        placeholder="30"
                        min="1"
                      />
                    </div>
                  </div>

                  <div className="flex items-center space-x-4">
                    <label className="flex items-center">
                      <input
                        type="checkbox"
                        checked={formData.requiresDeposit}
                        onChange={(e) => handleInputChange('requiresDeposit', e.target.checked)}
                        className="mr-2"
                      />
                      Requires Deposit
                    </label>

                    {formData.requiresDeposit && (
                      <div className="flex-1">
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Deposit Amount (₹)
                        </label>
                        <input
                          type="number"
                          value={formData.depositAmount}
                          onChange={(e) => handleInputChange('depositAmount', e.target.value)}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                          placeholder="0.00"
                          min="0"
                          step="0.01"
                        />
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Step 3: Product Specifications */}
          {currentStep === 3 && (
            <div className="space-y-4">
              <h3 className="text-lg font-medium text-gray-900">Product Specifications</h3>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Variety/Brand
                  </label>
                  <input
                    type="text"
                    value={formData.specifications.variety}
                    onChange={(e) => handleInputChange('specifications.variety', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    placeholder="Enter variety or brand"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Color
                  </label>
                  <input
                    type="text"
                    value={formData.specifications.color}
                    onChange={(e) => handleInputChange('specifications.color', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    placeholder="Enter color"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Size
                  </label>
                  <input
                    type="text"
                    value={formData.specifications.size}
                    onChange={(e) => handleInputChange('specifications.size', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    placeholder="Enter size"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Material
                  </label>
                  <input
                    type="text"
                    value={formData.specifications.material}
                    onChange={(e) => handleInputChange('specifications.material', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    placeholder="Enter material"
                  />
                </div>
              </div>

              <div className="flex items-center">
                <input
                  type="checkbox"
                  checked={formData.specifications.organic}
                  onChange={(e) => handleInputChange('specifications.organic', e.target.checked)}
                  className="mr-2"
                />
                <label className="text-sm font-medium text-gray-700">
                  Organic Product
                </label>
              </div>
            </div>
          )}

          {/* Navigation Buttons */}
          <div className="flex justify-between mt-6">
            <button
              onClick={() => setCurrentStep(Math.max(1, currentStep - 1))}
              disabled={currentStep === 1}
              className="px-4 py-2 text-gray-600 bg-gray-100 rounded-lg hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Previous
            </button>

            {currentStep < 3 ? (
              <button
                onClick={() => setCurrentStep(Math.min(3, currentStep + 1))}
                className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
              >
                Next
              </button>
            ) : (
              <button
                onClick={handleSubmit}
                disabled={loading}
                className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? 'Updating...' : 'Update Product'}
              </button>
            )}
          </div>
        </div>
      </motion.div>
    </div>
  )
}
