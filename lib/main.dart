import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'constants/app_colors.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/merchant_auth_screen.dart';
import 'screens/merchant_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const Flash2MartApp());
}

class Flash2MartApp extends StatelessWidget {
  const Flash2MartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flash2Mart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const MerchantAuthScreen(),
        '/dashboard': (context) => MerchantDashboard(),
      },
    );
  }
}