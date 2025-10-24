"use client";

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import React from 'react';

interface LegalPagesHeaderProps {
  activeTab?: 'terms-and-conditions' | 'privacy-notice' | 'cookie-management';
}

const LegalPagesHeader: React.FC<LegalPagesHeaderProps> = ({ activeTab }) => {
  const getTabClasses = (path: string) =>
    `cursor-pointer px-4 py-2 text-lg font-medium ${
      activeTab === path
        ? 'border-b-2 border-green-500 text-green-500'
        : 'text-gray-600 hover:text-green-500 transition-colors duration-200'
    }`;

  return (
    <div className="flex border-b border-gray-200 mb-6">
      <Link href="/terms-and-conditions" className={getTabClasses('/terms-and-conditions')}>
        Terms & Conditions
      </Link>
      <Link href="/privacy-notice" className={getTabClasses('/privacy-notice')}>
        Privacy Notice
      </Link>
      <Link href="/cookie-management" className={getTabClasses('/cookie-management')}>
        Cookie Management
      </Link>
    </div>
  );
};

export default LegalPagesHeader;