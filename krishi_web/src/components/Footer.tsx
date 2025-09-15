import Link from 'next/link';
import Image from 'next/image';

export default function Footer() {
  return (
    <footer className="bg-gray-900 text-white py-10 relative">
      <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-green-500 via-blue-500 to-green-500" />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <div className="flex flex-col items-center justify-center space-y-2 mb-5">
          <div className="flex items-center space-x-2">
            <Image
              src="/logo.jpg"
              alt="Krishi Sahayak Logo"
              width={50}
              height={50}
              className="rounded-full object-cover"
            />
            <span className="text-2xl font-bold text-white">Krishi Sahayak</span>
          </div>
          <div className="flex flex-col items-center space-y-1">
            <span className="text-sm text-gray-400">Powered by:</span>
            <Image
              src="/NIELIT.jpeg"
              alt="NIELIT Logo"
              width={40}
              height={40}
              className="object-contain"
            />
          </div>
        </div>
        <p className="text-gray-400 mb-3 text-sm">Empowering farmers with AI-driven agricultural solutions</p>
        <p className="text-gray-500 text-xs">© 2025 Krishi Sahayak. All rights reserved.</p>
      </div>
    </footer>
  );
}