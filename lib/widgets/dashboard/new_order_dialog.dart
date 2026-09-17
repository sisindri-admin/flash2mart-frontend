import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class NewOrderDialog extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  final Function(String, String) onUpdateStatus;

  const NewOrderDialog({
    super.key,
    required this.orderId,
    required this.orderData,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final double amount = (orderData['totalAmount'] ?? orderData['price'] ?? 0.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: TextButton.icon(
              onPressed: () {
                FlutterRingtonePlayer.stop();
                Navigator.pop(context);
                onUpdateStatus(orderId, 'rejected');
              },
              icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
              label: const Text("Reject", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(backgroundColor: const Color(0xFFFEE2E2)),
            ),
          ),
          const SizedBox(height: 12),
          Text("New Order Received!", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("₹${amount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              onPressed: () {
                FlutterRingtonePlayer.stop();
                Navigator.pop(context);
                onUpdateStatus(orderId, 'accepted');
              },
              child: const Text("ACCEPT ORDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}