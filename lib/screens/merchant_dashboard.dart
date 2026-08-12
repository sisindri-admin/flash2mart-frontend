import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Welcome to Flash2Mart Partner Dashboard!',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}