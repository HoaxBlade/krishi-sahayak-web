'use client'

import { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation' // Import usePathname
import { motion } from 'framer-motion'
import {
  Leaf,
  Menu,
  X,
  Camera,
  Cloud,
  BarChart3,
  Home
} from 'lucide-react'

export default function Navigation() {
  const [isOpen, setIsOpen] = useState(false)
  const pathname = usePathname() // Initialize usePathname

  const navItems = [
    { name: 'Home', href: '/', icon: Home },
    { name: 'Analyze', href: '/analyze', icon: Camera },
    { name: 'Weather', href: '/weather', icon: Cloud },
    { name: 'Dashboard', href: '/dashboard', icon: BarChart3 },
  ]

  return (
    <nav className="bg-white shadow-subtle border-b border-gray-100 sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center py-3"> {/* Adjusted padding */}
          {/* Logo */}
          <Link href="/" className="flex items-center space-x-2">
            <Leaf className="w-7 h-7 text-green-600" /> {/* Slightly smaller icon */}
            <span className="text-xl font-bold text-gray-900">Krishi Sahayak</span> {/* Slightly smaller text */}
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-6"> {/* Adjusted spacing */}
            {navItems.map((item) => (
              <Link
                key={item.name}
                href={item.href}
                className={`flex items-center space-x-2 text-gray-600 hover:text-green-600 transition-colors px-3 py-2 rounded-md ${ /* Added padding and rounded corners */
                  pathname === item.href ? 'text-green-600 font-semibold bg-green-50' : '' /* Added background for active */
                }`}
              >
                <item.icon className="w-4 h-4" /> {/* Slightly smaller icon */}
                <span className="text-sm">{item.name}</span> {/* Slightly smaller text */}
              </Link>
            ))}
            
            <button className="bg-green-600 text-white px-5 py-2.5 rounded-lg font-medium hover:bg-green-700 transition-all shadow-md hover:shadow-lg"> {/* Refined button style */}
              Get Started
            </button>
          </div>

          {/* Mobile menu button */}
          <button
            onClick={() => setIsOpen(!isOpen)}
            className="md:hidden p-2 rounded-lg text-gray-600 hover:text-gray-900 hover:bg-gray-100 transition-colors"
          >
            {isOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile Navigation */}
        {isOpen && (
          <motion.div
            className="md:hidden py-2 border-t border-gray-200" /* Adjusted padding */
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.2 }}
          >
            <div className="space-y-1"> {/* Adjusted spacing */}
              {navItems.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`flex items-center space-x-3 px-4 py-2 text-gray-700 hover:text-green-600 hover:bg-green-50 rounded-lg transition-colors ${ /* Adjusted padding and text color */
                    pathname === item.href ? 'text-green-600 font-semibold bg-green-50' : ''
                  }`}
                  onClick={() => setIsOpen(false)}
                >
                  <item.icon className="w-5 h-5" />
                  <span>{item.name}</span>
                </Link>
              ))}
              <div className="px-4 pt-2">
                <button className="w-full bg-green-600 text-white px-4 py-2.5 rounded-lg font-medium hover:bg-green-700 transition-colors shadow-md"> {/* Refined button style */}
                  Get Started
                </button>
              </div>
            </div>
          </motion.div>
        )}
      </div>
    </nav>
  )
}
