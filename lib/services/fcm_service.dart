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
        _navigateToDashboard();
      },
    );

    // 4. Background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Foreground Notification Handling (యాప్ ఓపెన్ లో ఉన్నప్పుడు)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground Message: ${message.notification?.title}');
      _showForegroundLocalNotification(message);

      // 🚀 2 నుండి 5 సెకన్లలో ఆటోమేటిక్‌గా డ్యాష్‌బోర్డ్ స్క్రీన్‌కి తీసుకెళ్లడం
      Future.delayed(const Duration(seconds: 2), () {
        _navigateToDashboard();
      });
    });

    // 6. Notification Tap Handling (App in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification clicked from background!');
      _navigateToDashboard();
    });

    // 7. Notification Tap Handling (App completely closed / terminated)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
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

  // 🚀 Big Text Style & Green Bold Amount తో Foreground Notification డిస్‌ప్లే చేయడం
  void _showForegroundLocalNotification(RemoteMessage message) {
    final String amount = message.data['totalAmount'] ??
        message.data['grandTotal'] ??
        message.data['amount'] ??
        '0';
    final String customerName = message.data['customerName'] ??
        message.data['userName'] ??
        'Customer';

    // 🚨 అమౌంట్ పెద్దగా, విజిబుల్‌గా ఉండేలా BigTextStyleStyleInformation వాడాను
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      '💰 AMOUNT: ₹$amount\nCustomer: $customerName\n\nTap or wait 5 sec to accept order.',
      htmlFormatBigText: true,
      contentTitle: '🚨 NEW ORDER RECEIVED!',
      htmlFormatContentTitle: true,
      summaryText: 'Flash2Mart Instant Order',
      htmlFormatSummaryText: true,
    );

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _orderChannel.id,
      _orderChannel.name,
      channelDescription: _orderChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigTextStyleInformation, // 👈 Big Text Layout
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('order_ringtone'),
      fullScreenIntent: true,
    );

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🚨 NEW ORDER RECEIVED!',
      '💰 AMOUNT: ₹$amount ($customerName)',
      platformChannelSpecifics,
      payload: message.data['orderId'] ?? '',
    );
  }

  void _navigateToDashboard() {
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushNamed('/dashboard');
    }
  }
}