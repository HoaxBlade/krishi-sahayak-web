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
  Loader2
} from 'lucide-react'
import { MLService, MLAnalysisResult } from '@/lib/mlService'

type DisplayLanguage = 'hindi' | 'english';

export default function AnalyzePage() {
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [preview, setPreview] = useState<string | null>(null)
  const [analysis, setAnalysis] = useState<MLAnalysisResult | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [displayLanguage, setDisplayLanguage] = useState<DisplayLanguage>('hindi'); // Default to Hindi
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      setSelectedFile(file)
      setError(null)
      setAnalysis(null)
      setDisplayLanguage('hindi'); // Reset language on new file select
      
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
        <div className="text-center mb-10"> {/* Adjusted margin */}
          <h1 className="text-3xl font-bold text-gray-900 mb-3"> {/* Adjusted text size and margin */}
            AI Crop Health Analysis
          </h1>
          <p className="text-lg text-gray-600"> {/* Adjusted text size */}
            Upload a photo of your crop to get instant health analysis and recommendations
          </p>
        </div>

        <div className="grid lg:grid-cols-2 gap-7"> {/* Adjusted gap */}
          {/* Upload Section */}
          <motion.div
            className="bg-white rounded-xl shadow-subtle p-7" /* Refined card style */
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5 }}
          >
            <h2 className="text-xl font-semibold text-gray-900 mb-5"> {/* Adjusted text size and margin */}
              Upload Crop Image
            </h2>
            
            {!preview ? (
              <div
                className="border border-dashed border-gray-200 rounded-xl p-10 text-center hover:border-green-500 transition-colors cursor-pointer" /* Refined border, rounded corners, and padding */
                onClick={() => fileInputRef.current?.click()}
              >
                <Camera className="w-14 h-14 text-gray-400 mx-auto mb-3" /> {/* Adjusted icon size and margin */}
                <p className="text-base text-gray-500 mb-2"> {/* Adjusted text size and color */}
                  Click to upload or drag and drop
                </p>
                <p className="text-xs text-gray-400"> {/* Adjusted text size and color */}
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
                    className="w-full h-56 object-cover rounded-lg" /* Adjusted height */
                  />
                  <button
                    onClick={() => {
                      setSelectedFile(null)
                      setPreview(null)
                      setAnalysis(null)
                      setDisplayLanguage('hindi'); // Reset language on clear
                    }}
                    className="absolute top-2 right-2 bg-red-500 text-white rounded-full p-1.5 hover:bg-red-600 transition-colors" /* Adjusted padding */
                  >
                    ×
                  </button>
                </div>
                
                <button
                  onClick={handleAnalyze}
                  disabled={loading}
                  className="w-full bg-green-600 text-white py-2.5 px-5 rounded-lg font-medium hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center shadow-md hover:shadow-lg" /* Refined button style */
                >
                  {loading ? (
                    <>
                      <Loader2 className="w-4.5 h-4.5 mr-2 animate-spin" /> {/* Adjusted icon size */}
                      Analyzing...
                    </>
                  ) : (
                    <>
                      <Upload className="w-4.5 h-4.5 mr-2" /> {/* Adjusted icon size */}
                      Analyze Crop Health
                    </>
                  )}
                </button>
              </div>
            )}

            {error && (
              <motion.div
                className="mt-3 p-3 bg-red-100 border border-red-300 text-red-600 rounded-lg" /* Adjusted padding, border, and text color */
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
              >
                {error}
              </motion.div>
            )}
          </motion.div>

          {/* Results Section */}
          <motion.div
            className="bg-white rounded-xl shadow-subtle p-7" /* Refined card style */
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5 }}
          >
            <h2 className="text-xl font-semibold text-gray-900 mb-5"> {/* Adjusted text size and margin */}
              Analysis Results
            </h2>
            
            {!analysis ? (
              <div className="text-center py-10"> {/* Adjusted padding */}
                <Leaf className="w-14 h-14 text-gray-300 mx-auto mb-3" /> {/* Adjusted icon size and margin */}
                <p className="text-gray-400 text-sm"> {/* Adjusted text color and size */}
                  Upload an image to see analysis results
                </p>
              </div>
            ) : (
              <div className="space-y-5"> {/* Adjusted spacing */}
                {/* Health Status */}
                <div className="text-center">
                  <div className={`inline-flex items-center space-x-2 px-3.5 py-1.5 rounded-full ${getHealthColor(analysis.health_status)}`}> {/* Adjusted padding */}
                    {getHealthIcon(analysis.health_status)}
                    <span className="font-medium capitalize text-sm"> {/* Adjusted font weight and size */}
                      {analysis.health_status}
                    </span>
                  </div>
                  <p className="text-xs text-gray-500 mt-1.5"> {/* Adjusted text size and margin */}
                    Confidence: {(parseFloat(analysis.confidence) * 100).toFixed(1)}%
                  </p>
                </div>

                {/* Prediction Details */}
                <div className="space-y-3"> {/* Adjusted spacing */}
                  <h3 className="text-base font-semibold text-gray-900"> {/* Adjusted text size */}
                    Detailed Analysis
                  </h3>
                  
                  <div className="space-y-2"> {/* Adjusted spacing */}
                    {Object.entries(analysis.all_predictions).map(([key, value]) => (
                      <div key={key} className="flex items-center justify-between">
                        <span className="text-gray-600 capitalize text-sm"> {/* Adjusted text color and size */}
                          {key.replace('_', ' ')}
                        </span>
                        <div className="flex items-center space-x-2">
                          <div className="w-28 bg-gray-200 rounded-full h-2"> {/* Adjusted width */}
                            <div
                              className="bg-green-500 h-2 rounded-full transition-all duration-500"
                              style={{ width: `${value * 100}%` }}
                            />
                          </div>
                          <span className="text-xs font-medium text-gray-500 w-10"> {/* Adjusted text size and width */}
                            {(value * 100).toFixed(1)}%
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Gemini Analysis */}
                {(analysis.gemini_analysis_hindi || analysis.gemini_analysis_english) && (
                  <div className="bg-blue-50/70 rounded-xl p-3.5">
                    <div className="flex justify-between items-center mb-2">
                      <h4 className="font-medium text-blue-800 text-base">
                        AI Insights ({displayLanguage === 'hindi' ? 'Hindi' : 'English'})
                      </h4>
                      <button
                        onClick={() => setDisplayLanguage(displayLanguage === 'hindi' ? 'english' : 'hindi')}
                        className="text-sm text-blue-600 hover:underline"
                      >
                        View in {displayLanguage === 'hindi' ? 'English' : 'Hindi'}
                      </button>
                    </div>
                    <p className="text-xs text-blue-700 whitespace-pre-wrap">
                      {displayLanguage === 'hindi' ? analysis.gemini_analysis_hindi : analysis.gemini_analysis_english}
                    </p>
                  </div>
                )}

                {/* Recommendations */}
                <div className="bg-green-50/70 rounded-xl p-3.5"> {/* Refined background, rounded corners, and padding */}
                  <h4 className="font-medium text-green-800 mb-1.5 text-base"> {/* Adjusted font weight, color, and margin */}
                    Recommendations
                  </h4>
                  <ul className="text-xs text-green-700 space-y-0.5"> {/* Adjusted text size, color, and spacing */}
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
                      setDisplayLanguage('hindi'); // Reset language on clear
                    }}
                    className="flex-1 bg-gray-100 text-gray-600 py-2 px-4 rounded-lg hover:bg-gray-200 transition-colors shadow-sm hover:shadow-md" /* Refined button style */
                  >
                    Analyze Another
                  </button>
                  <button className="flex-1 bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 transition-colors shadow-md hover:shadow-lg"> {/* Refined button style */}
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
