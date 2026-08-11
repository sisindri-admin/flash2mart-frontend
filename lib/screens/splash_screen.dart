import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 2 సెకన్ల తర్వాత Auth Screen కి వెళ్తుంది
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/auth');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo Icon Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: const Icon(
                Icons.flash_on,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            
            // App Title
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: 'Flash', style: TextStyle(color: Colors.blue)),
                  TextSpan(text: '2', style: TextStyle(color: Colors.red)),
                  TextSpan(text: 'Mart', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Everything you need, delivered faster',
              style: TextStyle(color: AppColors.textGrey, fontSize: 12),
            ),
            const SizedBox(height: 40),
            
            // Loading Indicator
            const CircularProgressIndicator(
              color: AppColors.secondary,
              strokeWidth: 3,
            )
          ],
        ),
      ),
    );
  }
}