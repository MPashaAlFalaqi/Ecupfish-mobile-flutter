import 'api_client.dart';

class AuthApi {
  static final ApiClient _c = ApiClient.instance;

  static Future<void> login(String email, String password) async {
    final data = await _c.post('/api/auth/login', {
      'email': email.trim(),
      'password': password,
    }) as Map<String, dynamic>;
    // Aplikasi mobile hanya untuk pembeli
    final role = (data['user'] as Map)['role'];
    if (role != 'BUYER') {
      throw ApiException(403, 'Akun ini bukan akun pembeli. Gunakan dashboard web.');
    }
    await _c.saveSession(data);
  }

  static Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await _c.post('/api/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      if (phone != null && phone.trim().isNotEmpty) 'phoneNumber': phone.trim(),
    }) as Map<String, dynamic>;
    await _c.saveSession(data);
  }

  static Future<void> logout() async {
    final rt = _c.refreshToken;
    try {
      if (rt != null) await _c.post('/api/auth/logout', {'refreshToken': rt});
    } catch (_) {}
    await _c.clear();
  }

  static Future<void> forgotPassword(String target) async {
    await _c.post('/api/auth/forgot-password', {'target': target.trim()});
  }

  static Future<String> verifyOtp(String target, String code) async {
    final data = await _c.post('/api/auth/verify-otp', {
      'target': target.trim(),
      'code': code,
    }) as Map<String, dynamic>;
    return data['resetToken'] as String;
  }

  static Future<void> resetPassword(String resetToken, String newPassword) async {
    await _c.post('/api/auth/reset-password', {
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
  }
}