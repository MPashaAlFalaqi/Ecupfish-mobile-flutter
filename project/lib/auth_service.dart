import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Gunakan 10.0.2.2 jika pakai Emulator Android. Jika pakai HP fisik, ganti dengan IP WiFi laptop Anda (contoh: 192.168.1.x)
  static const String baseUrl = 'http://localhost:3000/api/auth';

  static Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phoneNumber': phone,
          'password': password,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Register Error: $e');
      return false;
    }
  }

  static Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        
        // Simpan token ke penyimpanan HP
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        
        return token;
      }
      return null;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }
}