import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Contact Us',
            [
              _buildContactTile(
                context,
                'Email Support',
                'support@medtrack.com',
                Icons.email,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening email client...'),
                    ),
                  );
                },
              ),
              _buildContactTile(
                context,
                'Phone Support',
                '+1 (800) 123-4567',
                Icons.phone,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Calling support...'),
                    ),
                  );
                },
              ),
              _buildContactTile(
                context,
                'Live Chat',
                'Available 24/7',
                Icons.chat,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening live chat...'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Frequently Asked Questions',
            [
              _buildFAQTile(
                context,
                'How do I upload a medical report?',
                'Go to the Reports tab, tap the + button, and select "Upload Report". You can take a photo or choose from gallery.',
              ),
              _buildFAQTile(
                context,
                'How do I share my reports with my doctor?',
                'Open any report and tap the share icon at the top. You can share via email, WhatsApp, or any messaging app.',
              ),
              _buildFAQTile(
                context,
                'Is my medical data secure?',
                'Yes! All your data is encrypted and stored securely. We never share your medical information without your consent.',
              ),
              _buildFAQTile(
                context,
                'How do I change my password?',
                'Go to Profile > Privacy & Security > Change Password to update your account password.',
              ),
              _buildFAQTile(
                context,
                'Can I export all my medical data?',
                'Yes! Go to Profile > Privacy & Security > Download Your Data to export all your medical records.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Resources',
            [
              _buildResourceTile(
                context,
                'User Guide',
                'Learn how to use all features',
                Icons.book,
                () {},
              ),
              _buildResourceTile(
                context,
                'Video Tutorials',
                'Watch step-by-step tutorials',
                Icons.play_circle,
                () {},
              ),
              _buildResourceTile(
                context,
                'Community Forum',
                'Connect with other users',
                Icons.forum,
                () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Feedback',
            [
              _buildActionTile(
                context,
                'Send Feedback',
                'Help us improve Med Track',
                Icons.feedback,
                () {
                  _showFeedbackDialog(context);
                },
              ),
              _buildActionTile(
                context,
                'Report a Bug',
                'Let us know if something is not working',
                Icons.bug_report,
                () {
                  _showFeedbackDialog(context, isBugReport: true);
                },
              ),
              _buildActionTile(
                context,
                'Rate the App',
                'Give us a rating on the app store',
                Icons.star,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening app store...'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildContactTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildFAQTile(BuildContext context, String question, String answer) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResourceTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.secondary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  void _showFeedbackDialog(BuildContext context, {bool isBugReport = false}) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBugReport ? 'Report a Bug' : 'Send Feedback'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: isBugReport
                ? 'Describe the issue you encountered...'
                : 'Tell us what you think...',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isBugReport
                        ? 'Bug report submitted. Thank you!'
                        : 'Feedback submitted. Thank you!',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
