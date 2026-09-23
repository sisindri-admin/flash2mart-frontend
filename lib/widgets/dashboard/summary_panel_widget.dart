import 'package:flutter/material.dart';

class SummaryPanelWidget extends StatelessWidget {
  final int totalProducts;
  final int pendingOrders;
  final int totalOrders;
  final double totalRevenue;

  const SummaryPanelWidget({
    super.key,
    required this.totalProducts,
    required this.pendingOrders,
    required this.totalOrders,
    required this.totalRevenue,
  });

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryPurple = Color(0xFF4F46E5);
  static const Color textDark = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Store Performance Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Live', style: TextStyle(fontSize: 9.5, color: primaryPurple, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBottomStatItem('Total Items', '$totalProducts', Icons.inventory_2_outlined, primaryBlue),
              _buildBottomStatItem('Active Orders', '$pendingOrders', Icons.pending_actions_rounded, Colors.deepOrange),
              _buildBottomStatItem('Total Orders', '$totalOrders', Icons.shopping_bag_outlined, Colors.indigo),
              _buildBottomStatItem('Revenue', '₹${totalRevenue.toStringAsFixed(0)}', Icons.currency_rupee_rounded, Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: textDark),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}