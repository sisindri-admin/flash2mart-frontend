import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class OverlayPermissionHandler {
  // 🚀 బ్యాక్‌గ్రౌండ్ లో Firestore నిరంతరం రన్ అవ్వడానికి Foreground Task ని ప్రారంభించే మెథడ్
  static Future<void> startOrderForegroundService() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'flash2mart_merchant_orders',
        channelName: 'Flash2Mart Merchant Service',
        channelDescription: 'Keeps store online for new real-time orders',
        channelImportance: NotificationImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
    );

    await FlutterForegroundTask.startService(
      notificationTitle: 'Flash2Mart Store Active',
      notificationText: 'కొత్త ఆర్డర్ల కోసం యాప్ బ్యాక్‌గ్రౌండ్‌లో రన్ అవుతోంది...',
    );
  }

  // 'Display Over Other Apps' & Battery Optimization permissions అడిగే మెథడ్
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

      // 4. Start Foreground Task
      await startOrderForegroundService();

    } catch (e) {
      debugPrint("Overlay/Battery permission Error: $e");
    }
  }
}