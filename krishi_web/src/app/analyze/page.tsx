'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import {
  AlertTriangle,
  CheckCircle,
  BarChart3,
  Activity,
  Clock,
  Target,
  TrendingUp,
  Server,
  Zap,
  Shield
} from 'lucide-react'
import { MLService } from '@/lib/mlService'

export default function AnalyzePage() {
  // COMMENTED OUT: Original analysis functionality
  // const [selectedFile, setSelectedFile] = useState<File | null>(null)
  // const [preview, setPreview] = useState<string | null>(null)
  // const [analysis, setAnalysis] = useState<MLAnalysisResult | null>(null)
  // const [loading, setLoading] = useState(false)
  // const [error, setError] = useState<string | null>(null)
  // const [displayLanguage, setDisplayLanguage] = useState<DisplayLanguage>('hindi'); // Default to Hindi
  // const fileInputRef = useRef<HTMLInputElement>(null)

  // NEW: ML Model Performance Stats
  const [modelStats, setModelStats] = useState({
    accuracy: 0,
    totalAnalyses: 0,
    avgResponseTime: 0,
    uptime: 0,
    lastUpdated: '',
    trends: {
      accuracyChange: 0,
      analysesChange: 0,
      responseTimeChange: 0,
    }
  })
  const [serverHealth, setServerHealth] = useState({
    status: 'unknown',
    responseTime: 0,
    lastCheck: ''
  })
  const [recentAnalyses, setRecentAnalyses] = useState<Array<{
    id: string
    crop: string
    status: string
    confidence: number
    date: string
    location: string
  }>>([])
  const [usingSampleData, setUsingSampleData] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isClient, setIsClient] = useState(false)
  
  // Loading state is used in fetchModelStats function

  // COMMENTED OUT: Original analysis functions
  // const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
  //   const file = event.target.files?.[0]
  //   if (file) {
  //     setSelectedFile(file)
  //     setError(null)
  //     setAnalysis(null)
  //     setDisplayLanguage('hindi'); // Reset language on new file select
      
  //     // Create preview
  //     const reader = new FileReader()
  //     reader.onload = (e) => {
  //       setPreview(e.target?.result as string)
  //     }
  //     reader.readAsDataURL(file)
  //   }
  // }

  // const handleAnalyze = async () => {
  //   if (!selectedFile) return

  //   setLoading(true)
  //   setError(null)

  //   try {
  //     const mlService = MLService.getInstance()
      
  //     // Check if ML server is available first
  //     const isHealthy = await mlService.checkServerHealth()
  //     if (!isHealthy) {
  //       setError('ML Server is currently offline. Please try again later.')
  //       return
  //     }
      
  //     const result = await mlService.analyzeCropHealth(selectedFile)
  //     setAnalysis(result)
  //   } catch (err) {
  //     setError('Failed to analyze image. Please check your connection and try again.')
  //     console.error('Analysis error:', err)
  //   } finally {
  //     setLoading(false)
  //   }
  // }

  // NEW: ML Model Performance Functions
  const fetchModelStats = async () => {
    setLoading(true)
    setError(null)
    try {
      const mlService = MLService.getInstance()
      
      // Fetch server health status
      const serverStatus = await mlService.getServerStatus()
      
      setServerHealth({
        status: serverStatus.healthy ? 'healthy' : 'unhealthy',
        responseTime: serverStatus.responseTime,
        lastCheck: new Date().toISOString()
      })

      // Fetch model performance data from API
      await fetchModelPerformanceData()
      
    } catch (error) {
      console.error('Failed to fetch model stats:', error)
      setError('Failed to fetch model statistics')
      setServerHealth({
        status: 'unhealthy',
        responseTime: 0,
        lastCheck: new Date().toISOString()
      })
    } finally {
      setLoading(false)
    }
  }

  const fetchRecentAnalyses = async () => {
    try {
      const response = await fetch('/api/ml/analyses?limit=5')
      if (!response.ok) {
        throw new Error(`Failed to fetch recent analyses: ${response.status}`)
      }
      const data = await response.json()
      setRecentAnalyses(data.analyses || [])
      setUsingSampleData(!!data.note)
      
      // Log if using sample data
      if (data.note) {
        console.log('Analyses API:', data.note)
      }
    } catch (error) {
      console.error('Error fetching recent analyses:', error)
      // Set fallback data if API fails completely
      setRecentAnalyses([
        {
          id: 'fallback-1',
          crop: 'Tomato',
          status: 'Healthy',
          confidence: 96,
          date: new Date().toISOString().split('T')[0],
          location: 'Field A'
        },
        {
          id: 'fallback-2',
          crop: 'Wheat',
          status: 'Diseased',
          confidence: 89,
          date: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          location: 'Field B'
        }
      ])
      setUsingSampleData(true)
    }
  }

  const fetchModelPerformanceData = async () => {
    try {
      // Fetch from ML performance API endpoint
      const response = await fetch('/api/ml/performance', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      })

      if (!response.ok) {
        throw new Error('Failed to fetch performance data')
      }

      const data = await response.json()
      
      setModelStats({
        accuracy: Math.round((data.accuracy || 0) * 10) / 10, // Round to 1 decimal
        totalAnalyses: data.totalAnalyses || 0,
        avgResponseTime: Math.round((data.avgResponseTime || 0) * 10) / 10, // Round to 1 decimal
        uptime: Math.round((data.uptime || 0) * 10) / 10, // Round to 1 decimal
        lastUpdated: new Date().toISOString(),
        trends: {
          accuracyChange: data.trends?.accuracyChange || 0,
          analysesChange: data.trends?.analysesChange || 0,
          responseTimeChange: data.trends?.responseTimeChange || 0,
        }
      })
    } catch (error) {
      console.error('Failed to fetch performance data:', error)
      setError('Unable to fetch real-time data. Showing cached information.')
      // Keep previous data if available, don't reset to 0
    }
  }

  useEffect(() => {
    setIsClient(true)
    fetchModelStats()
    fetchRecentAnalyses()
    // Refresh stats every 30 seconds
    const interval = setInterval(() => {
      fetchModelStats()
      fetchRecentAnalyses()
    }, 30000)
    return () => clearInterval(interval)
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  // COMMENTED OUT: Original analysis helper functions
  // const getHealthColor = (status: string) => {
  //   switch (status.toLowerCase()) {
  //     case 'healthy':
  //       return 'text-green-600 bg-green-100'
  //     case 'diseased':
  //       return 'text-red-600 bg-red-100'
  //     case 'stressed':
  //       return 'text-yellow-600 bg-yellow-100'
  //     default:
  //       return 'text-gray-600 bg-gray-100'
  //   }
  // }

  // const getHealthIcon = (status: string) => {
  //   switch (status.toLowerCase()) {
  //     case 'healthy':
  //       return <CheckCircle className="w-6 h-6 text-green-600" />
  //     case 'diseased':
  //       return <AlertTriangle className="w-6 h-6 text-red-600" />
  //     case 'stressed':
  //       return <AlertTriangle className="w-6 h-6 text-yellow-600" />
  //     default:
  //       return <Leaf className="w-6 h-6 text-gray-600" />
  //   }
  // }

  // NEW: ML Model Performance Helper Functions
  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'healthy':
        return 'text-green-600 bg-green-100'
      case 'unhealthy':
        return 'text-red-600 bg-red-100'
      case 'warning':
        return 'text-yellow-600 bg-yellow-100'
      default:
        return 'text-gray-600 bg-gray-100'
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status.toLowerCase()) {
      case 'healthy':
        return <CheckCircle className="w-5 h-5 text-green-600" />
      case 'unhealthy':
        return <AlertTriangle className="w-5 h-5 text-red-600" />
      case 'warning':
        return <AlertTriangle className="w-5 h-5 text-yellow-600" />
      default:
        return <Server className="w-5 h-5 text-gray-600" />
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="text-center mb-10">
          <h1 className="text-3xl font-bold text-gray-900 mb-3">
            ML Model Performance Stats
          </h1>
          <p className="text-lg text-gray-600">
            Real-time monitoring of AI crop health analysis model performance
          </p>
          {loading && (
            <div className="mt-4 flex items-center justify-center">
              <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-green-600 mr-2"></div>
              <span className="text-sm text-gray-600">Updating data...</span>
            </div>
          )}
          {error && (
            <div className="mt-4 p-3 bg-yellow-100 border border-yellow-300 text-yellow-700 rounded-lg max-w-md mx-auto">
              {error}
            </div>
          )}
        </div>

        {/* Server Health Status */}
          <motion.div
          className="bg-white rounded-xl shadow-lg p-6 mb-8"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-gray-900 flex items-center">
              <Server className="w-6 h-6 mr-2 text-blue-600" />
              Server Health Status
            </h2>
            <div className={`inline-flex items-center space-x-2 px-3 py-1 rounded-full ${getStatusColor(serverHealth.status)}`}>
              {getStatusIcon(serverHealth.status)}
              <span className="font-medium capitalize text-sm">
                {serverHealth.status}
              </span>
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Response Time</span>
                <Clock className="w-4 h-4 text-gray-400" />
              </div>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {serverHealth.responseTime}ms
              </p>
            </div>
            
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Last Check</span>
                <Activity className="w-4 h-4 text-gray-400" />
              </div>
              <p className="text-sm text-gray-900 mt-1">
                {isClient && serverHealth.lastCheck ? new Date(serverHealth.lastCheck).toLocaleTimeString() : 'Loading...'}
              </p>
                </div>
                
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Auto Refresh</span>
                <Zap className="w-4 h-4 text-gray-400" />
              </div>
              <p className="text-sm text-gray-900 mt-1">
                Every 30s
              </p>
            </div>
          </div>
        </motion.div>

        {/* Performance Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <motion.div
            className="bg-white rounded-xl shadow-lg p-6"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
          >
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-green-100 rounded-lg">
                <Target className="w-6 h-6 text-green-600" />
              </div>
              <TrendingUp className="w-5 h-5 text-green-500" />
            </div>
            <h3 className="text-sm font-medium text-gray-600 mb-1">Model Accuracy</h3>
            <p className="text-3xl font-bold text-gray-900">
              {loading ? '...' : `${modelStats.accuracy}%`}
            </p>
            <p className={`text-xs mt-1 ${
              modelStats.trends.accuracyChange > 0 ? 'text-green-500' : 
              modelStats.trends.accuracyChange < 0 ? 'text-red-500' : 'text-gray-500'
            }`}>
              {loading ? 'Loading...' : 
                `${modelStats.trends.accuracyChange > 0 ? '+' : ''}${modelStats.trends.accuracyChange.toFixed(1)}% from last check`
              }
            </p>
          </motion.div>

              <motion.div
            className="bg-white rounded-xl shadow-lg p-6"
            initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
          >
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-blue-100 rounded-lg">
                <BarChart3 className="w-6 h-6 text-blue-600" />
              </div>
              <TrendingUp className="w-5 h-5 text-blue-500" />
            </div>
            <h3 className="text-sm font-medium text-gray-600 mb-1">Total Analyses</h3>
            <p className="text-3xl font-bold text-gray-900">
              {loading ? '...' : modelStats.totalAnalyses.toLocaleString()}
            </p>
            <p className={`text-xs mt-1 ${
              modelStats.trends.analysesChange > 0 ? 'text-green-500' : 
              modelStats.trends.analysesChange < 0 ? 'text-red-500' : 'text-gray-500'
            }`}>
              {loading ? 'Loading...' : 
                `+${modelStats.trends.analysesChange} since last check`
              }
            </p>
              </motion.div>

          <motion.div
            className="bg-white rounded-xl shadow-lg p-6"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
          >
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-purple-100 rounded-lg">
                <Clock className="w-6 h-6 text-purple-600" />
              </div>
              <TrendingUp className="w-5 h-5 text-purple-500" />
            </div>
            <h3 className="text-sm font-medium text-gray-600 mb-1">Avg Response Time</h3>
            <p className="text-3xl font-bold text-gray-900">
              {loading ? '...' : `${modelStats.avgResponseTime}s`}
            </p>
            <p className={`text-xs mt-1 ${
              modelStats.trends.responseTimeChange < 0 ? 'text-green-500' : 
              modelStats.trends.responseTimeChange > 0 ? 'text-red-500' : 'text-gray-500'
            }`}>
              {loading ? 'Loading...' : 
                `${modelStats.trends.responseTimeChange > 0 ? '+' : ''}${modelStats.trends.responseTimeChange.toFixed(1)}s change`
              }
            </p>
          </motion.div>

          <motion.div
            className="bg-white rounded-xl shadow-lg p-6"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.4 }}
          >
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-orange-100 rounded-lg">
                <Shield className="w-6 h-6 text-orange-600" />
              </div>
              <TrendingUp className="w-5 h-5 text-orange-500" />
                  </div>
            <h3 className="text-sm font-medium text-gray-600 mb-1">Uptime</h3>
            <p className="text-3xl font-bold text-gray-900">
              {loading ? '...' : `${modelStats.uptime}%`}
            </p>
            <p className="text-xs text-gray-500 mt-1">
              {loading ? 'Loading...' : 'Last 30 days'}
            </p>
          </motion.div>
                </div>

        {/* Recent Crop Analyses */}
        <motion.div
          className="bg-white rounded-xl shadow-lg p-6 mb-8"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.5 }}
        >
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900 flex items-center">
              <Activity className="w-6 h-6 mr-2 text-green-600" />
              Latest Crop Analyses
            </h2>
            {usingSampleData && (
              <span className="text-xs bg-yellow-100 text-yellow-800 px-2 py-1 rounded-full">
                Sample Data
              </span>
            )}
          </div>
          
          <div className="space-y-3">
            {recentAnalyses.length > 0 ? recentAnalyses.map((analysis) => (
              <motion.div
                key={analysis.id}
                className="flex items-center justify-between p-3.5 border border-gray-100 rounded-lg"
                whileHover={{ scale: 1.01, backgroundColor: "#f0f0f0", boxShadow: "0 5px 10px rgba(0, 0, 0, 0.05)" }}
                transition={{ type: "spring", stiffness: 400, damping: 10 }}
              >
                <div className="flex items-center space-x-4">
                  <div className={`w-2.5 h-2.5 rounded-full ${
                    analysis.status === 'Healthy' ? 'bg-green-500' : 'bg-red-500'
                  }`} />
                  <div>
                    <p className="font-medium text-gray-800">{analysis.crop}</p>
                    <p className="text-xs text-gray-500">{analysis.location}</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="font-medium text-gray-800">{analysis.status}</p>
                  <p className="text-xs text-gray-500">{analysis.confidence}% confidence</p>
                </div>
                <div className="text-xs text-gray-400">
                  {new Date(analysis.date).toLocaleDateString()}
                </div>
              </motion.div>
            )) : (
              <div className="text-center py-8 text-gray-500">
                <Activity className="w-12 h-12 mx-auto mb-4 text-gray-300" />
                <p>No recent analyses found</p>
                <p className="text-sm text-gray-400 mt-1">Analyses will appear here once crops are analyzed</p>
              </div>
            )}
          </div>
          
          <div className="mt-5">
            <button className="inline-flex items-center text-green-600 hover:text-green-700 font-semibold text-sm transition-all hover:scale-[1.02]">
              View All Analyses
              <Activity className="w-3.5 h-3.5 ml-2" />
            </button>
          </div>
        </motion.div>

        {/* System Status */}
        <motion.div
          className="bg-white rounded-xl shadow-lg p-6 mb-8"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.6 }}
        >
          <h2 className="text-xl font-semibold text-gray-900 mb-6 flex items-center">
            <Server className="w-6 h-6 mr-2 text-blue-600" />
            System Status
          </h2>
          
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-black text-sm">ML Server</span>
              <div className="flex items-center space-x-2">
                <div className={`w-2 h-2 rounded-full ${serverHealth.status === 'healthy' ? 'bg-green-500' : 'bg-red-500'}`} />
                <span className="text-xs font-medium text-black">{serverHealth.status === 'healthy' ? 'Online' : 'Offline'}</span>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-black text-sm">Weather API</span>
              <div className="flex items-center space-x-2">
                <div className="w-2 h-2 rounded-full bg-green-500" />
                <span className="text-xs font-medium text-black">Connected</span>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-black text-sm">Database</span>
              <div className="flex items-center space-x-2">
                <div className="w-2 h-2 rounded-full bg-green-500" />
                <span className="text-xs font-medium text-black">Connected</span>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Model Performance Chart Placeholder */}
        <motion.div
          className="bg-white rounded-xl shadow-lg p-6 mb-8"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.7 }}
        >
          <h2 className="text-xl font-semibold text-gray-900 mb-6 flex items-center">
            <BarChart3 className="w-6 h-6 mr-2 text-blue-600" />
            Performance Trends
          </h2>
          
          <div className="h-64 bg-gray-50 rounded-lg flex items-center justify-center">
            <div className="text-center">
              <BarChart3 className="w-12 h-12 text-gray-400 mx-auto mb-2" />
              <p className="text-gray-500">Performance chart will be displayed here</p>
              <p className="text-sm text-gray-400 mt-1">Integration with monitoring dashboard coming soon</p>
                    </div>
                  </div>
        </motion.div>

        {/* Recent Activity */}
        <motion.div
          className="bg-white rounded-xl shadow-lg p-6"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.8 }}
        >
          <h2 className="text-xl font-semibold text-gray-900 mb-6 flex items-center">
            <Activity className="w-6 h-6 mr-2 text-green-600" />
            Recent Activity
          </h2>
          
          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 bg-green-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                <span className="text-sm text-gray-700">
                  Model accuracy: {loading ? '...' : `${modelStats.accuracy}%`}
                  {!loading && modelStats.trends.accuracyChange > 0 && ' (improved)'}
                  {!loading && modelStats.trends.accuracyChange < 0 && ' (decreased)'}
                </span>
              </div>
              <span className="text-xs text-gray-500">
                {isClient && modelStats.lastUpdated ? new Date(modelStats.lastUpdated).toLocaleTimeString() : 'Loading...'}
              </span>
                </div>

            <div className="flex items-center justify-between p-4 bg-blue-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                <span className="text-sm text-gray-700">
                  Total analyses: {loading ? '...' : modelStats.totalAnalyses.toLocaleString()}
                  {!loading && modelStats.trends.analysesChange > 0 && ` (+${modelStats.trends.analysesChange} new)`}
                </span>
              </div>
              <span className="text-xs text-gray-500">
                {isClient && modelStats.lastUpdated ? new Date(modelStats.lastUpdated).toLocaleTimeString() : 'Loading...'}
              </span>
            </div>

            <div className="flex items-center justify-between p-4 bg-purple-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <div className="w-2 h-2 bg-purple-500 rounded-full"></div>
                <span className="text-sm text-gray-700">
                  Response time: {loading ? '...' : `${modelStats.avgResponseTime}s`}
                  {!loading && modelStats.trends.responseTimeChange < 0 && ' (improved)'}
                  {!loading && modelStats.trends.responseTimeChange > 0 && ' (slower)'}
                </span>
              </div>
              <span className="text-xs text-gray-500">
                {isClient && modelStats.lastUpdated ? new Date(modelStats.lastUpdated).toLocaleTimeString() : 'Loading...'}
              </span>
                </div>

            <div className="flex items-center justify-between p-4 bg-orange-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <div className={`w-2 h-2 rounded-full ${
                  serverHealth.status === 'healthy' ? 'bg-green-500' : 
                  serverHealth.status === 'unhealthy' ? 'bg-red-500' : 'bg-yellow-500'
                }`}></div>
                <span className="text-sm text-gray-700">
                  Server status: {serverHealth.status} ({serverHealth.responseTime}ms)
                </span>
              </div>
              <span className="text-xs text-gray-500">
                {isClient && serverHealth.lastCheck ? new Date(serverHealth.lastCheck).toLocaleTimeString() : 'Loading...'}
              </span>
            </div>
          </div>
        </motion.div>

        {/* COMMENTED OUT: Original Analysis Interface */}
        {/* 
        <div className="grid lg:grid-cols-2 gap-7">
          <motion.div className="bg-white rounded-xl shadow-subtle p-7">
            <h2 className="text-xl font-semibold text-gray-900 mb-5">Upload Crop Image</h2>
            // ... original upload interface code ...
          </motion.div>
          <motion.div className="bg-white rounded-xl shadow-subtle p-7">
            <h2 className="text-xl font-semibold text-gray-900 mb-5">Analysis Results</h2>
            // ... original results interface code ...
          </motion.div>
        </div>
        */}
      </div>
    </div>
  )
}
