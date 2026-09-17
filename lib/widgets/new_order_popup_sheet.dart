import 'package:audioplayers/audioplayers.dart'; // Audio Player Package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NewOrderPopupSheet extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final String orderId;

  const NewOrderPopupSheet({
    super.key,
    required this.orderData,
    required this.orderId,
  });

  @override
  State<NewOrderPopupSheet> createState() => _NewOrderPopupSheetState();
}

class _NewOrderPopupSheetState extends State<NewOrderPopupSheet> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playRingtone(); // Popup స్క్రీన్ పై రాగానే sound ప్లే అవుతుంది
  }

  // Ringtone Play Function (Repeats continuously like Swiggy)
  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // లూప్‌లో ప్లే అవుతుంది
      await _audioPlayer.setVolume(1.0); // Full Volume
      
      // STEP 1 FIX: 'sounds/' కి బదులుగా 'assets/sounds/' పూర్తి పాత్ ఇవ్వబడింది
      await _audioPlayer.play(AssetSource('assets/sounds/order_ringtone.mp3'));
    } catch (e) {
      debugPrint("Audio Playback Error: $e");
    }
  }

  // Ringtone Stop Function
  Future<void> _stopRingtone() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint("Audio Stop Error: $e");
    }
  }

  @override
  void dispose() {
    _stopRingtone(); // Popup క్లోజ్ కాగానే sound ఆగిపోతుంది
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayOrderId = widget.orderData['orderId'] ?? widget.orderId;
    final customerName = widget.orderData['customerName'] ?? widget.orderData['userName'] ?? 'Customer (#$displayOrderId)';
    final items = (widget.orderData['items'] as List<dynamic>?) ?? [];
    final totalAmount = widget.orderData['grandTotal'] ?? widget.orderData['totalAmount'] ?? widget.orderData['itemTotal'] ?? 0;
    final address = widget.orderData['deliveryAddress'] ?? 'Standard Delivery';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator Bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // Header Badge & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active, color: Colors.orange, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NEW ORDER RECEIVED!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹$totalAmount',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Items List
          const Text(
            'Order Items:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item['quantity'] ?? 1}x ${item['name'] ?? 'Product'} (${item['unit'] ?? ''})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '₹${item['totalPrice'] ?? item['price'] ?? 0}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Address Row
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Accept / Reject Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await _stopRingtone(); // Sound off
                    await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
                      'orderStatus': 'Cancelled',
                      'status': 'Cancelled',
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await _stopRingtone(); // Sound off
                    await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
                      'orderStatus': 'Accepted',
                      'status': 'Accepted',
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Accept Order', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}