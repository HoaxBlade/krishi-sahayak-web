'use client'

import { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation' // Import usePathname
import { motion } from 'framer-motion'
import {
  Menu,
  X,
  Activity,
  MapPin,
  BarChart3,
  Home,
  LogIn,
  User,
  Store
} from 'lucide-react'
import Image from 'next/image'
import { useAuth } from '@/contexts/AuthContext'

export default function Navigation() {
  const [isOpen, setIsOpen] = useState(false)
  const pathname = usePathname() // Initialize usePathname
  const { user, isAuthenticated } = useAuth()

  const navItems = [
    { name: 'Home', href: '/', icon: Home },
    { name: 'Stats', href: '/analyze', icon: Activity },
    { name: 'Marketplace', href: '/marketplace', icon: Store },
    { name: 'Requirements', href: '/weather', icon: MapPin },
    { name: 'Dashboard', href: '/dashboard', icon: BarChart3 },
  ]

  return (
    <nav className="shadow-subtle border-b border-gray-100 sticky top-0 z-50 min-h-[70px] sm:min-h-[80px] bg-white">
      <a href="#main-content" className="sr-only focus:not-sr-only focus:absolute focus:top-0 focus:left-0 focus:z-50 focus:bg-green-600 focus:text-white focus:p-3 focus:rounded-br-lg">Skip to main content</a>
      <div className="max-w-full mx-auto px-3 sm:px-4">
        <div className="flex justify-between items-center">
          {/* Logo */}
          <Link href="/" className="flex items-center space-x-2 sm:space-x-3">
            <Image
              src="/applogo.png"
              alt="Krishi Sahayak Logo"
              width={50}
              height={50}
              className="sm:w-[60px] sm:h-[60px] md:w-[70px] md:h-[70px] rounded-full object-cover"
            />
            <div className="flex flex-col justify-center items-start pt-1 sm:pt-2">
              <Image
                src="/name.png"
                alt="Krishi Sahayak"
                width={100}
                height={167}
                className="sm:w-[120px] md:w-[150px] object-contain flex-shrink-0"
                priority
              />
              <div className="hidden sm:flex items-center space-x-1">
                <span className="text-xs sm:text-sm text-gray-500">Powered by:</span>
                <Image
                  src="/NIELIT.png"
                  alt="NIELIT Logo"
                  width={35}
                  height={35}
                  className="sm:w-9 sm:h-9 md:w-10 md:h-10 object-contain"
                />
              </div>
            </div>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden lg:flex items-center space-x-4 xl:space-x-6">
            {navItems.map((item) => (
              <Link
                key={item.name}
                href={item.href}
                className={`relative flex items-center space-x-1 xl:space-x-2 text-gray-600 hover:text-green-600 transition-colors px-2 xl:px-3 py-2 rounded-md ${
                  pathname === item.href ? 'text-green-600 font-semibold bg-green-50' : ''
                }`}
              >
                {pathname === item.href && (
                  <motion.span
                    layoutId="underline"
                    className="absolute bottom-0 left-0 w-full h-0.5 bg-green-600"
                    initial={false}
                    transition={{ type: "spring", stiffness: 500, damping: 30 }}
                  />
                )}
                <item.icon className="w-4 h-4" />
                <span className="text-xs xl:text-sm">{item.name}</span>
              </Link>
            ))}
            
            {isAuthenticated ? (
              <div className="flex items-center space-x-2 xl:space-x-3">
                <Link
                  href="/profile"
                  className="flex items-center space-x-1 xl:space-x-2 text-gray-600 hover:text-gray-900 transition-colors px-2 xl:px-3 py-2 rounded-lg hover:bg-gray-100"
                >
                  <User className="w-4 h-4" />
                  <span className="text-xs xl:text-sm">
                        Hi {user?.user_metadata?.full_name || user?.email?.split('@')[0] || 'User'}
                  </span>
                </Link>
              </div>
            ) : (
              <Link
                href="/login"
                className="bg-green-600 text-white px-4 xl:px-5 py-2 rounded-lg xl:py-2.5 text-xs xl:text-sm font-medium hover:bg-green-700 transition-all shadow-md hover:shadow-lg flex items-center space-x-2"
              >
                <LogIn className="w-4 h-4" />
                <span>Get Started</span>
              </Link>
            )}
          </div>

          {/* Mobile/Tablet menu button */}
          <button
            onClick={() => setIsOpen(!isOpen)}
            className="lg:hidden p-2 rounded-lg text-gray-600 hover:text-gray-900 hover:bg-gray-100 transition-colors"
            aria-controls="mobile-menu"
            aria-expanded={isOpen}
          >
            {isOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile/Tablet Navigation */}
        {isOpen && (
          <motion.div
            id="mobile-menu"
            className="lg:hidden py-2 border-t border-gray-200 bg-white"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.3, ease: "easeInOut" }}
          >
            <div className="space-y-1">
              {navItems.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`flex items-center space-x-3 px-4 py-2 text-gray-700 hover:text-green-600 hover:bg-green-50 rounded-lg transition-colors ${
                    pathname === item.href ? 'text-green-600 font-semibold bg-green-50' : ''
                  }`}
                  onClick={() => setIsOpen(false)}
                >
                  <item.icon className="w-5 h-5" />
                  <span>{item.name}</span>
                </Link>
              ))}
              <div className="px-4 pt-2">
                {isAuthenticated ? (
                  <div className="space-y-2">
                    <Link
                      href="/profile"
                      className="flex items-center space-x-2 text-gray-600 hover:text-gray-900 transition-colors px-2 py-2 rounded-lg hover:bg-gray-100"
                      onClick={() => setIsOpen(false)}
                    >
                      <User className="w-4 h-4" />
                      <span className="text-sm">
                        Hi {user?.user_metadata?.full_name || user?.email?.split('@')[0] || 'User'}
                      </span>
                    </Link>
                  </div>
                ) : (
                  <Link
                    href="/login"
                    className="w-full bg-green-600 text-white px-4 py-2.5 rounded-lg font-medium hover:bg-green-700 transition-colors shadow-md flex items-center justify-center space-x-2"
                    onClick={() => setIsOpen(false)}
                  >
                    <LogIn className="w-4 h-4" />
                    <span>Get Started</span>
                  </Link>
                )}
              </div>
            </div>
          </motion.div>
        )}
      </div>
    </nav>
  )
}
