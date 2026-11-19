import 'api_client.dart';

typedef JsonMap = Map<String, dynamic>;

class UserApi {
  static final ApiClient _c = ApiClient.instance;

  static Future<JsonMap> getProfile() async {
    final res = await _c.get('/api/me') as JsonMap;
    final user = JsonMap.from(res['user'] as Map);
    _c.user = user;
    return user;
  }

  static Future<JsonMap> updateProfile({
    String? name,
    String? username,
    String? phoneNumber,
  }) async {
    final res = await _c.put('/api/me', {
      if (name != null) 'name': name.trim(),
      if (username != null) 'username': username.trim(),
      if (phoneNumber != null) 'phoneNumber': phoneNumber.trim(),
    }) as JsonMap;
    final user = JsonMap.from(res['user'] as Map);
    _c.user = user;
    return user;
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _c.put('/api/me/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  static Future<List<JsonMap>> getAddresses() async {
    final res = await _c.get('/api/me/addresses') as JsonMap;
    final list = res['data'] as List? ?? [];
    return list.map((e) => JsonMap.from(e as Map)).toList();
  }

  static Future<JsonMap> addAddress({
    String? label,
    required String recipientName,
    required String phoneNumber,
    required String address,
    required String city,
    String? province,
    required String postalCode,
    bool isDefault = false,
  }) async {
    final res = await _c.post('/api/me/addresses', {
      if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
      'recipientName': recipientName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'address': address.trim(),
      'city': city.trim(),
      if (province != null && province.trim().isNotEmpty) 'province': province.trim(),
      'postalCode': postalCode.trim(),
      'isDefault': isDefault,
    }) as JsonMap;
    return JsonMap.from(res['data'] as Map);
  }

  static Future<void> deleteAddress(int id) async {
    await _c.delete('/api/me/addresses/$id');
  }
}