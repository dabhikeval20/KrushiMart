import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../screens/api_product_details_screen.dart';
import 'api_service.dart';

class NotificationService {
  NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'krushimart_notifications',
    'KrushiMart Notifications',
    description: 'Notifications for KrushiMart users',
    importance: Importance.high,
  );

  /// Initializes local notifications, FCM permissions, and message handlers.
  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Etc/UTC'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationPayload(response.payload);
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    if (!kIsWeb) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      _showMessageInForeground(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessageNavigation(message);
    });
  }

  /// Show a local notification immediately.
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Schedule a daily reminder at 9 AM local time.
  static Future<void> scheduleDailyReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
      0,
    ).add(const Duration(days: 1));

    await _localNotifications.zonedSchedule(
      100,
      'KrushiMart Reminder',
      'Check new products and offers today.',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  static Future<void> _showMessageInForeground(RemoteMessage message) async {
    final title = message.notification?.title ?? 'New KrushiMart update';
    final body = message.notification?.body ?? 'Tap to see the latest product.';
    final payload = message.data['productId'];
    await showLocalNotification(title: title, body: body, payload: payload);
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    final payload = message.data['productId'];
    if (payload != null && payload.isNotEmpty) {
      _handleNotificationPayload(payload);
    }
  }

  static void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }

    final productId = int.tryParse(payload);
    if (productId == null) {
      return;
    }

    _navigateToProductDetail(productId);
  }

  static Future<void> _navigateToProductDetail(int productId) async {
    final apiService = ApiService();
    try {
      final product = await apiService.fetchProductById(productId);
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      navigator.push(
        MaterialPageRoute(
          builder: (context) => ApiProductDetailsScreen(product: product),
        ),
      );
    } catch (e) {
      debugPrint('Notification navigation failed: $e');
    }
  }
}
