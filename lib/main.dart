import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      // 🚀 StreamBuilder ద్వారా ఆటో-లాగిన్ (Persistent Auth Check)
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Firebase ఆథెంటికేషన్ చెక్ చేసేంతవరకు లోడింగ్ స్క్రీన్
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          // యూజర్ ఆల్రెడీ లాగిన్ అయి ఉంటే డైరెక్ట్‌గా MerchantDashboard కి వెళ్తుంది
          if (snapshot.hasData && snapshot.data != null) {
            return const MerchantDashboard();
          }

          // యూజర్ లాగిన్ అవ్వకపోతే మాత్రమే లాగిన్/సాఫ్ట్‌వేర్ ఆత్ స్క్రీన్‌కి పంపుతుంది
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