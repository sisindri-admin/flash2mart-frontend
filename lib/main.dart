import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'constants/app_colors.dart';
import 'firebase_options.dart';
import 'screens/merchant_auth_screen.dart';
import 'screens/merchant_dashboard.dart';
import 'services/fcm_service.dart'; // 🚀 Import FCM Service

// Navigator Key for global routing on notification tap
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const Flash2MartApp());
}

class Flash2MartApp extends StatefulWidget {
  const Flash2MartApp({super.key});

  @override
  State<Flash2MartApp> createState() => _Flash2MartAppState();
}

class _Flash2MartAppState extends State<Flash2MartApp> {
  @override
  void initState() {
    super.initState();
    // 🚀 FCM Service ప్రారంభించడం
    FCMService.instance.initialize(navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flash2Mart',
      navigatorKey: navigatorKey, // Set global navigator key
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return const MerchantDashboard();
          }

          return const MerchantAuthScreen();
        },
      ),
      routes: {
        '/auth': (context) => const MerchantAuthScreen(),
        '/dashboard': (context) => const MerchantDashboard(),
      },
    );
  }
}