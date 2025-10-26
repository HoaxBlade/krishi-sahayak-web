/* eslint-disable react-hooks/exhaustive-deps */
'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import {
  AlertTriangle,
  CheckCircle,
  BarChart3,
  Activity,
  Clock,
  TrendingUp,
  Server,
  Zap,
  Shield,
  User
} from 'lucide-react'
import { MLService } from '@/lib/mlService'

export default function AnalyzePage() {
  // NEW: ML Model Performance Stats
  const [modelStats, setModelStats] = useState({
    activeUsers: 0,
    avgResponseTime: 0,
    downtime: 0,
    lastUpdated: '',
    trends: {
      activeUsersChange: 0,
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
  const [showAllAnalyses, setShowAllAnalyses] = useState(false)
  const [allAnalyses, setAllAnalyses] = useState<Array<{
    id: string
    crop: string
    status: string
    confidence: number
    date: string
    location: string
  }>>([])
  
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

  const fetchAllAnalyses = async () => {
    try {
      const response = await fetch('/api/ml/analyses?limit=50')
      if (!response.ok) {
        throw new Error(`Failed to fetch all analyses: ${response.status}`)
      }
      const data = await response.json()
      setAllAnalyses(data.analyses || [])
    } catch (error) {
      console.error('Error fetching all analyses:', error)
      setAllAnalyses([])
    }
  }

  const handleViewAllAnalyses = async () => {
    if (!showAllAnalyses) {
      await fetchAllAnalyses()
    }
    setShowAllAnalyses(!showAllAnalyses)
  }

  const fetchModelPerformanceData = async () => {
    try {
      const mlService = MLService.getInstance();
      const data = await mlService.getModelPerformance();
      
      setModelStats({
        activeUsers: data.activeUsers || 0,
        avgResponseTime: data.avgResponseTime || 0,
        downtime: data.downtime || 0,
        lastUpdated: data.lastUpdated || new Date().toISOString(),
        trends: {
          activeUsersChange: data.trends?.activeUsersChange || 0,
          responseTimeChange: data.trends?.responseTimeChange || 0,
        }
      });
    } catch (error) {
      console.error('Failed to fetch performance data:', error);
      setError('Unable to fetch real-time data. Showing cached information.');
      // Keep previous data if available, don't reset to 0
    }
  };

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
  }, [])

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
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 md:py-12">
        <div className="text-center mb-8 sm:mb-10">
          <h1 className="text-2xl sm:text-3xl font-bold text-gray-900 mb-2 sm:mb-3">
            Advanced Agricultural Analytics
          </h1>
          <p className="text-base sm:text-lg text-gray-600 px-2">
            Real-time monitoring of AI models and drone data for comprehensive crop health analysis
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
          className={`bg-white rounded-xl shadow-lg p-4 sm:p-6 mb-6 sm:mb-8 ${serverHealth.status === 'healthy' ? 'glow-green' : 'glow-red'}`}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg sm:text-xl font-semibold text-gray-900 flex items-center">
              <Server className="w-5 h-5 sm:w-6 sm:h-6 mr-2 text-blue-600" />
              <span className="hidden sm:inline">Server Health Status</span>
              <span className="sm:hidden">Health Status</span>
            </h2>
            <div className={`inline-flex items-center space-x-1 sm:space-x-2 px-2 sm:px-3 py-1 rounded-full ${getStatusColor(serverHealth.status)}`}>
              {getStatusIcon(serverHealth.status)}
              <span className="font-medium capitalize text-xs sm:text-sm">
                {serverHealth.status}
              </span>
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3 sm:gap-4">
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
        {/* Drone Data Integration */}
        <motion.div
          className="bg-white rounded-xl shadow-lg p-4 sm:p-6 mb-6 sm:mb-8"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.05 }}
        >
          <h2 className="text-lg sm:text-xl font-semibold text-gray-900 flex items-center">
            <Zap className="w-5 h-5 sm:w-6 sm:h-6 mr-2 text-yellow-600" />
            <span className="hidden sm:inline">Drone Data Integration</span>
            <span className="sm:hidden">Drone Integration</span>
          </h2>
          <p className="text-sm sm:text-base text-gray-600 mb-3 sm:mb-4">
            Seamlessly integrate and analyze data from your agricultural drones for enhanced insights.
          </p>
          <div className="h-24 sm:h-32 bg-gray-50 rounded-lg flex items-center justify-center px-2">
            <p className="text-xs sm:text-sm text-gray-500 text-center">Drone data visualization coming soon</p>
          </div>
        </motion.div>

        {/* Performance Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6 mb-6 sm:mb-8">
              <motion.div
            className="bg-white rounded-xl shadow-lg p-4 sm:p-6"
            initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
          >
            <div className="flex items-center justify-between mb-3 sm:mb-4">
              <div className="p-2 sm:p-3 bg-blue-100 rounded-lg">
                <User className="w-5 h-5 sm:w-6 sm:h-6 text-blue-600" />
              </div>
              <TrendingUp className="w-4 h-4 sm:w-5 sm:h-5 text-blue-500" />
            </div>
            <h3 className="text-xs sm:text-sm font-medium text-gray-600 mb-1">Number of Active Users</h3>
            <p className="text-2xl sm:text-3xl font-bold text-gray-900">
              {loading ? '...' : modelStats.activeUsers.toLocaleString()}
            </p>
            <p className={`text-xs mt-1 ${
              modelStats.trends.activeUsersChange > 0 ? 'text-green-500' :
              modelStats.trends.activeUsersChange < 0 ? 'text-red-500' : 'text-gray-500'
            }`}>
              {loading ? 'Loading...' :
                `+${modelStats.trends.activeUsersChange} since last check`
              }
            </p>
              </motion.div>

          <motion.div
            className="bg-white rounded-xl shadow-lg p-4 sm:p-6"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
          >
            <div className="flex items-center justify-between mb-3 sm:mb-4">
              <div className="p-2 sm:p-3 bg-purple-100 rounded-lg">
                <Clock className="w-5 h-5 sm:w-6 sm:h-6 text-purple-600" />
              </div>
              <TrendingUp className="w-4 h-4 sm:w-5 sm:h-5 text-purple-500" />
            </div>
            <h3 className="text-xs sm:text-sm font-medium text-gray-600 mb-1">Avg Response Time</h3>
            <p className="text-2xl sm:text-3xl font-bold text-gray-900">
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
            className="bg-white rounded-xl shadow-lg p-4 sm:p-6"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
          >
            <div className="flex items-center justify-between mb-3 sm:mb-4">
              <div className="p-2 sm:p-3 bg-orange-100 rounded-lg">
                <Shield className="w-5 h-5 sm:w-6 sm:h-6 text-orange-600" />
              </div>
              <TrendingUp className="w-4 h-4 sm:w-5 sm:h-5 text-orange-500" />
                   </div>
            <h3 className="text-xs sm:text-sm font-medium text-gray-600 mb-1">Downtime</h3>
            <p className="text-2xl sm:text-3xl font-bold text-gray-900">
              {loading ? '...' : `${modelStats.downtime}%`}
            </p>
            <p className="text-xs text-gray-500 mt-1">
              {loading ? 'Loading...' : 'Last 30 days'}
            </p>
          </motion.div>
                </div>

        {/* Recent Crop Analyses */}
        <motion.div
          className="bg-white rounded-xl shadow-lg p-4 sm:p-6 mb-6 sm:mb-8"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.5 }}
        >
          <div className="flex items-center justify-between mb-4 sm:mb-6">
            <h2 className="text-lg sm:text-xl font-semibold text-gray-900 flex items-center">
              <Activity className="w-5 h-5 sm:w-6 sm:h-6 mr-2 text-green-600" />
              <span className="hidden sm:inline">Latest Crop Analyses</span>
              <span className="sm:hidden">Crop Analyses</span>
            </h2>
            {usingSampleData && (
              <span className="text-xs bg-yellow-100 text-yellow-800 px-2 py-1 rounded-full">
                Sample Data
              </span>
            )}
          </div>
          
          <div className="space-y-2 sm:space-y-3">
            {(showAllAnalyses ? allAnalyses : recentAnalyses).length > 0 ? (showAllAnalyses ? allAnalyses : recentAnalyses).map((analysis) => (
              <motion.div
                key={analysis.id}
                className="flex flex-col sm:flex-row items-start sm:items-center justify-between p-3 sm:p-3.5 border border-gray-100 rounded-lg gap-2 sm:gap-0"
                whileHover={{ scale: 1.01, backgroundColor: "#f0f0f0", boxShadow: "0 5px 10px rgba(0, 0, 0, 0.05)" }}
                transition={{ type: "spring", stiffness: 400, damping: 10 }}
              >
                <div className="flex items-center space-x-2 sm:space-x-4 flex-1 min-w-0">
                  <div className={`w-2 sm:w-2.5 h-2 sm:h-2.5 rounded-full flex-shrink-0 ${
                    analysis.status === 'Healthy' ? 'bg-green-500' : 'bg-red-500'
                  }`} />
                  <div className="min-w-0 flex-1">
                    <p className="font-medium text-gray-800 text-sm sm:text-base truncate">{analysis.crop}</p>
                    <p className="text-xs text-gray-500 truncate">{analysis.location}</p>
                  </div>
                </div>
                <div className="flex items-center justify-between sm:flex-col sm:items-end gap-1 sm:gap-0 sm:ml-4">
                  <p className={`font-medium text-xs sm:text-sm ${analysis.status === 'Healthy' ? 'text-green-600' : 'text-red-600'}`}>{analysis.status}</p>
                  <p className="text-xs text-gray-500 whitespace-nowrap">{analysis.confidence}%</p>
                </div>
                <div className="text-xs text-gray-400 ml-auto sm:ml-0 whitespace-nowrap">
                  {new Date(analysis.date).toLocaleDateString()}
                </div>
              </motion.div>
            )) : (
              <div className="text-center py-6 sm:py-8 text-gray-500">
                <Activity className="w-10 h-10 sm:w-12 sm:h-12 mx-auto mb-4 text-gray-300" />
                <p className="text-sm sm:text-base">No recent analyses found</p>
                <p className="text-xs sm:text-sm text-gray-400 mt-1">Analyses will appear here once crops are analyzed</p>
              </div>
            )}
          </div>
          
          <div className="mt-4 sm:mt-5">
            <button 
              onClick={handleViewAllAnalyses}
              className="inline-flex items-center text-green-600 hover:text-green-700 font-semibold text-xs sm:text-sm transition-all hover:scale-[1.02]"
            >
              {showAllAnalyses ? 'Show Recent' : 'View All'}
              <Activity className="w-3 h-3 sm:w-3.5 sm:h-3.5 ml-1 sm:ml-2" />
            </button>
          </div>
        </motion.div>

        {/* System Status */}
        <motion.div
          className="bg-white rounded-xl shadow-lg p-4 sm:p-6 mb-6 sm:mb-8"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.6 }}
        >
          <h2 className="text-lg sm:text-xl font-semibold text-gray-900 mb-4 sm:mb-6 flex items-center">
            <Server className="w-5 h-5 sm:w-6 sm:h-6 mr-2 text-blue-600" />
            System Status
          </h2>
          
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-black text-sm">ML Server</span>
              <div className={`flex items-center space-x-2 ${serverHealth.status === 'healthy' ? 'glow-green' : 'glow-red'}`}>
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
          className="bg-white rounded-xl shadow-lg p-4 sm:p-6 mb-6 sm:mb-8"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.7 }}
        >
          <h2 className="text-lg sm:text-xl font-semibold text-gray-900 mb-4 sm:mb-6 flex items-center">
            <BarChart3 className="w-5 h-5 sm:w-6 sm:h-6 mr-2 text-blue-600" />
            Performance Trends
          </h2>
          
          <div className="h-48 sm:h-64 bg-gray-50 rounded-lg flex items-center justify-center px-2">
            <div className="text-center">
              <BarChart3 className="w-10 h-10 sm:w-12 sm:h-12 text-gray-400 mx-auto mb-2" />
              <p className="text-xs sm:text-sm text-gray-500">Performance chart will be displayed here</p>
              <p className="text-xs text-gray-400 mt-1">Integration with monitoring dashboard coming soon</p>
                    </div>
                  </div>
        </motion.div>

        {/* Recent Activity */}
        <motion.div
          className="bg-white rounded-xl shadow-lg p-4 sm:p-6"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.8 }}
        >
          <h2 className="text-lg sm:text-xl font-semibold text-gray-900 mb-4 sm:mb-6 flex items-center">
            <Activity className="w-5 h-5 sm:w-6 sm:h-6 mr-2 text-green-600" />
            Recent Activity
          </h2>
          
          <div className="space-y-4">

            <div className="flex items-center justify-between p-4 bg-blue-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                <span className="text-sm text-gray-700">
                  Active users: {loading ? '...' : modelStats.activeUsers.toLocaleString()}
                  {!loading && modelStats.trends.activeUsersChange > 0 && ` (+${modelStats.trends.activeUsersChange} new)`}
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
                  Backend Downtime: {loading ? '...' : `${modelStats.downtime}%`}
                </span>
              </div>
              <span className="text-xs text-gray-500">
                {isClient && modelStats.lastUpdated ? new Date(modelStats.lastUpdated).toLocaleTimeString() : 'Loading...'}
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
