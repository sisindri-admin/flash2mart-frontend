import 'package:flutter/material.dart';
import 'role_selection_screen.dart'; // మనం త్వరలో క్రియేట్ చేద్దాం

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 3 సెకన్ల తర్వాత ఆటోమేటిక్‌గా లాగిన్ స్క్రీన్‌కి వెళ్తుంది
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // లోగో ఐకాన్ లేదా ఇమేజ్
            const Icon(
              Icons.flash_on,
              size: 100,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              'Flash2Mart',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Quick Commerce & Delivery',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.orangeAccent,
            ),
          ],
        ),
      ),
    );
  }
}