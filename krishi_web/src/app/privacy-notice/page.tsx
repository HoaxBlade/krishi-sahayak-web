import React from 'react';
import LegalPagesHeader from '@/components/LegalPagesHeader';

const PrivacyNoticePage = () => {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8 flex flex-col items-center">
      <div className="max-w-4xl w-full bg-white p-8 rounded-lg shadow-md">
        <LegalPagesHeader activeTab="privacy-notice" />
        <h1 className="text-4xl font-bold mb-6 text-green-700">Privacy Notice</h1>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4 text-green-600">1. Introduction</h2>
          <p className="text-gray-700 leading-relaxed">
            This Privacy Notice explains how Krishi Sahayak collects, uses, and discloses information about you when you use our mobile application and website (collectively, the &quot;Service&quot;).
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4 text-green-600">2. Information We Collect</h2>
          <p className="text-gray-700 leading-relaxed mb-2">
            We collect information you provide directly to us, such as when you create an account, use the Service, or communicate with us. This may include:
          </p>
          <ul className="list-disc list-inside text-gray-700 ml-4">
            <li>Personal identification information (Name, email address, phone number, etc.)</li>
            <li>Location data (with your permission)</li>
            <li>Agricultural data (crop types, soil conditions, etc.)</li>
            <li>Device information (device model, operating system, unique device identifiers)</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4 text-green-600">3. How We Use Your Information</h2>
          <p className="text-gray-700 leading-relaxed mb-2">
            We use the information we collect to:
          </p>
          <ul className="list-disc list-inside text-gray-700 ml-4">
            <li>Provide, maintain, and improve our Service</li>
            <li>Personalize your experience</li>
            <li>Communicate with you</li>
            <li>Monitor and analyze trends, usage, and activities in connection with our Service</li>
            <li>Detect, investigate, and prevent fraudulent transactions and other illegal activities</li>
            <li>Protect the rights and property of Krishi Sahayak and others</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4 text-green-600">4. Sharing of Information</h2>
          <p className="text-gray-700 leading-relaxed mb-2">
            We may share information about you as follows or as otherwise described in this Privacy Notice:
          </p>
          <ul className="list-disc list-inside text-gray-700 ml-4">
            <li>With vendors, consultants, and other service providers who need access to such information to carry out work on our behalf</li>
            <li>In response to a request for information if we believe disclosure is in accordance with, or required by, any applicable law, regulation, or legal process</li>
            <li>If we believe your actions are inconsistent with our user agreements or policies, or to protect the rights, property, and safety of Krishi Sahayak and others</li>
            <li>In connection with, or during negotiations of, any merger, sale of company assets, financing, or acquisition of all or a portion of our business by another company</li>
            <li>With your consent or at your direction</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4 text-green-600">5. Data Security</h2>
          <p className="text-gray-700 leading-relaxed">
            We take reasonable measures to help protect information about you from loss, theft, misuse, and unauthorized access, disclosure, alteration, and destruction.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4 text-green-600">6. Your Choices</h2>
          <p className="text-gray-700 leading-relaxed">
            You may update, correct, or delete information about you at any time by logging into your account. You may also opt out of receiving promotional communications from us by following the instructions in those communications.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4 text-green-600">7. Changes to This Privacy Notice</h2>
          <p className="text-gray-700 leading-relaxed">
            We may change this Privacy Notice from time to time. If we make changes, we will notify you by revising the date at the top of the notice and, in some cases, we may provide you with additional notice (such as adding a statement to our homepage or sending you a notification).
          </p>
        </section>

        <section>
          <h2 className="text-2xl font-semibold mb-4 text-green-600">8. Contact Us</h2>
          <p className="text-gray-700 leading-relaxed">
            If you have any questions about this Privacy Notice, please contact us at krishi.sahayak2025@gmail.com
          </p>
        </section>
      </div>
    </div>
  );
};

export default PrivacyNoticePage;