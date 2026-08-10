import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flash2Mart - Login'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: const Center(
        child: Text(
          'Select Role Login Screen (Coming Soon)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}