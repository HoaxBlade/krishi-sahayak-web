import Image from 'next/image';
import Link from 'next/link';

export default function Footer() {
  return (
    <footer className="bg-gray-900 text-white py-10 relative">
      <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-green-500 via-blue-500 to-green-500" />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <div className="flex flex-col items-center justify-center space-y-2 mb-8">
          <div className="flex items-center space-x-2">
            <Image
              src="/logo.jpg"
              alt="Krishi Sahayak Logo"
              width={50}
              height={50}
              className="rounded-full object-cover transition-transform hover:scale-[1.03]"
            />
            <span className="text-2xl font-bold text-white">Krishi Sahayak</span>
          </div>
          <div className="flex flex-col items-center space-y-1">
            <span className="text-sm text-gray-400">Powered by:</span>
            <Image
              src="/NIELIT.png"
              alt="NIELIT Logo"
              width={50}
              height={50}
              className="object-contain transition-transform hover:scale-[1.03]"
            />
          </div>
        </div>
        <p className="text-gray-400 mb-3 text-sm">Empowering farmers with AI-driven agricultural solutions</p>
        <div className="mt-8 border-t border-gray-700 pt-8">
          <div className="flex justify-center space-x-6 text-sm">
            <Link href="/terms-and-conditions?section=terms" className="text-gray-400 hover:text-green-500 transition-colors duration-200">
              Terms & Conditions
            </Link>
            <Link href="/terms-and-conditions?section=privacy" className="text-gray-400 hover:text-green-500 transition-colors duration-200">
              Privacy Notice
            </Link>
            <Link href="/terms-and-conditions?section=cookie" className="text-gray-400 hover:text-green-500 transition-colors duration-200">
              Cookie Management
            </Link>
          </div>
          <p className="mt-4 text-gray-500 text-xs">
            &copy; {new Date().getFullYear()} Krishi Sahayak. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}