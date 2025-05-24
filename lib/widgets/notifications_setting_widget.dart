import 'package:flutter/material.dart';

import '../services/notifications_service.dart';

class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({Key? key}) : super(key: key);

  @override
  _NotificationSettingsWidgetState createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    try {
      final enabled = await _notificationService.areNotificationsEnabled();
      setState(() {
        _notificationsEnabled = enabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value && !_notificationsEnabled) {
      final granted =
          await _notificationService.requestNotificationPermissions();
      setState(() {
        _notificationsEnabled = granted;
      });

      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications enabled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to enable notifications. Please check your device settings.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendTestNotification() async {
    await _notificationService.sendTestNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              SwitchListTile(
                title: const Text('New Order Notifications'),
                subtitle: const Text('Get notified when new orders arrive'),
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                secondary: const Icon(Icons.notifications),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _notificationsEnabled ? _sendTestNotification : null,
                      icon: const Icon(Icons.send),
                      label: const Text('Send Test Notification'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Note: Make sure notifications are enabled in your device settings for the best experience.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
