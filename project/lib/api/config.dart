import 'package:flutter/foundation.dart';

// Untuk HP fisik atau produksi: flutter run --dart-define=API_URL=http://192.168.1.10:3000
const String _override = String.fromEnvironment('API_URL');

String get baseUrl {
  if (_override.isNotEmpty) return _override;
  if (kIsWeb) return 'http://localhost:3000'; // Chrome
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000'; // emulator Android
  }
  return 'http://localhost:3000';
}