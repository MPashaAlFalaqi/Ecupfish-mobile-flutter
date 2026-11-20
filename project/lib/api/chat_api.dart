import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'config.dart' as app_config;

class ChatApi {
  static final ApiClient _c = ApiClient.instance;

  static Future<List<Map<String, dynamic>>> getSyncMessages() async {
    try {
      final res = await http
          .get(Uri.parse('${app_config.baseUrl}/api/chat/messages'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List? ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}

    // Fallback dari database terautentikasi jika endpoint sync belum ada
    try {
      final res = await _c.get('/api/conversations/1/messages') as Map;
      final data = res['data'] as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> sendSyncMessage(String body) async {
    final buyerName = (_c.user?['name'] != null &&
            _c.user!['name'].toString().trim().isNotEmpty)
        ? _c.user!['name'].toString()
        : 'Pembeli (Mobile)';

    // 1. Simpan ke local sync shared_preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'ecupfish_chat_sync',
        jsonEncode({
          'type': 'BUYER_MESSAGE',
          'buyerName': buyerName,
          'body': body,
          'createdAt': DateTime.now().toIso8601String(),
          'ts': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (_) {}

    // 2. Kirim ke backend sync endpoint (universal cross-platform)
    try {
      final res = await http.post(
        Uri.parse('${app_config.baseUrl}/api/chat/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': 'BUYER',
          'senderName': buyerName,
          'body': body,
        }),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return Map<String, dynamic>.from(data['data'] as Map);
      }
    } catch (_) {}

    // 3. Fallback kirim ke REST endpoint dengan token jika ada
    try {
      final res = await _c.post('/api/conversations/1/messages', {
        'body': body,
      }) as Map;
      return Map<String, dynamic>.from(res['data'] as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> resetMessages() async {
    try {
      await http.delete(Uri.parse('${app_config.baseUrl}/api/chat/messages'));
    } catch (_) {}
  }
}
