import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _appointmentReminders = true;
  bool _testResultsReady = true;
  bool _medicationReminders = true;
  bool _healthTips = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Notification Types',
            [
              _buildSwitchTile(
                'Appointment Reminders',
                'Get notified about upcoming appointments',
                Icons.calendar_today,
                _appointmentReminders,
                (value) => setState(() => _appointmentReminders = value),
              ),
              _buildSwitchTile(
                'Test Results Ready',
                'Notification when your test results are available',
                Icons.description,
                _testResultsReady,
                (value) => setState(() => _testResultsReady = value),
              ),
              _buildSwitchTile(
                'Medication Reminders',
                'Reminders to take your medications',
                Icons.medication,
                _medicationReminders,
                (value) => setState(() => _medicationReminders = value),
              ),
              _buildSwitchTile(
                'Health Tips',
                'Daily health tips and wellness advice',
                Icons.lightbulb,
                _healthTips,
                (value) => setState(() => _healthTips = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Delivery Channels',
            [
              _buildSwitchTile(
                'Push Notifications',
                'Receive notifications on this device',
                Icons.notifications_active,
                _pushNotifications,
                (value) => setState(() => _pushNotifications = value),
              ),
              _buildSwitchTile(
                'Email Notifications',
                'Receive notifications via email',
                Icons.email,
                _emailNotifications,
                (value) => setState(() => _emailNotifications = value),
              ),
              _buildSwitchTile(
                'SMS Notifications',
                'Receive notifications via SMS',
                Icons.sms,
                _smsNotifications,
                (value) => setState(() => _smsNotifications = value),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification settings saved successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
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
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}
