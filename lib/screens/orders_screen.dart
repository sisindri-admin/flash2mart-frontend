import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _showHistoryOnly = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final merchantId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _showHistoryOnly ? 'Order History' : 'Active Orders Process',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: _showHistoryOnly ? 'Show Active Orders' : 'View History',
            icon: Icon(
              _showHistoryOnly ? Icons.list_alt_rounded : Icons.history_rounded,
              color: const Color(0xFF2563EB),
              size: 26,
            ),
            onPressed: () {
              setState(() {
                _showHistoryOnly = !_showHistoryOnly;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('merchantId', isEqualTo: merchantId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];
          
          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['orderStatus'] ?? data['status'] ?? '').toString().toLowerCase();

            if (_showHistoryOnly) {
              return status == 'completed' || status == 'delivered' || status == 'cancelled';
            } else {
              return status == 'pending' || status == 'placed' || status == 'preparing' || status == 'accepted' || status == 'packing_ready' || status == 'ready_for_pickup' || status == 'on_the_way';
            }
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showHistoryOnly ? Icons.history_toggle_off_rounded : Icons.move_to_inbox_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _showHistoryOnly ? 'No Order History Found' : 'No Active Orders in Process',
                    style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final orderId = data['orderId'] ?? doc.id;
              final customerName = data['customerName'] ?? data['userName'] ?? 'Customer';
              
              // Merchant కి ఉత్పత్తుల ధర మొత్తం మాత్రమే కనిపిస్తుంది
              final itemsTotal = data['itemsTotal'] ?? data['itemTotal'] ?? _calculateItemsTotal(data['items']);
              
              final rawStatus = (data['orderStatus'] ?? data['status'] ?? 'Pending').toString();
              final items = (data['items'] as List<dynamic>?) ?? [];

              final bool isPackingReady = rawStatus.toLowerCase() == 'packing_ready' || rawStatus.toLowerCase() == 'ready_for_pickup';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  // Packing Ready అయినప్పుడు కార్డ్ గ్రీన్ రంగులోకి మారుతుంది
                  color: isPackingReady ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPackingReady ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
                    width: isPackingReady ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isPackingReady ? Colors.green.withOpacity(0.1) : Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            'Products Total: ₹$itemsTotal',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: isPackingReady ? const Color(0xFF15803D) : const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Customer: $customerName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const Divider(height: 16),

                      // Items list
                      const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item['quantity']}x ${item['name']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              Text('₹${item['totalPrice'] ?? item['price']}', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),

                      // Status & Packing Button Section
                      if (!isPackingReady && !_showHistoryOnly)
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.inventory_2_outlined, size: 18),
                            label: const Text('PACKING READY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () async {
                              // FirestoreService ద్వారా trackingHistory అరే తో పాటు Firestore నిమిషాల్లో update అవుతుంది
                              await FirestoreService.markOrderPackingReady(doc.id);
                            },
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            color: _getStatusBgColor(rawStatus),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _getStatusIcon(rawStatus),
                              const SizedBox(width: 6),
                              Text(
                                'Status: ${rawStatus.replaceAll('_', ' ').toUpperCase()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _getStatusTextColor(rawStatus),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  double _calculateItemsTotal(dynamic items) {
    double total = 0.0;
    if (items is List) {
      for (var item in items) {
        final price = item['totalPrice'] ?? item['price'] ?? 0;
        if (price is num) total += price.toDouble();
      }
    }
    return total;
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'packing_ready':
      case 'ready_for_pickup':
        return const Color(0xFFDCFCE7);
      case 'preparing':
      case 'accepted':
        return const Color(0xFFFEF3C7);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'packing_ready':
      case 'ready_for_pickup':
        return const Color(0xFF15803D);
      case 'preparing':
      case 'accepted':
        return const Color(0xFFD97706);
      case 'cancelled':
        return Colors.redAccent;
      default:
        return const Color(0xFF2563EB);
    }
  }

  Widget _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'packing_ready':
      case 'ready_for_pickup':
        return const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF15803D));
      case 'preparing':
      case 'accepted':
        return const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)));
      case 'cancelled':
        return const Icon(Icons.cancel, size: 16, color: Colors.redAccent);
      default:
        return const Icon(Icons.info, size: 16, color: Color(0xFF2563EB));
    }
  }
}