import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications data
    final notifications = _getMockNotifications();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(context, notification);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any notifications yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    final bool isRead = notification['isRead'] as bool;
    final String type = notification['type'] as String;

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'reminder':
        icon = Icons.alarm;
        iconColor = AppColors.warning;
        break;
      case 'report':
        icon = Icons.description;
        iconColor = AppColors.primary;
        break;
      case 'appointment':
        icon = Icons.calendar_today;
        iconColor = AppColors.info;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? const Color(0xFFE5E7EB)
              : AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          notification['title'] as String,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification['message'] as String),
            const SizedBox(height: 8),
            Text(
              notification['time'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          // Handle notification tap
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening: ${notification['title']}'),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getMockNotifications() {
    return [
      {
        'title': 'Annual Checkup Reminder',
        'message': 'Your annual health checkup is due next week',
        'time': _formatTime(DateTime.now().subtract(const Duration(hours: 2))),
        'type': 'reminder',
        'isRead': false,
      },
      {
        'title': 'Blood Test Results Ready',
        'message': 'Your Complete Blood Count results are now available',
        'time': _formatTime(DateTime.now().subtract(const Duration(hours: 5))),
        'type': 'report',
        'isRead': false,
      },
      {
        'title': 'Upcoming Appointment',
        'message': 'Dr. Sarah Johnson - Tomorrow at 10:00 AM',
        'time': _formatTime(DateTime.now().subtract(const Duration(days: 1))),
        'type': 'appointment',
        'isRead': true,
      },
      {
        'title': 'Medication Reminder',
        'message': 'Time to take your daily vitamins',
        'time': _formatTime(DateTime.now().subtract(const Duration(days: 1))),
        'type': 'reminder',
        'isRead': true,
      },
      {
        'title': 'Lipid Profile Available',
        'message': 'Your Lipid Profile test results have been uploaded',
        'time': _formatTime(DateTime.now().subtract(const Duration(days: 2))),
        'type': 'report',
        'isRead': true,
      },
    ];
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }
}
