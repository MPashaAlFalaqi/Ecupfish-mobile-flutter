import 'api/api_client.dart';

class AuctionApi {
  static final ApiClient _c = ApiClient.instance;

  static Future list() async {
    final res = await _c.get('/api/auctions') as Map;
    return (res['data'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future detail(int auctionId) async {
    final res = await _c.get('/api/auctions/$auctionId') as Map;
    return Map<String, dynamic>.from(res['data'] as Map);
  }

  static Future placeBid(int auctionId, int amount) async {
    final res = await _c.post('/api/auctions/$auctionId/bids', {
      'amount': amount,
    }) as Map;
    return Map<String, dynamic>.from(res['data'] as Map);
  }
}