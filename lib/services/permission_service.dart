import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class OverlayPermissionHandler {
  // 🚀 Swiggy లాగా ఆటోమేటిక్‌గా Notification Channel క్రియేట్ చేసి Allow చేసే మెథడ్
  static Future<void> setupNotificationChannel() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'flash2mart_merchant_orders', // Channel ID
      'New Order Alerts', // Channel Name (సెట్టింగ్స్‌లో కనిపించే పేరు)
      description: 'Notifications for new incoming store orders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // 🚀 బ్యాక్‌గ్రౌండ్‌లో Firestore నిరంతరం రన్ అవ్వడానికి Foreground Task ప్రారంభించే మెథడ్
  static Future<void> startOrderForegroundService() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    // ఫస్ట్ ఛానెల్ సృష్టించడం
    await setupNotificationChannel();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'flash2mart_merchant_orders',
        channelName: 'Flash2Mart Merchant Service',
        channelDescription: 'Keeps store online for new real-time orders',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
    );

    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Flash2Mart Store Active',
      notificationText: 'కొత్త ఆర్డర్ల కోసం యాప్ బ్యాక్‌గ్రౌండ్‌లో రన్ అవుతోంది...',
    );
  }

  // 'Display Over Other Apps', Battery Optimization & Notification permissions అడిగే మెథడ్
  static Future<void> checkAndRequestOverlayPermission(BuildContext context) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      // 1. Display Over Other Apps Permission Check
      PermissionStatus status = await Permission.systemAlertWindow.status;
      if (!status.isGranted) {
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.layers_rounded, color: Color(0xFF2563EB)),
                    SizedBox(width: 10),
                    Text('Permission Required', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: const Text(
                  'మీరు వేరే యాప్స్ ఉపయోగిస్తున్నప్పుడు కొత్త ఆర్డర్లు రాగానే తక్షణమే పాప్-అప్ రావడానికి "Display Over Other Apps" పర్మిషన్ అనుమతించండి.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('LATER', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await Permission.systemAlertWindow.request();
                    },
                    child: const Text('ENABLE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        }
      }

      // 2. Battery Optimization Disable Request
      PermissionStatus batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }

      // 3. Notification Permission Check
      PermissionStatus notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        await Permission.notification.request();
      }

      // 4. Start Foreground Task & Notification Channel Setup
      await startOrderForegroundService();

    } catch (e) {
      debugPrint("Overlay/Battery permission Error: $e");
    }
  }
}