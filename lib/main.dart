import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

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
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}