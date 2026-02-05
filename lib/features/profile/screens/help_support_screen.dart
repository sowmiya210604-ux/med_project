import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});
<<<<<<< HEAD
=======

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@medtrack.com',
      query: 'subject=Support Request&body=Describe your issue here...',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email client'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+18001234567');

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open phone dialer'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
>>>>>>> 77aadebe87dfc6bcddee5ff551e232c69dedd002

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
                () => _launchEmail(context),
              ),
              _buildContactTile(
                context,
                'Phone Support',
                '+1 (800) 123-4567',
                Icons.phone,
                () => _launchPhone(context),
              ),
              _buildContactTile(
                context,
                'Live Chat',
                'Available 24/7',
                Icons.chat,
                () {
                  _showLiveChatDialog(context);
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
                () => _showUserGuide(context),
              ),
              _buildResourceTile(
                context,
                'Video Tutorials',
                'Watch step-by-step tutorials',
                Icons.play_circle,
                () => _showVideoTutorials(context),
              ),
              _buildResourceTile(
                context,
                'Community Forum',
                'Connect with other users',
                Icons.forum,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening community forum...'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
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

  void _showLiveChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.chat_bubble, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Live Chat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Our support team is available 24/7 to help you.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Text(
                    'Average Response Time',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '< 2 minutes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Starting live chat...'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.message),
            label: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  void _showUserGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.book, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'User Guide',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildGuideSection(
                    'Getting Started',
                    Icons.start,
                    [
                      'Create your account with email and password',
                      'Complete your profile with medical information',
                      'Set up notification preferences',
                    ],
                  ),
                  _buildGuideSection(
                    'Uploading Reports',
                    Icons.upload_file,
                    [
                      'Tap the + button on the Reports screen',
                      'Choose to take a photo or select from gallery',
                      'Wait for OCR processing to extract data',
                      'View your test results and trends',
                    ],
                  ),
                  _buildGuideSection(
                    'Viewing Health Data',
                    Icons.timeline,
                    [
                      'Navigate to Reports to see all your tests',
                      'Tap any report to view detailed graphs',
                      'Use filters to find specific test types',
                      'Share reports with your doctor',
                    ],
                  ),
                  _buildGuideSection(
                    'Managing Appointments',
                    Icons.calendar_today,
                    [
                      'Go to Appointments tab',
                      'Add new appointments with details',
                      'Set reminders so you don\'t miss them',
                      'View upcoming and past appointments',
                    ],
                  ),
                  _buildGuideSection(
                    'Security & Privacy',
                    Icons.security,
                    [
                      'All data is encrypted end-to-end',
                      'Enable biometric authentication',
                      'Control who can access your reports',
                      'Download or delete your data anytime',
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection(String title, IconData icon, List<String> steps) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void _showVideoTutorials(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Video Tutorials',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildVideoTutorialTile(
              context,
              'How to Upload Your First Report',
              '2:30',
              Icons.upload,
            ),
            _buildVideoTutorialTile(
              context,
              'Understanding Your Test Results',
              '4:15',
              Icons.analytics,
            ),
            _buildVideoTutorialTile(
              context,
              'Setting Up Appointment Reminders',
              '3:00',
              Icons.alarm,
            ),
            _buildVideoTutorialTile(
              context,
              'Sharing Reports with Your Doctor',
              '1:45',
              Icons.share,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTutorialTile(
    BuildContext context,
    String title,
    String duration,
    IconData icon,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.secondary),
      ),
      title: Text(title),
      subtitle: Text(duration),
      trailing: const Icon(Icons.play_circle_filled,
          color: AppColors.primary, size: 32),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing: $title'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }
}
