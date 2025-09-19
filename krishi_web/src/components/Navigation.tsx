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
  User
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
    { name: 'Requirements', href: '/weather', icon: MapPin },
    { name: 'Dashboard', href: '/dashboard', icon: BarChart3 },
  ]

  return (
    <nav className="bg-white shadow-subtle border-b border-gray-100 sticky top-0 z-50">
      <a href="#main-content" className="sr-only focus:not-sr-only focus:absolute focus:top-0 focus:left-0 focus:z-50 focus:bg-green-600 focus:text-white focus:p-3 focus:rounded-br-lg">Skip to main content</a>
      <div className="max-w-full mx-auto px-4">
        <div className="flex justify-between items-center">
          {/* Logo */}
          <Link href="/" className="flex items-center space-x-3">
            <Image
              src="/logo.jpg"
              alt="Krishi Sahayak Logo"
              width={70}
              height={70}
              className="rounded-full object-cover"
            />
            <div className="flex flex-col justify-center items-start">
              <Image
                src="/name.png"
                alt="Krishi Sahayak"
                width={150}
                height={250}
                className="object-contain pt-4"
              />
              <div className="flex items-center space-x-1">
                <span className="text-sm text-gray-500">Powered by:</span>
                <Image
                  src="/NIELIT.png"
                  alt="NIELIT Logo"
                  width={40}
                  height={40}
                  className="object-contain"
                />
              </div>
            </div>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-6">
            {navItems.map((item) => (
              <Link
                key={item.name}
                href={item.href}
                className={`relative flex items-center space-x-2 text-gray-600 hover:text-green-600 transition-colors px-3 py-2 rounded-md ${
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
                <span className="text-sm">{item.name}</span>
              </Link>
            ))}
            
            {isAuthenticated ? (
              <div className="flex items-center space-x-3">
                <Link
                  href="/profile"
                  className="flex items-center space-x-2 text-gray-600 hover:text-gray-900 transition-colors px-3 py-2 rounded-lg hover:bg-gray-100"
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
                className="bg-green-600 text-white px-5 py-2.5 rounded-lg font-medium hover:bg-green-700 transition-all shadow-md hover:shadow-lg flex items-center space-x-2"
              >
                <LogIn className="w-4 h-4" />
                <span>Get Started</span>
              </Link>
            )}
          </div>

          {/* Mobile menu button */}
          <button
            onClick={() => setIsOpen(!isOpen)}
            className="md:hidden p-2 rounded-lg text-gray-600 hover:text-gray-900 hover:bg-gray-100 transition-colors"
            aria-controls="mobile-menu"
            aria-expanded={isOpen}
          >
            {isOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile Navigation */}
        {isOpen && (
          <motion.div
            id="mobile-menu"
            className="md:hidden py-2 border-t border-gray-200"
            initial={{ opacity: 0, maxHeight: 0 }}
            animate={{ opacity: 1, maxHeight: '300px' }}
            exit={{ opacity: 0, maxHeight: 0 }}
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
