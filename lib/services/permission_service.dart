import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class OverlayPermissionHandler {
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
                    Text('Display Permission', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: const Text(
                  'వేరే యాప్స్ ఉపయోగిస్తున్నప్పుడు కొత్త ఆర్డర్లు రాగానే తక్షణమే పాప్-అప్ రావడానికి "Display Over Other Apps" పర్మిషన్ అనుమతించండి.',
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
        if (context.mounted) {
          _showBatteryOptimizationDialog(context);
        }
      }

    } catch (e) {
      debugPrint("Overlay/Battery permission Error: $e");
    }
  }

  // Battery Optimization Dialog (Single Click System Request)
  static void _showBatteryOptimizationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.battery_saver_rounded, color: Colors.amber),
              SizedBox(width: 10),
              Text('Unrestricted Orders', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'యాప్ మినిమైజ్ చేసినప్పుడు కూడా ఆర్డర్‌లు మిస్ కాకుండా ఉండటానికి "Don\'t Optimize / Allow" బటన్ నొక్కండి.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('SKIP', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await Permission.ignoreBatteryOptimizations.request();
              },
              child: const Text('ALLOW NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Auto-Start / App Settings కి సులభంగా వెళ్లే ఫంక్షన్
  static Future<void> openAutoStartSettings(BuildContext context) async {
    await openAppSettings();
  }
}