import fs from 'fs/promises';
import path from 'path';
import TermsAndConditions from '../../components/TermsAndConditions';

export default async function TermsAndConditionsPage() {
  let termsContent = '';
  let privacyContent = '';
  let cookieContent = '';

  try {
    const termsFilePath = path.join(process.cwd(), 'src', 'terms-and-conditions.md');
    termsContent = await fs.readFile(termsFilePath, 'utf8');
  } catch (error) {
    console.error('Error loading terms and conditions markdown:', error);
    termsContent = 'Error loading terms and conditions.';
  }

  try {
    const privacyFilePath = path.join(process.cwd(), 'src', 'privacy-notice.md');
    privacyContent = await fs.readFile(privacyFilePath, 'utf8');
  } catch (error) {
    console.error('Error loading privacy notice markdown:', error);
    privacyContent = 'Error loading privacy notice.';
  }

  try {
    const cookieFilePath = path.join(process.cwd(), 'src', 'cookie-management.md');
    cookieContent = await fs.readFile(cookieFilePath, 'utf8');
  } catch (error) {
    console.error('Error loading cookie management markdown:', error);
    cookieContent = 'Error loading cookie management policy.';
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold mb-6 text-gray-900 text-center sm:text-left">
            Legal Information
          </h1>
          <TermsAndConditions
            termsContent={termsContent}
            privacyContent={privacyContent}
            cookieContent={cookieContent}
          />
        </div>
      </div>
    </div>
  );
}