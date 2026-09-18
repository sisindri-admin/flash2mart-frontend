import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../screens/orders_screen.dart';
import '../services/firestore_service.dart';

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
  String? _selectedRejectReason;
  bool _isSubmitting = false;

  final List<String> _rejectReasons = [
    'Item Out of Stock',
    'Store Closing Soon',
    'Too Many Pending Orders',
    'Price / Quantity Mismatch',
    'Delivery Area Not Serviceable',
    'Other Merchant Issue',
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playRingtone();
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/order_ringtone.mp3'));
    } catch (e) {
      debugPrint("Audio Playback Error: $e");
    }
  }

  Future<void> _stopRingtone() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint("Audio Stop Error: $e");
    }
  }

  @override
  void dispose() {
    _stopRingtone();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Calculate items total price only (Excluding Delivery Charges & Other Fees)
  double _calculateItemsOnlyTotal(List<dynamic> items) {
    double total = 0.0;
    for (var item in items) {
      final price = item['totalPrice'] ?? item['price'] ?? 0;
      if (price is num) {
        total += price.toDouble();
      } else if (price is String) {
        total += double.tryParse(price) ?? 0.0;
      }
    }
    return total;
  }

  void _showRejectReasonDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Select Rejection Reason',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _rejectReasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(reason, style: const TextStyle(fontSize: 13)),
                    value: reason,
                    groupValue: _selectedRejectReason,
                    activeColor: Colors.redAccent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() {
                        _selectedRejectReason = val;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _selectedRejectReason == null || _isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => _isSubmitting = true);
                        await _processRejection(_selectedRejectReason!);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // PROCESS REJECTION VIA FIRESTORE SERVICE
  Future<void> _processRejection(String reason) async {
    await _stopRingtone();
    await FirestoreService.rejectOrder(
      orderId: widget.orderId,
      orderData: widget.orderData,
      reason: reason,
    );
  }

  // PROCESS ACCEPT VIA FIRESTORE SERVICE
  Future<void> _processAccept() async {
    await _stopRingtone();

    await FirestoreService.acceptOrder(
      orderId: widget.orderId,
      orderData: widget.orderData,
    );

    if (mounted) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayOrderId = widget.orderData['orderId'] ?? widget.orderId;
    final customerName = widget.orderData['customerName'] ?? widget.orderData['userName'] ?? 'Customer (#$displayOrderId)';
    final items = (widget.orderData['items'] as List<dynamic>?) ?? [];
    final address = widget.orderData['deliveryAddress'] ?? 'Standard Delivery';

    // PRODUCTS TOTAL PRICE (EXCLUDING DELIVERY CHARGES)
    final double itemsOnlyTotal = widget.orderData['itemsTotal'] != null
        ? (widget.orderData['itemsTotal'] is num
            ? (widget.orderData['itemsTotal'] as num).toDouble()
            : double.tryParse('${widget.orderData['itemsTotal']}') ?? _calculateItemsOnlyTotal(items))
        : _calculateItemsOnlyTotal(items);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 5),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _showRejectReasonDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
                            SizedBox(width: 4),
                            Text('Reject Order', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                    // Displaying Products Total Price Only
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Items Total',
                          style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${itemsOnlyTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NEW ORDER RECEIVED!',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          Text(
                            customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                const Text('Products List:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index] as Map<String, dynamic>;
                      final itemPrice = item['totalPrice'] ?? item['price'] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item['quantity'] ?? 1}x ${item['name'] ?? 'Item'} (${item['unit'] ?? ''})',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '₹$itemPrice',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                ),
              ),
              onPressed: _processAccept,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'ACCEPT ORDER',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}