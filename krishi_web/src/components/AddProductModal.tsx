'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { X } from 'lucide-react'
import { MarketplaceService } from '@/lib/marketplaceService'

interface AddProductModalProps {
  isOpen: boolean
  onClose: () => void
}

export default function AddProductModal({ isOpen, onClose }: AddProductModalProps) {
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
        category_id: formData.category, // This will be the category name for now
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

      // Call the actual API
      await marketplaceService.createProduct(productData)
      
      setSuccess(true)
      
      // Reset form and close modal after a short delay
      setTimeout(() => {
        resetForm()
        onClose()
      }, 1500)
      
    } catch (error: unknown) {
      console.error('Error creating product:', error)
      const errorMessage = error instanceof Error && 'response' in error 
        ? (error as { response?: { data?: { error?: string } } }).response?.data?.error 
        : 'Failed to create product. Please try again.'
      setError(errorMessage || 'Failed to create product. Please try again.')
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

  const nextStep = () => setCurrentStep(prev => prev + 1)
  const prevStep = () => setCurrentStep(prev => prev - 1)

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 backdrop-blur-lg flex items-center justify-center z-50 p-4" role="dialog" aria-modal="true">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
      >
        <div className="p-6">
          {/* Header */}
          <div className="flex justify-between items-center mb-6">
            <div>
              <h2 className="text-2xl font-bold text-gray-900">Add New Product</h2>
              <p className="text-gray-600">Step {currentStep} of 3</p>
            </div>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 transition-colors"
              aria-label="Close modal"
            >
              <X className="w-6 h-6" />
            </button>
          </div>

          {/* Progress Bar */}
          <div className="mb-6">
            <div className="flex items-center">
              {[1, 2, 3].map((step) => (
                <div key={step} className="flex items-center">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                    step <= currentStep 
                      ? 'bg-green-600 text-white' 
                      : 'bg-gray-200 text-gray-600'
                  }`}>
                    {step}
                  </div>
                  {step < 3 && (
                    <div className={`w-16 h-1 mx-2 ${
                      step < currentStep ? 'bg-green-600' : 'bg-gray-200'
                    }`} />
                  )}
                </div>
              ))}
            </div>
          </div>

          <div>
            {/* Step 1: Basic Information */}
            {currentStep === 1 && (
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Basic Information</h3>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Product Name *
                  </label>
                  <input
                    type="text"
                    required
                    aria-required="true"
                    value={formData.name}
                    onChange={(e) => handleInputChange('name', e.target.value)}
                    className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                    placeholder="e.g., Organic Tomatoes"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Description *
                  </label>
                  <textarea
                    required
                    aria-required="true"
                    value={formData.description}
                    onChange={(e) => handleInputChange('description', e.target.value)}
                    rows={3}
                    className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                    placeholder="Describe your product..."
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Category *
                    </label>
                    <select
                      required
                      aria-required="true"
                      value={formData.category}
                      onChange={(e) => handleInputChange('category', e.target.value)}
                      className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                    >
                      <option value="">Select Category</option>
                      {categories.map(cat => (
                        <option key={cat} value={cat}>{cat}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Product Type *
                    </label>
                    <select
                      required
                      aria-required="true"
                      value={formData.productType}
                      onChange={(e) => handleInputChange('productType', e.target.value)}
                      className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                    >
                      <option value="buyable">Buyable</option>
                      <option value="rentable">Rentable</option>
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Unit *
                    </label>
                    <select
                      required
                      aria-required="true"
                      value={formData.unit}
                      onChange={(e) => handleInputChange('unit', e.target.value)}
                      className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                    >
                      <option value="">Select Unit</option>
                      {units.map(unit => (
                        <option key={unit} value={unit}>{unit}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Stock Quantity *
                    </label>
                    <input
                      type="number"
                      required
                      aria-required="true"
                      min="0"
                      value={formData.stockQuantity}
                      onChange={(e) => handleInputChange('stockQuantity', e.target.value)}
                      className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                      placeholder="100"
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Step 2: Pricing */}
            {currentStep === 2 && (
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Pricing Information</h3>
                
                {formData.productType === 'buyable' ? (
                  <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Price (₹) *
                        </label>
                        <input
                          type="number"
                          required
                          aria-required="true"
                          min="0"
                          step="0.01"
                          value={formData.price}
                          onChange={(e) => handleInputChange('price', e.target.value)}
                          className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                          placeholder="120.00"
                        />
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Discount Price (₹)
                        </label>
                        <input
                          type="number"
                          min="0"
                          step="0.01"
                          value={formData.discountPrice}
                          onChange={(e) => handleInputChange('discountPrice', e.target.value)}
                          className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                          placeholder="100.00"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Minimum Order Quantity
                      </label>
                      <input
                        type="number"
                        min="1"
                        value={formData.minOrderQuantity}
                        onChange={(e) => handleInputChange('minOrderQuantity', e.target.value)}
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                        placeholder="1"
                      />
                    </div>
                  </div>
                ) : (
                  <div className="space-y-4">
                    <div className="grid grid-cols-3 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Daily Rate (₹)
                        </label>
                        <input
                          type="number"
                          min="0"
                          step="0.01"
                          value={formData.rentalPricePerDay}
                          onChange={(e) => handleInputChange('rentalPricePerDay', e.target.value)}
                          className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                          placeholder="2500"
                        />
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Weekly Rate (₹)
                        </label>
                        <input
                          type="number"
                          min="0"
                          step="0.01"
                          value={formData.rentalPricePerWeek}
                          onChange={(e) => handleInputChange('rentalPricePerWeek', e.target.value)}
                          className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                          placeholder="15000"
                        />
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Monthly Rate (₹)
                        </label>
                        <input
                          type="number"
                          min="0"
                          step="0.01"
                          value={formData.rentalPricePerMonth}
                          onChange={(e) => handleInputChange('rentalPricePerMonth', e.target.value)}
                          className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                          placeholder="50000"
                        />
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Min Rental Days
                        </label>
                        <input
                          type="number"
                          min="1"
                          value={formData.minRentalDays}
                          onChange={(e) => handleInputChange('minRentalDays', e.target.value)}
                          className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                          placeholder="1"
                        />
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Max Rental Days
                        </label>
                        <input
                          type="number"
                          min="1"
                          value={formData.maxRentalDays}
                          onChange={(e) => handleInputChange('maxRentalDays', e.target.value)}
                          className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                          placeholder="30"
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
                        <span className="text-sm text-gray-700">Requires Security Deposit</span>
                      </label>
                    </div>

                    {formData.requiresDeposit && (
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Deposit Amount (₹)
                        </label>
                        <input
                          type="number"
                          min="0"
                          step="0.01"
                          value={formData.depositAmount}
                          onChange={(e) => handleInputChange('depositAmount', e.target.value)}
                          className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                          placeholder="50000"
                        />
                      </div>
                    )}
                  </div>
                )}
              </div>
            )}

            {/* Step 3: Specifications */}
            {currentStep === 3 && (
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Product Specifications</h3>
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Variety/Brand
                    </label>
                    <input
                      type="text"
                      value={formData.specifications.variety}
                      onChange={(e) => handleInputChange('specifications.variety', e.target.value)}
                      className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                      placeholder="e.g., Cherry, John Deere"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Color
                    </label>
                    <input
                      type="text"
                      value={formData.specifications.color}
                      onChange={(e) => handleInputChange('specifications.color', e.target.value)}
                      className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                      placeholder="e.g., Red, Green"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Size
                    </label>
                    <input
                      type="text"
                      value={formData.specifications.size}
                      onChange={(e) => handleInputChange('specifications.size', e.target.value)}
                      className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                      placeholder="e.g., Medium, Large"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Material
                    </label>
                    <input
                      type="text"
                      value={formData.specifications.material}
                      onChange={(e) => handleInputChange('specifications.material', e.target.value)}
                      className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500 focus:border-transparent text-black placeholder:text-gray-500"
                      placeholder="e.g., Steel, Organic"
                    />
                  </div>
                </div>

                <div className="flex items-center space-x-4">
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={formData.specifications.organic}
                      onChange={(e) => handleInputChange('specifications.organic', e.target.checked)}
                      className="mr-2"
                    />
                    <span className="text-sm text-gray-700">Organic Product</span>
                  </label>
                </div>
              </div>
            )}

            {/* Error and Success Messages */}
            {error && (
              <div className="mt-6 p-4 bg-red-50 border border-red-200 rounded-lg">
                <div className="flex items-center">
                  <div className="text-red-600 text-sm font-medium">{error}</div>
                </div>
              </div>
            )}

            {success && (
              <div className="mt-6 p-4 bg-green-50 border border-green-200 rounded-lg">
                <div className="flex items-center">
                  <div className="text-green-600 text-sm font-medium">
                    ✅ Product created successfully! 
                  </div>
                </div>
              </div>
            )}

            {/* Navigation Buttons */}
            <div className="flex justify-between mt-8">
              <button
                type="button"
                onClick={prevStep}
                disabled={currentStep === 1}
                className={`px-4 py-2 rounded-lg transition-colors ${
                  currentStep === 1
                    ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                Previous
              </button>

              <div className="flex space-x-3">
                {currentStep < 3 ? (
                  <button
                    type="button"
                    onClick={nextStep}
                    className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                  >
                    Next
                  </button>
                ) : (
                  <button
                    type="button"
                    onClick={handleSubmit}
                    disabled={loading}
                    className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                  >
                    {loading ? (
                      <>
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                        Creating...
                      </>
                    ) : (
                      'Create Product'
                    )}
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  )
}
