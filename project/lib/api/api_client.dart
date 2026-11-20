import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final _storage = const FlutterSecureStorage();
  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? user;
  Future<bool>? _refreshing;

  bool get loggedIn => _token != null;
  String? get token => _token;
  String? get refreshToken => _refreshToken;

  Future<void> load() async {
    try {
      String? rawUser;
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString('token');
        _refreshToken = prefs.getString('refresh');
        rawUser = prefs.getString('user');
      } else {
        _token = await _storage.read(key: 'token');
        _refreshToken = await _storage.read(key: 'refresh');
        rawUser = await _storage.read(key: 'user');
      }
      if (rawUser != null) {
        user = jsonDecode(rawUser) as Map<String, dynamic>;
      }
    } catch (_) {
      _token = null;
      _refreshToken = null;
      user = null;
    }
  }

  Future<void> saveSession(Map<String, dynamic> data) async {
    _token = data['token'] as String;
    _refreshToken = data['refreshToken'] as String;
    user = Map<String, dynamic>.from(data['user'] as Map);

    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('refresh', _refreshToken!);
        await prefs.setString('user', jsonEncode(user));
      } else {
        await _storage.write(key: 'token', value: _token);
        await _storage.write(key: 'refresh', value: _refreshToken);
        await _storage.write(key: 'user', value: jsonEncode(user));
      }
    } catch (_) {
      // Tetap lanjutkan sesi di memori jika penyimpanan lokal gagal
    }
  }

  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
    user = null;

    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('refresh');
        await prefs.remove('user');
      } else {
        await _storage.deleteAll();
      }
    } catch (_) {}
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);
  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body: body);
  Future<dynamic> put(String path, [Object? body]) =>
      _send('PUT', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool retry = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json';
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    if (body != null) request.body = jsonEncode(body);

    http.Response res;
    try {
      final streamed = await request.send().timeout(const Duration(seconds: 15));
      res = await http.Response.fromStream(streamed);
    } catch (_) {
      throw ApiException(0, 'Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    }

    if (res.statusCode == 401 && retry && _refreshToken != null && await _tryRefresh()) {
      return _send(method, path, body: body, query: query, retry: false);
    }

    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      data = null;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    final pesan = (data is Map && data['message'] != null)
        ? '${data['message']}'
        : 'Terjadi kesalahan (${res.statusCode}).';
    throw ApiException(res.statusCode, pesan);
  }

  Future<bool> _tryRefresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (res.statusCode != 200) {
        await clear();
        return false;
      }
      await saveSession(jsonDecode(res.body) as Map<String, dynamic>);
      return true;
    } catch (_) {
      return false;
    }
  }
}