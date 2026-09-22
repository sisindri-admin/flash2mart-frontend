import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:auto_start_flutter/auto_start_flutter.dart';

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
                    Text('Display Permission Required', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

      // 2. Battery Optimization Disable Request (డైరెక్ట్ సిస్టమ్ పర్మిషన్ పాప్-అప్)
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

  // Battery Optimization మ్యాన్యువల్ లేకుండా సింపుల్ డయలాగ్
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
            'యాప్ మినిమైజ్ చేసినప్పుడు కూడా ఆర్డర్‌లు మిస్ కాకుండా ఉండటానికి "Unrestricted Battery / Don\'t Optimize" బటన్ నొక్కండి.',
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
                // 🚀 ఒకే ట్యాప్‌తో ఆండ్రాయిడ్ బ్యాటరీ ఆప్టిమైజేషన్ పాప్-అప్ ఓపెన్ అవుతుంది
                await Permission.ignoreBatteryOptimizations.request();
              },
              child: const Text('ALLOW NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Auto-Start Settings కి ఒకే క్లిక్‌తో వెళ్ళే హెల్పర్ ఫంక్షన్ (Xiaomi, Vivo, Oppo మొదలైన వాటికి)
  static Future<void> openAutoStartSettings(BuildContext context) async {
    try {
      bool isAvailable = await isAutoStartAvailable ?? false;
      if (isAvailable) {
        await getAutoStartPermission();
      } else {
        // Auto-start లేని ఫోన్‌లకు డైరెక్ట్‌గా ఆప్టిమైజేషన్ పేజీకి తీసుకెళ్తుంది
        await openAppSettings();
      }
    } catch (e) {
      await openAppSettings();
    }
  }
}