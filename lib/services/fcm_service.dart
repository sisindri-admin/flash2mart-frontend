import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 🚀 బ్యాక్‌గ్రౌండ్ మెసేజ్ హ్యాండ్లర్ (Top level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background FCM message: ${message.messageId}");
}

class FCMService {
  static final FCMService instance = FCMService._internal();
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? navigatorKey;

  // 🚀 Notification Channel Setup
  static const AndroidNotificationChannel _orderChannel =
      AndroidNotificationChannel(
    'new_orders',
    'New Order Alerts',
    description: 'High priority alerts for incoming merchant orders',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('order_ringtone'),
  );

  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    // 1. Notification Permissions అడగడం
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM Notification permission granted');
    }

    // 2. Android Notification Channel క్రియేట్ చేయడం
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_orderChannel);

    // 3. Local Notifications Initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          _navigateToDashboard();
        }
      },
    );

    // 4. Background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Foreground Notification Handling (యాప్ ఓపెన్ లో ఉన్నప్పుడు)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground Message: ${message.notification?.title}');
      _showForegroundLocalNotification(message);
    });

    // 6. Notification Tap Handling (App in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification clicked from background!');
      _navigateToDashboard();
    });

    // 7. Notification Tap Handling (App completely closed / terminated)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _navigateToDashboard();
      });
    }

    // 8. Save FCM Token to Firestore
    await saveTokenToFirestore();

    // 9. Listen for Token Refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _updateTokenInFirestore(newToken);
    });
  }

  // 🚀 FCM Token ని Firestore 'merchants' కలెక్షన్‌లో సేవ్ చేయడం
  Future<void> saveTokenToFirestore() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint("Error fetching FCM token: $e");
    }
  }

  Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('merchants')
        .doc(user.uid)
        .set({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint("FCM Token successfully stored in Firestore: $token");
  }

  // 🚀 Foreground Local Notification డిస్‌ప్లే చేయడం
  void _showForegroundLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title ?? "🚨 NEW ORDER!",
        notification.body ?? "You have received a new order.",
        NotificationDetails(
          android: AndroidNotificationDetails(
            _orderChannel.id,
            _orderChannel.name,
            channelDescription: _orderChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('order_ringtone'),
          ),
        ),
        payload: message.data['orderId'] ?? '',
      );
    }
  }

  void _navigateToDashboard() {
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushNamed('/dashboard');
    }
  }
}