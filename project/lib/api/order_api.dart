import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../core.dart';

class OrderApi {
  static final ApiClient _c = ApiClient.instance;

  static Future<void> syncOrderToDashboard(Order o, Draft d, String payment) async {
    final buyerName = (_c.user?['name'] != null && _c.user!['name'].toString().trim().isNotEmpty)
        ? _c.user!['name'].toString()
        : 'Sinta';
    final buyerPhone = _c.user?['phoneNumber']?.toString() ?? '08123456789';
    final address = 'Jl. Anggrek No. 12, Pekanbaru';
    final fishName = d.names.isNotEmpty ? d.names.join(', ') : 'Ikan Cupang Kontes';
    final totalQty = d.lines.isNotEmpty ? d.lines.fold<int>(0, (a, b) => a + b.$2) : 1;
    final isAuction = d.names.any((n) => n.toLowerCase().contains('lelang'));

    final orderPayload = {
      'id': o.id,
      'pembeli': buyerName,
      'alamat': address,
      'ikan': fishName,
      'jumlah': totalQty,
      'hargaSatuan': d.subtotal,
      'ongkir': d.ship,
      'sumber': isAuction ? 'Lelang' : 'Beli langsung',
      'metode': payment,
      'status': 'Dibayar',
      'ts': DateTime.now().millisecondsSinceEpoch,
    };

    // 1. Simpan event sinkronisasi real-time untuk Dashboard Web
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ecupfish_new_order_event', jsonEncode(orderPayload));

      // Simpan riwayat pesanan lokal agar tetap ada saat reload
      final raw = prefs.getString('local_saved_orders');
      List<dynamic> list = raw != null ? jsonDecode(raw) : [];
      list.insert(0, orderPayload);
      await prefs.setString('local_saved_orders', jsonEncode(list));
    } catch (_) {}

    // 2. Kirim ke backend Express / MySQL jika backend sedang berjalan
    try {
      final items = d.lines.map((l) {
        final pid = int.tryParse(l.$1.id) ?? 1;
        return {'productId': pid, 'quantity': l.$2};
      }).toList();

      if (items.isNotEmpty) {
        final checkoutRes = await _c.post('/api/orders/checkout', {
          'recipientName': buyerName,
          'recipientPhone': buyerPhone,
          'shippingAddress': address,
          'paymentMethod': payment,
          'shippingCost': d.ship,
          'guaranteeFee': d.guarantee,
          'items': items,
        }) as Map?;

        if (checkoutRes != null && checkoutRes['data']?['id'] != null) {
          final orderId = checkoutRes['data']['id'];
          await _c.post('/api/orders/$orderId/pay');
        }
      }
    } catch (e) {
      print('Checkout backend fallback to local sync: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getBuyerOrders() async {
    try {
      final res = await _c.get('/api/orders') as Map;
      final data = res['data'] as List? ?? [];
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('local_saved_orders');
        if (raw != null) {
          final list = jsonDecode(raw) as List;
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
      return [];
    }
  }
}
