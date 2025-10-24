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
    `cursor-pointer px-4 py-2 text-lg font-medium ${
      activeSection === section
        ? 'border-b-2 border-green-600 text-green-600'
        : 'text-gray-600 hover:text-gray-900'
    }`;

  return (
    <div className="p-8 rounded-lg shadow-subtle bg-white"> {/* Ensure white background for the component */}
      <div className="flex border-b border-gray-200 mb-6">
        <div className={getTabClasses('terms')} onClick={() => setActiveSection('terms')}>
          Terms & Conditions
        </div>
        <div className={getTabClasses('privacy')} onClick={() => setActiveSection('privacy')}>
          Privacy Notice
        </div>
        <div className={getTabClasses('cookie')} onClick={() => setActiveSection('cookie')}>
          Cookie Management
        </div>
      </div>

      <ReactMarkdown
        components={{
          h1: ({ ...props }) => <h1 className="text-3xl font-bold mt-6 mb-4 text-gray-900" {...props} />,
          h2: ({ ...props }) => <h2 className="text-2xl font-semibold mt-5 mb-3 text-gray-900" {...props} />,
          h3: ({ ...props }) => <h3 className="text-xl font-medium mt-4 mb-2 text-gray-900" {...props} />,
          p: ({ ...props }) => <p className="mb-4 leading-relaxed text-lg text-gray-900" {...props} />,
          ul: ({ ...props }) => <ul className="list-disc list-inside mb-4 pl-5 text-lg text-gray-900" {...props} />,
          ol: ({ ...props }) => <ol className="list-decimal list-inside mb-4 pl-5 text-lg text-gray-900" {...props} />,
          a: ({ ...props }) => <a className="text-green-600 hover:underline" {...props} />,
        }}
      >
        {renderContent()}
      </ReactMarkdown>
    </div>
  );
}