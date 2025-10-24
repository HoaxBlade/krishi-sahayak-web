import React, { useState, useEffect } from 'react';
import ReactMarkdown from 'react-markdown';

const TermsAndConditions: React.FC = () => {
  const [termsContent, setTermsContent] = useState('');

  useEffect(() => {
    fetch('/src/terms-and-conditions.md')
      .then((response) => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.text();
      })
      .then((text) => setTermsContent(text))
      .catch((error) => console.error('Error fetching terms and conditions:', error));
  }, []);

  return (
    <div className="container mx-auto p-4">
      <ReactMarkdown className="prose max-w-none">{termsContent}</ReactMarkdown>
    </div>
  );
};

export default TermsAndConditions;