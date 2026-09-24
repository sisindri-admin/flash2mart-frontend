import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide NotificationVisibility; // 👈 Import Collision ఎర్రర్ ఫిక్స్ చేయడానికి hide చేసాను

class OverlayPermissionHandler {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 🚨 ఈ Channel ID మిగతా అన్ని ఫైల్స్‌లో వాడే 'new_orders_v2' తో ఖచ్చితంగా మ్యాచ్ అవ్వాలి!
  static const String channelId = 'new_orders_v3';
  static const String channelName = 'New Order Alerts v3';

  // 🚀 బ్యాక్‌గ్రౌండ్‌లో ఆర్డర్ రాగానే బిగ్ గ్రీన్ అమౌంట్‌తో పైన పాప్-అప్ పంపే మెథడ్
  static Future<void> triggerOrderSoundNotification(String orderId, String customerDetails) async {
    
    // 🚨 Big Text Style with HTML formatting for Green & Large Amount Accent
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      '<br/><font color="#16A34A"><b><span style="font-size:24px;">💵 $customerDetails</span></b></font><br/><br/>'
      '<font color="#64748B"><small>Order ID: #$orderId</small></font><br/>'
      '<b>Tap or wait 5 sec to accept order.</b>',
      htmlFormatBigText: true,
      contentTitle: '<b>🚨 KOTHA ORDER VACHINDI!</b>',
      htmlFormatContentTitle: true,
      summaryText: 'Flash2Mart Instant Alert',
      htmlFormatSummaryText: true,
    );

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'High priority alerts for incoming merchant orders',
      importance: Importance.max,
      priority: Priority.max, // 👈 Max Priority
      styleInformation: bigTextStyleInformation, // 👈 Expandable Big Card Layout
      fullScreenIntent: true, // 👈 ఫోన్ లాక్‌లో/బ్యాక్‌గ్రౌండ్‌లో ఉన్నా పాప్-అప్ రావడానికి
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('order_ringtone'),
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm, // 👈 ఫోన్ సైలెంట్‌లో ఉన్నా రింగ్‌టోన్ ప్లే అవ్వడానికి
      category: AndroidNotificationCategory.alarm,
    );

    NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🚨 KOTHA ORDER VACHINDI!',
      customerDetails,
      platformDetails,
    );
  }

  // 🚀 Notification Channel క్రియేట్ చేసే మెథడ్
  static Future<void> setupNotificationChannel() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'High priority alerts for incoming merchant orders',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('order_ringtone'),
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // 🚀 బ్యాక్‌గ్రౌండ్‌లో నిరంతరం రన్ అవ్వడానికి Foreground Task ప్రారంభించే మెథడ్
  static Future<void> startOrderForegroundService() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    await setupNotificationChannel();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: channelId,
        channelName: 'Flash2Mart Merchant Service',
        channelDescription: 'Keeps store online for new real-time orders',
        channelImportance: NotificationChannelImportance.MAX,
        priority: NotificationPriority.MAX,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true, // 👈 Phone reboot/start లో కూడా auto restart అవ్వడానికి
        allowWifiLock: true,
      ),
    );

    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Flash2Mart Store Active',
      notificationText: 'కొత్త ఆర్డర్ల కోసం యాప్ బ్యాక్‌గ్రౌండ్‌లో రన్ అవుతోంది...',
    );
  }

  // 🚀 'Display Over Other Apps', Battery Optimization, Auto-Start & Notification permissions అడిగే మెథడ్
  static Future<void> checkAndRequestOverlayPermission(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      // 1. Display Over Other Apps Permission Check
      PermissionStatus overlayStatus = await Permission.systemAlertWindow.status;
      if (!overlayStatus.isGranted) {
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

      // 2. Battery Optimization Disable Request (Recent Apps క్లియర్ చేసినా ప్రాసెస్ కిల్‌కాకుండా ఉండటానికి)
      PermissionStatus batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.battery_saver_rounded, color: Color(0xFF16A34A)),
                    SizedBox(width: 10),
                    Text('Disable Battery Saver', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: const Text(
                  'Recent Apps తీసేసినా లేదా ఫోన్ క్లోజ్ అయి ఉన్నా కొత్త ఆర్డర్లు మిస్ అవ్వకుండా ఉండటానికి Battery Saver Exempt పర్మిషన్ అనుమతించండి.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('SKIP', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await Permission.ignoreBatteryOptimizations.request();
                    },
                    child: const Text('ALLOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        }
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