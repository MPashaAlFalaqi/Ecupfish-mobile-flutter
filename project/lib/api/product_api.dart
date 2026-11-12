import '../core.dart';
import 'api_client.dart';

class ProductApi {
  static final ApiClient _c = ApiClient.instance;

  static Future<List<Fish>> list({
    String? q,
    String? category,
    String? grade,
    int? minPrice,
    int? maxPrice,
  }) async {
    final query = <String, String>{
      'limit': '50',
      if (q != null && q.isNotEmpty) 'q': q,
      if (category != null && category != 'All') 'category': category.toLowerCase(),
      if (grade != null) 'grade': grade.toUpperCase(),
      if (minPrice != null) 'minPrice': '$minPrice',
      if (maxPrice != null) 'maxPrice': '$maxPrice',
    };
    final data = await _c.get('/api/products', query: query) as Map<String, dynamic>;
    return (data['data'] as List)
        .map((e) => Fish.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}