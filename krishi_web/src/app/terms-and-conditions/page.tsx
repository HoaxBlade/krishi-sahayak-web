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
    <div className="container mx-auto p-4 bg-white text-gray-900 min-h-screen">
      <h1 className="text-3xl font-bold mb-6">Legal Information</h1> {/* Changed heading */}
      <TermsAndConditions
        termsContent={termsContent}
        privacyContent={privacyContent}
        cookieContent={cookieContent}
      />
    </div>
  );
}