import Link from 'next/link';
import Image from 'next/image';

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

        <div className="flex justify-center space-x-6 mb-8">
          <Link href="/" className="text-gray-300 hover:text-green-500 transition-colors text-sm">Home</Link>
          <Link href="/analyze" className="text-gray-300 hover:text-green-500 transition-colors text-sm">Analyze</Link>
          <Link href="/weather" className="text-gray-300 hover:text-green-500 transition-colors text-sm">Weather</Link>
          <Link href="/dashboard" className="text-gray-300 hover:text-green-500 transition-colors text-sm">Dashboard</Link>
        </div>

        <p className="text-gray-400 mb-3 text-sm">Empowering farmers with AI-driven agricultural solutions</p>
        <p className="text-gray-500 text-xs">© {new Date().getFullYear()} Krishi Sahayak. All rights reserved.</p>
      </div>
    </footer>
  );
}