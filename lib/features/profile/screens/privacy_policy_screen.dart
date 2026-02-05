import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Privacy Policy',
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
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Privacy Matters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Effective Date: February 4, 2026',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildIntroduction(),
            const SizedBox(height: 16),
            _buildSection(
              '1. Information We Collect',
              '',
              [
                _buildSubSection(
                  'Personal Information',
                  '• Name, email address, and phone number\n'
                      '• Date of birth and gender\n'
                      '• Profile photo\n'
                      '• Account credentials',
                ),
                _buildSubSection(
                  'Medical Information',
                  '• Medical reports and test results\n'
                      '• Lab reports and diagnostic images\n'
                      '• Health metrics and measurements\n'
                      '• Medication information\n'
                      '• Doctor appointments and visits',
                ),
                _buildSubSection(
                  'Usage Data',
                  '• Device information (model, OS version)\n'
                      '• App usage patterns and preferences\n'
                      '• Log data and error reports\n'
                      '• IP address and location (with permission)',
                ),
              ],
            ),
            _buildSection(
              '2. How We Use Your Information',
              'We use the collected information for the following purposes:',
              [
                _buildBulletPoint('To provide and maintain our services'),
                _buildBulletPoint(
                    'To manage your medical records and health data'),
                _buildBulletPoint(
                    'To send notifications about test results and appointments'),
                _buildBulletPoint(
                    'To improve user experience and app features'),
                _buildBulletPoint('To ensure security and prevent fraud'),
                _buildBulletPoint('To comply with legal obligations'),
                _buildBulletPoint(
                    'To communicate important updates and changes'),
              ],
            ),
            _buildSection(
              '3. Data Security',
              'We implement robust security measures to protect your data:',
              [
                _buildSecurityFeature(
                  Icons.lock,
                  'End-to-End Encryption',
                  'All medical data is encrypted in transit and at rest',
                ),
                _buildSecurityFeature(
                  Icons.cloud_done,
                  'Secure Cloud Storage',
                  'Data stored on HIPAA-compliant cloud infrastructure',
                ),
                _buildSecurityFeature(
                  Icons.verified_user,
                  'Access Controls',
                  'Multi-factor authentication and role-based access',
                ),
                _buildSecurityFeature(
                  Icons.monitor_heart,
                  'Regular Audits',
                  'Continuous security monitoring and vulnerability assessments',
                ),
              ],
            ),
            _buildSection(
              '4. Data Sharing',
              'We do NOT sell your personal or medical information. We may share data only in these circumstances:',
              [
                _buildBulletPoint(
                    'With healthcare providers (only with your explicit consent)'),
                _buildBulletPoint(
                    'With service providers who help us operate the app (under strict confidentiality)'),
                _buildBulletPoint('When required by law or legal process'),
                _buildBulletPoint('To protect our rights and prevent fraud'),
                _buildBulletPoint(
                    'In case of business transfer (you will be notified)'),
              ],
            ),
            _buildSection(
              '5. Your Rights',
              'You have the following rights regarding your data:',
              [
                _buildRightItem(
                  Icons.visibility,
                  'Access',
                  'View all your personal and medical data',
                ),
                _buildRightItem(
                  Icons.edit,
                  'Correction',
                  'Update or correct inaccurate information',
                ),
                _buildRightItem(
                  Icons.download,
                  'Data Portability',
                  'Export your data in a readable format',
                ),
                _buildRightItem(
                  Icons.delete_forever,
                  'Deletion',
                  'Request deletion of your account and data',
                ),
                _buildRightItem(
                  Icons.block,
                  'Restrict Processing',
                  'Limit how we use your data',
                ),
                _buildRightItem(
                  Icons.cancel,
                  'Withdraw Consent',
                  'Opt out of optional data collection',
                ),
              ],
            ),
            _buildSection(
              '6. Data Retention',
              'We retain your information for as long as:',
              [
                _buildBulletPoint('Your account is active'),
                _buildBulletPoint(
                    'Needed to provide you services and fulfill transactions'),
                _buildBulletPoint(
                    'Required by law or for legitimate business purposes'),
                _buildBulletPoint(
                    'After account deletion, anonymized data may be retained for analytics'),
              ],
            ),
            _buildSection(
              '7. Children\'s Privacy',
              'MedTrack is not intended for children under 13 years of age. We do not knowingly collect personal information from children. If you are a parent/guardian and believe your child has provided us with data, please contact us immediately.',
              [],
            ),
            _buildSection(
              '8. Cookies and Tracking',
              'We use cookies and similar technologies to:',
              [
                _buildBulletPoint('Remember your preferences'),
                _buildBulletPoint('Understand how you use the app'),
                _buildBulletPoint('Improve app performance'),
                _buildBulletPoint('Provide personalized experience'),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Cookie Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can manage cookie preferences in your browser or app settings.',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ],
              ),
            ),
            _buildSection(
              '9. International Data Transfers',
              'Your data may be transferred and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your data in compliance with applicable laws.',
              [],
            ),
            _buildSection(
              '10. Changes to Privacy Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by:',
              [
                _buildBulletPoint('Posting the new policy on this page'),
                _buildBulletPoint('Sending an email notification'),
                _buildBulletPoint('Displaying an in-app notification'),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Your continued use of the app after changes indicates acceptance of the updated policy.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _buildContactSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroduction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: const Text(
        'At MedTrack, we take your privacy seriously. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services. Please read this policy carefully to understand our practices regarding your data.',
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, String description, List<Widget> children) {
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
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (children.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _buildSubSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(
              Icons.check_circle,
              size: 18,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeature(
      IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.success, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.contact_support, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'If you have any questions about this Privacy Policy or our data practices, please contact our Data Protection Officer:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(Icons.email, 'privacy@medtrack.com'),
          _buildContactItem(Icons.phone, '+1 (800) 123-4567'),
          _buildContactItem(
              Icons.location_on, '123 Healthcare Ave, Medical District, City'),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
