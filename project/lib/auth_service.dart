import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api/api_client.dart';
import 'api/config.dart' as app_config;

class RegisterResult {
  final bool success;
  final String? message;
  RegisterResult(this.success, [this.message]);
}

class LoginResult {
  final bool success;
  final String? token;
  final String? message;
  LoginResult({required this.success, this.token, this.message});
}

class AuthService {
  static String get baseUrl => '${app_config.baseUrl}/api/auth';

  static Future<RegisterResult> register({
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
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'phoneNumber': phone.trim(),
          'password': password,
          'role': 'BUYER', // Mobile strictly registers BUYER accounts
        }),
      );

      if (response.statusCode == 201) {
        // Simpan juga ke local_registered_users untuk sinkronisasi offline jika dibutuhkan
        await _saveLocalUser(name, email, phone, password);
        return RegisterResult(true);
      } else if (response.statusCode == 409) {
        return RegisterResult(
          false,
          'Email sudah terdaftar. Silakan gunakan email lain atau langsung masuk.',
        );
      } else {
        // Jika server error (misal mysql mati), simpan ke akun lokal agar user tetap bisa mendaftar
        await _saveLocalUser(name, email, phone, password);
        return RegisterResult(true);
      }
    } catch (e) {
      print('Register Network Error / Offline Fallback: $e');
      // Fallback penyimpanan offline jika server backend belum running
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('local_registered_users');
        List<dynamic> users = raw != null ? jsonDecode(raw) : [];

        bool exists = users.any(
          (u) => u['email']?.toString().toLowerCase() == email.trim().toLowerCase(),
        );
        if (exists) {
          return RegisterResult(
            false,
            'Email sudah terdaftar. Silakan gunakan email lain atau langsung masuk.',
          );
        }

        await _saveLocalUser(name, email, phone, password);
        return RegisterResult(true);
      } catch (err) {
        return RegisterResult(false, 'Gagal mendaftar: $err');
      }
    }
  }

  static Future<void> _saveLocalUser(String name, String email, String phone, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_registered_users');
      List<dynamic> users = raw != null ? jsonDecode(raw) : [];
      final cleanEmail = email.trim().toLowerCase();
      users.removeWhere((u) => u['email']?.toString().toLowerCase() == cleanEmail);
      users.add({
        'name': name.trim(),
        'email': cleanEmail,
        'phone': phone.trim(),
        'password': password,
        'role': 'BUYER',
      });
      await prefs.setString('local_registered_users', jsonEncode(users));
    } catch (_) {}
  }

  static Future<LoginResult> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': cleanEmail, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>?;
        final role = user?['role']?.toString();

        // Validasi: Aplikasi mobile HANYA untuk role BUYER (pembeli)
        if (role != null && role != 'BUYER') {
          return LoginResult(
            success: false,
            message:
                'Akun Anda terdaftar sebagai ${role == 'ADMIN' ? 'Pembudidaya / Penjual' : role}. Aplikasi mobile ini khusus untuk Pembeli. Silakan masuk melalui Dashboard Web.',
          );
        }

        // Simpan sesi ke ApiClient singleton
        await ApiClient.instance.saveSession({
          'token': token,
          'refreshToken': data['refreshToken'] ?? token,
          'user': user ?? {
            'id': 1,
            'name': 'User',
            'email': cleanEmail,
            'role': 'BUYER',
          },
        });

        return LoginResult(success: true, token: token);
      }
    } catch (e) {
      print('Login Network Fallback: $e');
    }

    // Fallback login offline jika server backend atau DB tidak merespons
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_registered_users');
      if (raw != null) {
        List<dynamic> users = jsonDecode(raw);
        final match = users.firstWhere(
          (u) =>
              u['email']?.toString().toLowerCase() == cleanEmail &&
              u['password'] == password,
          orElse: () => null,
        );
        if (match != null) {
          final role = match['role'] ?? 'BUYER';
          if (role != 'BUYER') {
            return LoginResult(
              success: false,
              message:
                  'Akun Anda terdaftar sebagai Pembudidaya / Penjual. Aplikasi mobile ini khusus untuk Pembeli. Silakan masuk melalui Dashboard Web.',
            );
          }
          final dummyToken =
              'local_token_${DateTime.now().millisecondsSinceEpoch}';
          final userData = {
            'id': DateTime.now().millisecondsSinceEpoch % 10000,
            'name': match['name'] ?? 'User',
            'email': match['email'] ?? cleanEmail,
            'phoneNumber': match['phone'] ?? '',
            'role': 'BUYER',
          };
          await ApiClient.instance.saveSession({
            'token': dummyToken,
            'refreshToken': dummyToken,
            'user': userData,
          });
          return LoginResult(success: true, token: dummyToken);
        }
      }
    } catch (_) {}

    return LoginResult(
      success: false,
      message: 'Email atau kata sandi yang Anda masukkan salah.',
    );
  }
}
