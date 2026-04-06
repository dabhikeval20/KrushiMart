import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/farming_tip.dart';
import '../models/api_product.dart';

class ApiService {
  // 🌐 Base URLs for APIs
  static const String _fakeStoreApi = 'https://fakestoreapi.com';
  static const String _jsonPlaceholdApi = 'https://jsonplaceholder.typicode.com';

  /// 📦 FETCH ALL PRODUCTS FROM FAKESTORE API
  /// 
  /// This method makes a GET request to FakeStore API and returns a list of products.
  /// FakeStore API: https://fakestoreapi.com/products
  /// 
  /// Response Example:
  /// [
  ///   {
  ///     "id": 1,
  ///     "title": "Fjallraven - Backpack",
  ///     "price": 109.95,
  ///     "description": "...",
  ///     "image": "...",
  ///     "category": "electronics",
  ///     "rating": {"rate": 3.9, "count": 120}
  ///   },
  ///   ...
  /// ]
  Future<List<ApiProduct>> fetchProducts() async {
    try {
      print('🔄 Fetching products from FakeStore API...');
      
      // Create URI for the API endpoint
      final uri = Uri.parse('$_fakeStoreApi/products');
      
      // Make GET request
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API request timed out. Please check your internet connection.');
        },
      );

      print('📊 Response status code: ${response.statusCode}');

      // Check if response is successful (status code 200)
      if (response.statusCode == 200) {
        // Decode JSON response body
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        
        print('✅ Successfully fetched ${data.length} products');

        // Convert JSON list to ApiProduct objects
        final products = data
            .map((item) => ApiProduct.fromJson(item as Map<String, dynamic>))
            .toList();

        return products;
      } else {
        // Handle HTTP error
        throw Exception(
          'Failed to fetch products. Status code: ${response.statusCode}',
        );
      }
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('❌ Error fetching products: $e');
      rethrow;
    }
  }

  /// 📦 FETCH PRODUCTS BY CATEGORY
  /// 
  /// Fetch products filtered by a specific category
  /// 
  /// Categories available:
  /// - electronics
  /// - jewelery
  /// - men's clothing
  /// - women's clothing
  Future<List<ApiProduct>> fetchProductsByCategory(String category) async {
    try {
      print('🔄 Fetching $category products...');

      final uri = Uri.parse('$_fakeStoreApi/products/category/$category');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API request timed out');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        
        print('✅ Fetched ${data.length} $category products');

        return data
            .map((item) => ApiProduct.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to fetch $category products. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error fetching $category products: $e');
      rethrow;
    }
  }

  /// 📦 GET SINGLE PRODUCT BY ID
  /// 
  /// Fetch a single product by its ID
  Future<ApiProduct> fetchProductById(int productId) async {
    try {
      print('🔄 Fetching product $productId...');

      final uri = Uri.parse('$_fakeStoreApi/products/$productId');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        print('✅ Fetched product: ${data['title']}');

        return ApiProduct.fromJson(data);
      } else {
        throw Exception(
          'Product not found. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error fetching product: $e');
      rethrow;
    }
  }

  /// 🏠 GET ALL CATEGORIES
  /// 
  /// Fetch list of all available product categories
  Future<List<String>> fetchCategories() async {
    try {
      print('🔄 Fetching categories...');

      final uri = Uri.parse('$_fakeStoreApi/products/categories');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API request timed out');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        
        final categories = data.map((item) => item as String).toList();
        
        print('✅ Fetched ${categories.length} categories');

        return categories;
      } else {
        throw Exception(
          'Failed to fetch categories. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error fetching categories: $e');
      rethrow;
    }
  }

  // This method fetches farming tips from a sample public API.
  Future<List<FarmingTip>> fetchFarmingTips() async {
    final uri = Uri.parse(
      'https://jsonplaceholder.typicode.com/posts?_limit=10',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data from API (${response.statusCode})');
    }

    final List<dynamic> data = json.decode(response.body) as List<dynamic>;

    return data.map((item) {
      return FarmingTip.fromJson(item as Map<String, dynamic>);
    }).toList();
  }
}
