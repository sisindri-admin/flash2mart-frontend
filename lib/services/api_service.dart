import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // మీ Railway backend Domain URL ని ఇక్కడ ఎంటర్ చేయండి
  static const String baseUrl = 'https://flash2mart-backend-production-6203.up.railway.app/api/merchant';

  // Merchant Login API Call
  static Future<Map<String, dynamic>> merchantLogin(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Merchant Register API Call
  static Future<Map<String, dynamic>> merchantRegister({
    required String storeName,
    required String ownerName,
    required String phone,
    required String category,
    required String location,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'storeName': storeName,
          'ownerName': ownerName,
          'phone': phone,
          'category': category,
          'location': location,
          'password': password,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}