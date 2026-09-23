import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_orderChannel);

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

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 🚀 Foreground లో నాటిఫికేషన్ రాగానే 2 సెకన్లలో Auto Open చేయడం
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundLocalNotification(message);
      
      // 🚀 Delay లేకుండా 2 సెకన్లలో ఆటోమేటిక్‌గా డ్యాష్‌బోర్డ్ స్క్రీన్‌కి తీసుకెళ్లడం
      Future.delayed(const Duration(seconds: 2), () {
        _navigateToDashboard();
      });
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateToDashboard();
    });

    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToDashboard();
      });
    }

    await saveTokenToFirestore();
  }

  Future<void> saveTokenToFirestore() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('merchants')
              .doc(user.uid)
              .set({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint("Error saving token: $e");
    }
  }

  // 🚀 Big Style Notification with Order Amount
  void _showForegroundLocalNotification(RemoteMessage message) {
    final String orderId = message.data['orderId'] ?? 'New';
    final String amount = message.data['totalAmount'] ?? message.data['grandTotal'] ?? '0';

    // 🚨 అమౌంట్ పెద్దగా, విజిబుల్‌గా ఉండేలా BigTextStyleStyleInformation వాడాను
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      '💰 AMOUNT: ₹$amount\n\nTap or wait 5 sec to accept order.',
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
      '💰 AMOUNT: ₹$amount',
      platformChannelSpecifics,
    );
  }

  void _navigateToDashboard() {
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushNamed('/dashboard');
    }
  }
}