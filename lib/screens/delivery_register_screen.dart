import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DeliveryRegisterScreen extends StatefulWidget {
  const DeliveryRegisterScreen({super.key});

  @override
  State<DeliveryRegisterScreen> createState() => _DeliveryRegisterScreenState();
}

class _DeliveryRegisterScreenState extends State<DeliveryRegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // డేటాబేస్‌కు డేటా పంపే ఫంక్షన్
  Future<void> _registerPartner() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final vehicle = _vehicleController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || vehicle.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('దయచేసి అన్ని వివరాలను నింపండి!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // మీ బ్యాెకెండ్ URL (Android Emulator అయితే http://10.0.2.2:3000/api/delivery/register వాడాలి)
      // Real Device అయితే మీ కంప్యూటర్ IP Address ఇవ్వాలి (ഉदा: http://192.168.x.x:3000/...)
      final url = Uri.parse('http://192.168.29.222:3000/api/delivery/register');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'vehicleNumber': vehicle,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Registration Successful!')),
        );
        Navigator.pop(context); // రిజిస్ట్రేషన్ అయ్యాక లాగిన్ స్క్రీన్‌కి వెళ్ళడానికి
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Registration Failed!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('నెట్‌వర్క్ ఎర్రర్: సర్వర్‌తో కనెక్షన్ కాలేదు')),
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
        title: const Text('Delivery Partner Register'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'assets/images/delevery partner role icon.png',
                height: 90,
                errorBuilder: (c, o, s) => Icon(Icons.delivery_dining, size: 90, color: Colors.teal.shade700),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Join as Delivery Partner 🚀',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
            ),
            const SizedBox(height: 8),
            const Text('కొత్త ఖాతాను సృష్టించి డెలివరీలు ప్రారంభించండి.', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 25),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'పూర్తి పేరు (Full Name)',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
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
              controller: _vehicleController,
              decoration: InputDecoration(
                labelText: 'వాహన నంబర్ (Vehicle / Bike Number)',
                prefixIcon: const Icon(Icons.directions_bike),
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
                onPressed: _isLoading ? null : _registerPartner,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  '이미 ఖాతా ఉందా? లాగిన్ అవ్వండి',
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