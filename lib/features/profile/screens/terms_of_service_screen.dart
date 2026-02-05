import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Terms of Service',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Updated',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'February 4, 2026',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Acceptance of Terms',
              'By accessing and using MedTrack ("the App"), you accept and agree to be bound by the terms and provisions of this agreement. If you do not agree to these terms, please do not use our services.',
            ),
            _buildSection(
              '2. Medical Disclaimer',
              'MedTrack is designed to help you manage and track your medical records. It is NOT a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.',
            ),
            _buildSection(
              '3. User Responsibilities',
              'You are responsible for:\n\n'
                  '• Maintaining the confidentiality of your account credentials\n'
                  '• All activities that occur under your account\n'
                  '• Ensuring the accuracy of information you provide\n'
                  '• Keeping your medical information up to date\n'
                  '• Complying with all applicable laws and regulations',
            ),
            _buildSection(
              '4. Data Collection and Use',
              'We collect and process your medical data to provide our services. This includes:\n\n'
                  '• Medical reports and test results you upload\n'
                  '• Health information you manually enter\n'
                  '• Usage data to improve our services\n'
                  '• Account information (name, email, phone)\n\n'
                  'Your data is encrypted and stored securely. We will never sell your personal or medical information to third parties.',
            ),
            _buildSection(
              '5. Health Data Security',
              'We implement industry-standard security measures to protect your health data:\n\n'
                  '• End-to-end encryption\n'
                  '• Secure cloud storage\n'
                  '• Regular security audits\n'
                  '• Access controls and authentication\n\n'
                  'However, no method of transmission over the Internet is 100% secure, and we cannot guarantee absolute security.',
            ),
            _buildSection(
              '6. Intellectual Property',
              'The App and its original content, features, and functionality are owned by MedTrack and are protected by international copyright, trademark, and other intellectual property laws.',
            ),
            _buildSection(
              '7. Prohibited Uses',
              'You agree NOT to:\n\n'
                  '• Use the App for any unlawful purpose\n'
                  '• Upload false or misleading medical information\n'
                  '• Attempt to gain unauthorized access to the system\n'
                  '• Share your account with others\n'
                  '• Use the App to practice medicine without proper licensing\n'
                  '• Transmit viruses or malicious code',
            ),
            _buildSection(
              '8. Third-Party Services',
              'Our App may contain links to third-party services or integrate with external healthcare systems. We are not responsible for the content, privacy policies, or practices of third-party services.',
            ),
            _buildSection(
              '9. Service Availability',
              'We strive to maintain continuous service availability but cannot guarantee uninterrupted access. We reserve the right to modify or discontinue the service with or without notice.',
            ),
            _buildSection(
              '10. Limitation of Liability',
              'MedTrack shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from:\n\n'
                  '• Your use or inability to use the service\n'
                  '• Unauthorized access to your data\n'
                  '• Errors or inaccuracies in content\n'
                  '• Any medical decisions made based on information in the App',
            ),
            _buildSection(
              '11. Account Termination',
              'We reserve the right to terminate or suspend your account immediately, without prior notice, for conduct that we believe violates these Terms of Service or is harmful to other users, us, or third parties.',
            ),
            _buildSection(
              '12. Changes to Terms',
              'We reserve the right to modify these terms at any time. We will notify you of significant changes via email or through the App. Your continued use after changes constitutes acceptance of the new terms.',
            ),
            _buildSection(
              '13. Governing Law',
              'These Terms shall be governed by and construed in accordance with the laws of your jurisdiction, without regard to its conflict of law provisions.',
            ),
            _buildSection(
              '14. Contact Information',
              'For questions about these Terms of Service, please contact us:\n\n'
                  'Email: legal@medtrack.com\n'
                  'Phone: +1 (800) 123-4567\n'
                  'Address: 123 Healthcare Ave, Medical District, City, State 12345',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: AppColors.success, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By using MedTrack, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
