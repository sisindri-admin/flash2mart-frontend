import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'constants/app_colors.dart';
import 'firebase_options.dart';
import 'screens/merchant_auth_screen.dart';
import 'screens/merchant_dashboard.dart';

// 🚀 బ్యాక్‌గ్రౌండ్ ప్రాసెస్ రన్ అవ్వడానికి టాస్క్ హ్యాండ్లర్
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class FirstTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🚀 బ్యాక్‌గ్రౌండ్ కమ్యూనికేషన్ పోర్ట్ ప్రారంభించడం
  FlutterForegroundTask.initCommunicationPort();

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