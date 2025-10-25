'use client'

import React, { useState, useEffect, useRef } from 'react'
import { MapPin, ChevronDown } from 'lucide-react'
import { INDIAN_REGIONS, getDistrictsByState, getRegionByState } from '@/lib/regionData'

interface RegionSelectorProps {
  selectedState?: string
  selectedDistrict?: string
  onStateChange: (state: string) => void
  onDistrictChange: (district: string) => void
  onRegionChange?: (region: string) => void
  required?: boolean
  className?: string
  label?: string
}

export default function RegionSelector({
  selectedState = '',
  selectedDistrict = '',
  onStateChange,
  onDistrictChange,
  onRegionChange,
  required = false,
  className = '',
  label = 'Location'
}: RegionSelectorProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [districts, setDistricts] = useState<string[]>([])
  const [region, setRegion] = useState('')

  // Use refs to store callback functions to avoid dependency issues
  const onDistrictChangeRef = useRef(onDistrictChange)
  const onRegionChangeRef = useRef(onRegionChange)
  
  // Update refs when props change
  onDistrictChangeRef.current = onDistrictChange
  onRegionChangeRef.current = onRegionChange

  // Update districts when state changes
  useEffect(() => {
    if (selectedState) {
      const newDistricts = getDistrictsByState(selectedState)
      setDistricts(newDistricts)
      
      const newRegion = getRegionByState(selectedState)
      setRegion(newRegion)
      onRegionChangeRef.current?.(newRegion)
      
      // Reset district if it's not valid for the new state
      if (selectedDistrict && !newDistricts.includes(selectedDistrict)) {
        onDistrictChangeRef.current?.('')
      }
    } else {
      setDistricts([])
      setRegion('')
      onRegionChangeRef.current?.('')
    }
  }, [selectedState, selectedDistrict])

  const handleStateChange = (state: string) => {
    onStateChange(state)
    setIsOpen(false)
  }

  const handleDistrictChange = (district: string) => {
    onDistrictChange(district)
  }

  const getRegionColor = (region: string) => {
    const colors = {
      'North': 'bg-blue-100 text-blue-800',
      'South': 'bg-green-100 text-green-800',
      'East': 'bg-orange-100 text-orange-800',
      'West': 'bg-purple-100 text-purple-800',
      'Central': 'bg-yellow-100 text-yellow-800',
      'Northeast': 'bg-pink-100 text-pink-800'
    }
    return colors[region as keyof typeof colors] || 'bg-gray-100 text-gray-800'
  }

  return (
    <div className={`space-y-4 ${className}`}>
      {/* State Selection */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          {label} {required && <span className="text-red-500">*</span>}
        </label>
        
        <div className="relative">
          <button
            type="button"
            onClick={() => setIsOpen(!isOpen)}
            className="w-full px-4 py-3 border border-gray-300 rounded-lg bg-white text-left focus:ring-2 focus:ring-green-500 focus:border-green-500 transition-colors"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <MapPin className="w-4 h-4 text-gray-500" />
                <span className={selectedState ? 'text-gray-900' : 'text-gray-500'}>
                  {selectedState || 'Select State'}
                </span>
              </div>
              <ChevronDown className={`w-4 h-4 text-gray-500 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
            </div>
          </button>

          {isOpen && (
            <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-y-auto">
              {INDIAN_REGIONS.map((regionData) => (
                <button
                  key={regionData.state}
                  type="button"
                  onClick={() => handleStateChange(regionData.state)}
                  className="w-full px-4 py-3 text-left hover:bg-gray-50 focus:bg-gray-50 focus:outline-none border-b border-gray-100 last:border-b-0"
                >
                  <div className="flex items-center justify-between">
                    <span className="text-gray-900">{regionData.state}</span>
                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${getRegionColor(regionData.region)}`}>
                      {regionData.region}
                    </span>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* District Selection */}
      {selectedState && districts.length > 0 && (
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            District {required && <span className="text-red-500">*</span>}
          </label>
          
          <select
            value={selectedDistrict}
            onChange={(e) => handleDistrictChange(e.target.value)}
            className="w-full px-4 py-3 border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-green-500 focus:border-green-500 transition-colors"
            required={required}
          >
            <option value="">Select District</option>
            {districts.map((district) => (
              <option key={district} value={district}>
                {district}
              </option>
            ))}
          </select>
        </div>
      )}

      {/* Region Display */}
      {region && (
        <div className="flex items-center space-x-2 text-sm">
          <span className="text-gray-600">Region:</span>
          <span className={`px-2 py-1 rounded-full text-xs font-medium ${getRegionColor(region)}`}>
            {region} India
          </span>
        </div>
      )}

      {/* Selected Location Summary */}
      {selectedState && selectedDistrict && (
        <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
          <div className="flex items-center space-x-2 text-sm text-green-800">
            <MapPin className="w-4 h-4" />
            <span className="font-medium">Selected Location:</span>
            <span>{selectedDistrict}, {selectedState}</span>
          </div>
        </div>
      )}
    </div>
  )
}
