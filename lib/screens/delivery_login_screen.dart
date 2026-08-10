import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'delivery_register_screen.dart';

class DeliveryLoginScreen extends StatefulWidget {
  const DeliveryLoginScreen({super.key});

  @override
  State<DeliveryLoginScreen> createState() => _DeliveryLoginScreenState();
}

class _DeliveryLoginScreenState extends State<DeliveryLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // లాగిన్ API కి డేటా పంపే ఫంక్షన్
  Future<void> _loginPartner() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('దయచేసి అన్ని వివరాలను నింపండి!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('https://flash2mart-backend-production.up.railway.app/api/delivery/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Login Successful!')),
        );
      } else {
        // సర్వర్ నుండి వచ్చే అసలు ఎర్రర్ మెసేజ్ ఇక్కడ చూపిస్తుంది
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Login Failed!')),
        );
      }
    } catch (e) {
      // నెట్‌వర్క్ లేదా కోడింగ్ ఎర్రర్ ఇక్కడ ప్రింట్ అవుతుంది
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('నెట్‌వర్క్ ఎర్రర్: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      appBar: AppBar(
        title: const Text('Delivery Partner Login'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Center(
              child: Image.asset(
                'assets/images/delevery partner role icon.png',
                height: 100,
                errorBuilder: (c, o, s) => Icon(Icons.delivery_dining, size: 100, color: Colors.teal.shade700),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Welcome Back! 👋',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
            ),
            const SizedBox(height: 8),
            const Text('లాగిన్ చేయడానికి మీ వివరాలను ఎంటర్ చేయండి.', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 30),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'ఫోన్ నంబర్ (Phone Number)',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'పాస్‌వర్డ్ (Password)',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _loginPartner,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeliveryRegisterScreen()),
                  );
                },
                child: Text(
                  'ఖాతా లేదా? కొత్త రిజిస్ట్రేషన్ చేసుకోండి',
                  style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}