import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/splash_screen.dart';
import 'screens/merchant_auth_screen.dart';
import 'screens/merchant_dashboard.dart';

void main() {
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
      // మొదట చూపించాల్సిన స్క్రీన్
      home: const SplashScreen(),
      
      // పేజీ నావిగేషన్ Routes
      routes: {
<<<<<<< HEAD
        '/auth': (context) => const MerchantAuthScreen(),
        '/dashboard': (context) => const MerchantDashboard(),
=======
        '/auth': (context) => MerchantAuthScreen(),
        '/dashboard': (context) => MerchantDashboardScreen(),
>>>>>>> 441a9e7 (updated build fix)
      },
    );
  }
}