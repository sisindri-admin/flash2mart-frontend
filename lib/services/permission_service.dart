import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class OverlayPermissionHandler {
  // 'Display Over Other Apps' పర్మిషన్ తనిఖీ చేసి అడిగే మెథడ్
  static Future<void> checkAndRequestOverlayPermission(BuildContext context) async {
    // 1. Web బ్రౌజర్‌లో రన్ అవుతుంటే ఈ పర్మిషన్ చెక్ చేయకుండా ఆపేస్తుంది (Fixes UnimplementedError)
    if (kIsWeb) return;

    // 2. ఆండ్రాయిడ్ కాకుండా వేరే OS లో రన్ అవుతుంటే కూడా స్కిప్ చేస్తుంది
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      PermissionStatus status = await Permission.systemAlertWindow.status;

      if (!status.isGranted) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.layers_rounded, color: Color(0xFF2563EB)),
                    SizedBox(width: 10),
                    Text('Permission Required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: const Text(
                  'మీరు వేరే యాప్స్ ఉపయోగిస్తున్నప్పుడు కొత్త ఆర్డర్లు రాగానే తక్షణమే నోటిఫికేషన్ పాప్-అప్ రావడానికి "Display Over Other Apps" పర్మిషన్ అనుమతించండి.',
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
                    child: const Text('ALLOW PERMISSION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      debugPrint("Overlay permission Error: $e");
    }
  }
}