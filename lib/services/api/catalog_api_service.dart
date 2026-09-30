import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../../models/category.dart';
import '../../models/pagination.dart';
import '../../models/product.dart';
import '../../models/product_query.dart';

class CatalogApiService {
  const CatalogApiService(this._client);

  final ApiClient _client;

  static PaginatedList<Product> _page(Object? data) =>
      PaginatedList.fromData(data, Product.fromJson);

  Future<List<Category>> getCategories() async {
    final response = await _client.get(
      ApiEndpoints.categories,
      auth: false,
      decoder: (data) => Json.list(data, Category.fromJson),
    );
    return response.data;
  }

  /// Products for a category, or across the catalog when no category is set.
  Future<PaginatedList<Product>> getProducts(ProductQuery query) async {
    final categoryId = query.categoryId;
    final response = await _client.get(
      categoryId == null ? ApiEndpoints.products : ApiEndpoints.categoryProducts(categoryId),
      query: query.toQueryParameters(),
      decoder: _page,
    );
    return response.data;
  }

  /// One of the curated lists: featured, popular, latest or deals.
  Future<List<Product>> getCollection(String path, {int perPage = 10}) async {
    final response = await _client.get(
      path,
      auth: false,
      query: {'page': 1, 'per_page': perPage},
      decoder: _page,
    );
    return response.data.items;
  }

  Future<Product> getProduct(String id) async {
    final response = await _client.get(
      ApiEndpoints.product(id),
      decoder: (data) => Product.fromJson(Json.map(data)),
    );
    return response.data;
  }

  Future<List<Product>> search(String term, {int perPage = 30}) async {
    final response = await _client.get(
      ApiEndpoints.searchProducts,
      query: {'q': term, 'page': 1, 'per_page': perPage},
      decoder: _page,
    );
    return response.data.items;
  }
}
