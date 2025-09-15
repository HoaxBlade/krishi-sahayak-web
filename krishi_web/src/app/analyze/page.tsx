/* eslint-disable @next/next/no-img-element */
'use client'

import { useState, useRef } from 'react'
import { motion } from 'framer-motion'
import { 
  Camera, 
  Upload, 
  Leaf, 
  AlertTriangle, 
  CheckCircle,
  Loader2,
  ArrowLeft
} from 'lucide-react'
import { MLService, MLAnalysisResult } from '@/lib/mlService'
import Link from 'next/link'

export default function AnalyzePage() {
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [preview, setPreview] = useState<string | null>(null)
  const [analysis, setAnalysis] = useState<MLAnalysisResult | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      setSelectedFile(file)
      setError(null)
      setAnalysis(null)
      
      // Create preview
      const reader = new FileReader()
      reader.onload = (e) => {
        setPreview(e.target?.result as string)
      }
      reader.readAsDataURL(file)
    }
  }

  const handleAnalyze = async () => {
    if (!selectedFile) return

    setLoading(true)
    setError(null)

    try {
      const mlService = MLService.getInstance()
      
      // Check if ML server is available first
      const isHealthy = await mlService.checkServerHealth()
      if (!isHealthy) {
        setError('ML Server is currently offline. Please try again later.')
        return
      }
      
      const result = await mlService.analyzeCropHealth(selectedFile)
      setAnalysis(result)
    } catch (err) {
      setError('Failed to analyze image. Please check your connection and try again.')
      console.error('Analysis error:', err)
    } finally {
      setLoading(false)
    }
  }

  const getHealthColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'healthy':
        return 'text-green-600 bg-green-100'
      case 'diseased':
        return 'text-red-600 bg-red-100'
      case 'stressed':
        return 'text-yellow-600 bg-yellow-100'
      default:
        return 'text-gray-600 bg-gray-100'
    }
  }

  const getHealthIcon = (status: string) => {
    switch (status.toLowerCase()) {
      case 'healthy':
        return <CheckCircle className="w-6 h-6 text-green-600" />
      case 'diseased':
        return <AlertTriangle className="w-6 h-6 text-red-600" />
      case 'stressed':
        return <AlertTriangle className="w-6 h-6 text-yellow-600" />
      default:
        return <Leaf className="w-6 h-6 text-gray-600" />
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            AI Crop Health Analysis
          </h1>
          <p className="text-xl text-gray-600">
            Upload a photo of your crop to get instant health analysis and recommendations
          </p>
        </div>

        <div className="grid lg:grid-cols-2 gap-8">
          {/* Upload Section */}
          <motion.div 
            className="bg-white rounded-xl shadow-lg p-8"
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5 }}
          >
            <h2 className="text-2xl font-semibold text-gray-900 mb-6">
              Upload Crop Image
            </h2>
            
            {!preview ? (
              <div 
                className="border-2 border-dashed border-gray-300 rounded-lg p-12 text-center hover:border-green-400 transition-colors cursor-pointer"
                onClick={() => fileInputRef.current?.click()}
              >
                <Camera className="w-16 h-16 text-gray-400 mx-auto mb-4" />
                <p className="text-lg text-gray-600 mb-2">
                  Click to upload or drag and drop
                </p>
                <p className="text-sm text-gray-500">
                  PNG, JPG, JPEG up to 10MB
                </p>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  onChange={handleFileSelect}
                  className="hidden"
                />
              </div>
            ) : (
              <div className="space-y-4">
                <div className="relative">
                  <img
                    src={preview}
                    alt="Crop preview"
                    className="w-full h-64 object-cover rounded-lg"
                  />
                  <button
                    onClick={() => {
                      setSelectedFile(null)
                      setPreview(null)
                      setAnalysis(null)
                    }}
                    className="absolute top-2 right-2 bg-red-500 text-white rounded-full p-2 hover:bg-red-600 transition-colors"
                  >
                    ×
                  </button>
                </div>
                
                <button
                  onClick={handleAnalyze}
                  disabled={loading}
                  className="w-full bg-green-600 text-white py-3 px-6 rounded-lg font-semibold hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center"
                >
                  {loading ? (
                    <>
                      <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                      Analyzing...
                    </>
                  ) : (
                    <>
                      <Upload className="w-5 h-5 mr-2" />
                      Analyze Crop Health
                    </>
                  )}
                </button>
              </div>
            )}

            {error && (
              <motion.div 
                className="mt-4 p-4 bg-red-100 border border-red-400 text-red-700 rounded-lg"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
              >
                {error}
              </motion.div>
            )}
          </motion.div>

          {/* Results Section */}
          <motion.div 
            className="bg-white rounded-xl shadow-lg p-8"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5 }}
          >
            <h2 className="text-2xl font-semibold text-gray-900 mb-6">
              Analysis Results
            </h2>
            
            {!analysis ? (
              <div className="text-center py-12">
                <Leaf className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                <p className="text-gray-500">
                  Upload an image to see analysis results
                </p>
              </div>
            ) : (
              <div className="space-y-6">
                {/* Health Status */}
                <div className="text-center">
                  <div className={`inline-flex items-center space-x-2 px-4 py-2 rounded-full ${getHealthColor(analysis.health_status)}`}>
                    {getHealthIcon(analysis.health_status)}
                    <span className="font-semibold capitalize">
                      {analysis.health_status}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 mt-2">
                    Confidence: {(parseFloat(analysis.confidence) * 100).toFixed(1)}%
                  </p>
                </div>

                {/* Prediction Details */}
                <div className="space-y-4">
                  <h3 className="text-lg font-semibold text-gray-900">
                    Detailed Analysis
                  </h3>
                  
                  <div className="space-y-3">
                    {Object.entries(analysis.all_predictions).map(([key, value]) => (
                      <div key={key} className="flex items-center justify-between">
                        <span className="text-gray-700 capitalize">
                          {key.replace('_', ' ')}
                        </span>
                        <div className="flex items-center space-x-2">
                          <div className="w-32 bg-gray-200 rounded-full h-2">
                            <div 
                              className="bg-green-500 h-2 rounded-full transition-all duration-500"
                              style={{ width: `${value * 100}%` }}
                            />
                          </div>
                          <span className="text-sm font-medium text-gray-600 w-12">
                            {(value * 100).toFixed(1)}%
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Recommendations */}
                <div className="bg-blue-50 rounded-lg p-4">
                  <h4 className="font-semibold text-blue-900 mb-2">
                    Recommendations
                  </h4>
                  <ul className="text-sm text-blue-800 space-y-1">
                    {analysis.health_status.toLowerCase() === 'healthy' ? (
                      <>
                        <li>• Continue current care routine</li>
                        <li>• Monitor for any changes</li>
                        <li>• Maintain proper irrigation</li>
                      </>
                    ) : analysis.health_status.toLowerCase() === 'diseased' ? (
                      <>
                        <li>• Check for signs of disease</li>
                        <li>• Consider fungicide treatment</li>
                        <li>• Improve air circulation</li>
                        <li>• Remove affected parts if necessary</li>
                      </>
                    ) : (
                      <>
                        <li>• Check soil moisture levels</li>
                        <li>• Ensure proper nutrition</li>
                        <li>• Monitor for pests</li>
                        <li>• Consider environmental factors</li>
                      </>
                    )}
                  </ul>
                </div>

                {/* Action Buttons */}
                <div className="flex space-x-3">
                  <button
                    onClick={() => {
                      setSelectedFile(null)
                      setPreview(null)
                      setAnalysis(null)
                    }}
                    className="flex-1 bg-gray-100 text-gray-700 py-2 px-4 rounded-lg hover:bg-gray-200 transition-colors"
                  >
                    Analyze Another
                  </button>
                  <button className="flex-1 bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 transition-colors">
                    Save Results
                  </button>
                </div>
              </div>
            )}
          </motion.div>
        </div>
      </div>
    </div>
  )
}
