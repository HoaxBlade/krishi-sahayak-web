"use client";
import React, { useState } from 'react';
import ReactMarkdown from 'react-markdown';

interface TermsAndConditionsProps {
  termsContent: string;
  privacyContent: string;
  cookieContent: string;
}

export default function TermsAndConditions({ termsContent, privacyContent, cookieContent }: TermsAndConditionsProps) {
  const [activeSection, setActiveSection] = useState<'terms' | 'privacy' | 'cookie'>('terms');

  const renderContent = () => {
    switch (activeSection) {
      case 'terms':
        return termsContent;
      case 'privacy':
        return privacyContent;
      case 'cookie':
        return cookieContent;
      default:
        return '';
    }
  };

  const getTabClasses = (section: 'terms' | 'privacy' | 'cookie') =>
    `cursor-pointer px-3 sm:px-4 py-3 sm:py-2 text-sm sm:text-base lg:text-lg font-medium transition-colors duration-200 ${
      activeSection === section
        ? 'border-b-2 border-green-600 text-green-600 bg-green-50 sm:bg-transparent'
        : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50 sm:hover:bg-transparent'
    }`;

  return (
    <div className="bg-white/80 backdrop-blur-sm rounded-xl shadow-lg border border-white/20 overflow-hidden">
      {/* Responsive Tab Navigation */}
      <div className="border-b border-gray-200 bg-gradient-to-r from-green-50/50 to-blue-50/50">
        <div className="flex flex-col sm:flex-row overflow-x-auto">
          <div className={getTabClasses('terms')} onClick={() => setActiveSection('terms')}>
            <span className="whitespace-nowrap">Terms & Conditions</span>
          </div>
          <div className={getTabClasses('privacy')} onClick={() => setActiveSection('privacy')}>
            <span className="whitespace-nowrap">Privacy Notice</span>
          </div>
          <div className={getTabClasses('cookie')} onClick={() => setActiveSection('cookie')}>
            <span className="whitespace-nowrap">Cookie Management</span>
          </div>
        </div>
      </div>

      {/* Content Area */}
      <div className="p-4 sm:p-6 lg:p-8">

        <ReactMarkdown
          components={{
            h1: ({ ...props }) => <h1 className="text-xl sm:text-2xl lg:text-3xl font-bold mt-4 sm:mt-6 mb-3 sm:mb-4 text-gray-900 leading-tight" {...props} />,
            h2: ({ ...props }) => <h2 className="text-lg sm:text-xl lg:text-2xl font-semibold mt-4 sm:mt-5 mb-2 sm:mb-3 text-gray-900 leading-tight" {...props} />,
            h3: ({ ...props }) => <h3 className="text-base sm:text-lg lg:text-xl font-medium mt-3 sm:mt-4 mb-2 text-gray-900 leading-tight" {...props} />,
            p: ({ ...props }) => <p className="mb-3 sm:mb-4 leading-relaxed text-sm sm:text-base lg:text-lg text-gray-900" {...props} />,
            ul: ({ ...props }) => <ul className="list-disc list-inside mb-3 sm:mb-4 pl-4 sm:pl-5 text-sm sm:text-base lg:text-lg text-gray-900 space-y-1" {...props} />,
            ol: ({ ...props }) => <ol className="list-decimal list-inside mb-3 sm:mb-4 pl-4 sm:pl-5 text-sm sm:text-base lg:text-lg text-gray-900 space-y-1" {...props} />,
            a: ({ ...props }) => <a className="text-green-600 hover:underline break-words" {...props} />,
            strong: ({ ...props }) => <strong className="font-semibold text-gray-900" {...props} />,
            em: ({ ...props }) => <em className="italic text-gray-700" {...props} />,
          }}
        >
          {renderContent()}
        </ReactMarkdown>
      </div>
    </div>
  );
}