import React from 'react';
import LegalPagesHeader from '../../components/LegalPagesHeader';

const CookieManagementPage = () => {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8 flex flex-col items-center">
      <div className="max-w-4xl w-full bg-white p-8 rounded-lg shadow-md">
      <LegalPagesHeader />
      <h1 className="text-4xl font-bold mb-6 text-green-700">Cookie Management Policy</h1>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold mb-4 text-green-600">1. Introduction</h2>
        <p className="text-gray-700 leading-relaxed">
          Welcome to Krishi Sahayak. This Cookie Management Policy explains how we use cookies and similar technologies
          on our website and services. By using our website, you consent to the use of cookies in accordance with this policy.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold mb-4 text-green-600">2. What are Cookies?</h2>
        <p className="text-gray-700 leading-relaxed">
          Cookies are small text files that are placed on your device (computer, tablet, mobile phone) when you visit a website.
          They are widely used to make websites work more efficiently, as well as to provide information to the owners of the site.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold mb-4 text-green-600">3. How We Use Cookies</h2>
        <p className="text-gray-700 leading-relaxed mb-2">
          We use cookies for various purposes, including:
        </p>
        <ul className="list-disc list-inside text-gray-700 ml-4">
          <li><strong>Essential Cookies:</strong> These are necessary for the website to function and cannot be switched off in our systems. They are usually only set in response to actions made by you which amount to a request for services, such as setting your privacy preferences, logging in, or filling in forms.</li>
          <li><strong>Analytical/Performance Cookies:</strong> These allow us to count visits and traffic sources so we can measure and improve the performance of our site. They help us to know which pages are the most and least popular and see how visitors move around the site.</li>
          <li><strong>Functionality Cookies:</strong> These enable the website to provide enhanced functionality and personalization. They may be set by us or by third-party providers whose services we have added to our pages.</li>
          <li><strong>Targeting/Advertising Cookies:</strong> These may be set through our site by our advertising partners. They may be used by those companies to build a profile of your interests and show you relevant adverts on other sites.</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold mb-4 text-green-600">4. Third-Party Cookies</h2>
        <p className="text-gray-700 leading-relaxed">
          In addition to our own cookies, we may also use various third-parties cookies to report usage statistics of the Service,
          deliver advertisements on and through the Service, and so on.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold mb-4 text-green-600">5. Your Cookie Choices</h2>
        <p className="text-gray-700 leading-relaxed mb-2">
          You have the right to decide whether to accept or reject cookies. You can exercise your cookie preferences by:
        </p>
        <ul className="list-disc list-inside text-gray-700 ml-4">
          <li><strong>Browser Settings:</strong> Most web browsers allow you to control cookies through their settings preferences. You can set your browser to refuse all or some browser cookies, or to alert you when cookies are being sent.</li>
          <li><strong>Opt-out Links:</strong> For some third-party cookies, you can opt out directly by visiting the third party&#39;s opt-out page.</li>
        </ul>
        <p className="text-gray-700 leading-relaxed mt-2">
          Please note that if you choose to disable cookies, some parts of our website may not function properly.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold mb-4 text-green-600">6. Changes to This Policy</h2>
        <p className="text-gray-700 leading-relaxed">
          We may update our Cookie Management Policy from time to time. We will notify you of any changes by posting the new
          Cookie Management Policy on this page. You are advised to review this Cookie Management Policy periodically for any changes.
        </p>
      </section>

      <section>
        <h2 className="text-2xl font-semibold mb-4 text-green-600">7. Contact Us</h2>
        <p className="text-gray-700 leading-relaxed">
          If you have any questions about this Cookie Management Policy, please contact us at krishi.sahayak2025@gmail.com.
        </p>
      </section>
      </div>
    </div>
  );
};

export default CookieManagementPage;