import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appointmentReminders = prefs.getBool('appointment_reminders') ?? true;
      _testResultsReady = prefs.getBool('test_results_ready') ?? true;
      _medicationReminders = prefs.getBool('medication_reminders') ?? true;
      _healthTips = prefs.getBool('health_tips') ?? false;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _smsNotifications = prefs.getBool('sms_notifications') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('appointment_reminders', _appointmentReminders);
      await prefs.setBool('test_results_ready', _testResultsReady);
      await prefs.setBool('medication_reminders', _medicationReminders);
      await prefs.setBool('health_tips', _healthTips);
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setBool('push_notifications', _pushNotifications);
      await prefs.setBool('sms_notifications', _smsNotifications);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved successfully'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
              onPressed: _isSaving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Settings'),
            ),
          ),
          const SizedBox(height: 16),
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
