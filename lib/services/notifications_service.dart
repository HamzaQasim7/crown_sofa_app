import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/order_model.dart';
import '../screens/order_details_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  BuildContext? _context;
  bool _isInitialized = false;

  // Initialize the notification service
  Future<void> initialize(BuildContext context) async {
    _context = context;

    if (_isInitialized) return;

    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
    await _setupOrderListener();

    _isInitialized = true;
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'new_orders_channel',
      'New Orders',
      description: 'Notifications for new customer orders',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Initialize Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Save token to Firestore for sending targeted notifications
    if (token != null) {
      await _saveFCMToken(token);
    }

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('admin_tokens')
          .doc('admin_device')
          .set({
            'fcm_token': token,
            'updated_at': FieldValue.serverTimestamp(),
            'platform': Platform.isAndroid ? 'android' : 'ios',
          });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Set up real-time listener for new orders
  Future<void> _setupOrderListener() async {
    FirebaseFirestore.instance
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final latestOrder = OrderModel.fromFirestore(snapshot.docs.first);

            // Check if this is a new order (within last 30 seconds)
            if (latestOrder.timestamp != null) {
              final now = DateTime.now();
              final orderTime = latestOrder.timestamp!;
              final difference = now.difference(orderTime).inSeconds;

              if (difference <= 30) {
                _showNewOrderNotification(latestOrder);
              }
            }
          }
        });
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');

    if (message.data['type'] == 'new_order') {
      final orderId = message.data['order_id'];
      if (orderId != null) {
        _showLocalNotification(
          title: message.notification?.title ?? 'New Order',
          body: message.notification?.body ?? 'A new order has been received',
          payload: orderId,
        );
      }
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');

    if (message.data['type'] == 'new_order') {
      final orderId = message.data['order_id'];
      if (orderId != null && _context != null) {
        _navigateToOrderDetails(orderId);
      }
    }
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null && _context != null) {
      _navigateToOrderDetails(response.payload!);
    }
  }

  // Navigate to order details screen
  void _navigateToOrderDetails(String orderId) async {
    if (_context == null) return;

    try {
      final orderDoc =
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .get();

      if (orderDoc.exists) {
        // final order = OrderModel.fromFirestore(orderDoc.data()!, orderDoc.id);
        final order = OrderModel.fromFirestore(
          orderDoc,
        ); // Pass the entire DocumentSnapshot

        Navigator.of(_context!).push(
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(orderId: order.id),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to order details: $e');
    }
  }

  // Show local notification for new orders
  void _showNewOrderNotification(OrderModel order) {
    final customerName = order.customerName ?? 'Unknown Customer';
    // final salePrice = order.salePrice.toStringAsFixed(2) ?? '0.00';
    final salePrice = order.formattedPrice; // Using the getter

    _showLocalNotification(
      title: 'New Order Received! 🎉',
      body: 'Order from $customerName - ${salePrice}',
      payload: order.id,
    );
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_orders_channel',
      'New Orders',
      channelDescription: 'Notifications for new customer orders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4361EE),
      playSound: true,
      enableVibration: true,
      vibrationPattern:
          Int64List.fromList([0, 1000, 500, 1000])
              as Int64List?, // Convert to Int64List
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Send test notification
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification to verify the system is working.',
    );
  }

  // Update context for navigation
  void updateContext(BuildContext context) {
    _context = context;
  }

  // Get notification permission status
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else {
      final iosImplementation =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      return await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
  }

  // Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      return await androidImplementation?.requestPermission() ?? false;
    } else {
      final iosImplementation =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      return await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Handle background message processing here
}
