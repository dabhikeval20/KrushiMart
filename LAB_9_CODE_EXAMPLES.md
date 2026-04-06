# LAB 9: Code Implementation Guide

## 📝 Complete Code Examples

### 1. API Product Model (lib/models/api_product.dart)

```dart
class ApiProduct {
  final int id;
  final String title;
  final double price;
  final String description;
  final String image;
  final String category;
  final double rating;
  final int ratingCount;

  ApiProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.image,
    required this.category,
    required this.rating,
    required this.ratingCount,
  });

  // Parse JSON from API response
  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    return ApiProduct(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown',
      price: (json['price'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      category: json['category'] ?? 'uncategorized',
      rating: (json['rating']?['rate'] ?? 0.0).toDouble(),
      ratingCount: json['rating']?['count'] ?? 0,
    );
  }

  // Convert Dart object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'image': image,
      'category': category,
      'rating': {
        'rate': rating,
        'count': ratingCount,
      },
    };
  }

  // Create a copy with modified fields
  ApiProduct copyWith({
    int? id,
    String? title,
    double? price,
    String? description,
    String? image,
    String? category,
    double? rating,
    int? ratingCount,
  }) {
    return ApiProduct(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      image: image ?? this.image,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  @override
  String toString() => 'ApiProduct(id: $id, title: $title, price: $price)';
}
```

---

### 2. API Service (lib/services/api_service.dart)

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/api_product.dart';

class ApiService {
  static const String baseUrl = 'https://fakestoreapi.com';
  static const Duration timeout = Duration(seconds: 10);

  // Fetch all products
  Future<List<ApiProduct>> fetchProducts() async {
    try {
      print('🔄 Fetching all products from $baseUrl/products...');
      
      final response = await http
          .get(Uri.parse('$baseUrl/products'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final products = jsonData
            .map((json) => ApiProduct.fromJson(json as Map<String, dynamic>))
            .toList();
        
        print('✅ Successfully fetched ${products.length} products');
        return products;
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } on TimeoutException {
      print('⏱️ Request timeout after $timeout');
      throw Exception('Request timeout: Unable to connect to server');
    } catch (e) {
      print('❌ Error fetching products: $e');
      throw Exception('Error fetching products: $e');
    }
  }

  // Fetch products by category
  Future<List<ApiProduct>> fetchProductsByCategory(String category) async {
    try {
      print('🔄 Fetching products for category: $category');
      
      final response = await http
          .get(Uri.parse('$baseUrl/products/category/$category'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final products = jsonData
            .map((json) => ApiProduct.fromJson(json as Map<String, dynamic>))
            .toList();
        
        print('✅ Found ${products.length} products in $category');
        return products;
      } else {
        throw Exception('Failed to load category products: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timeout: Unable to connect to server');
    } catch (e) {
      print('❌ Error fetching $category products: $e');
      throw Exception('Error fetching products: $e');
    }
  }

  // Fetch single product by ID
  Future<ApiProduct> fetchProductById(int productId) async {
    try {
      print('🔄 Fetching product ID: $productId');
      
      final response = await http
          .get(Uri.parse('$baseUrl/products/$productId'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final product = ApiProduct.fromJson(json);
        
        print('✅ Successfully fetched product: ${product.title}');
        return product;
      } else {
        throw Exception('Product not found');
      }
    } on TimeoutException {
      throw Exception('Request timeout: Unable to connect to server');
    } catch (e) {
      print('❌ Error fetching product: $e');
      throw Exception('Error fetching product: $e');
    }
  }

  // Fetch all available categories
  Future<List<String>> fetchCategories() async {
    try {
      print('🔄 Fetching all categories...');
      
      final response = await http
          .get(Uri.parse('$baseUrl/products/categories'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final categories = jsonData.map((cat) => cat.toString()).toList();
        
        print('✅ Found ${categories.length} categories: $categories');
        return categories;
      } else {
        throw Exception('Failed to load categories');
      }
    } on TimeoutException {
      throw Exception('Request timeout: Unable to connect to server');
    } catch (e) {
      print('❌ Error fetching categories: $e');
      throw Exception('Error fetching categories: $e');
    }
  }
}
```

---

### 3. Provider Integration (lib/providers/product_provider.dart - API Methods)

```dart
// Add these imports at the top:
import '../models/api_product.dart';
import '../services/api_service.dart';

// In ProductProvider class, add these properties:
class ProductProvider with ChangeNotifier {
  // ... existing properties ...

  final ApiService _apiService = ApiService();

  List<ApiProduct> apiProducts = [];
  List<String> categories = [];
  bool isLoadingApiProducts = false;
  String? apiError;

  // Fetch all products from API
  Future<void> fetchApiProducts() async {
    try {
      isLoadingApiProducts = true;
      apiError = null;
      notifyListeners();

      apiProducts = await _apiService.fetchProducts();
      print('✅ Loaded ${apiProducts.length} API products');

      isLoadingApiProducts = false;
      notifyListeners();
    } catch (e) {
      apiError = 'Failed to fetch products: $e';
      print('❌ Error: $apiError');
      isLoadingApiProducts = false;
      notifyListeners();
    }
  }

  // Fetch products for a specific category
  Future<void> fetchApiProductsByCategory(String category) async {
    try {
      isLoadingApiProducts = true;
      apiError = null;
      notifyListeners();

      apiProducts = await _apiService.fetchProductsByCategory(category);
      print('✅ Loaded ${apiProducts.length} products from $category');

      isLoadingApiProducts = false;
      notifyListeners();
    } catch (e) {
      apiError = 'Failed to fetch products: $e';
      print('❌ Error: $apiError');
      isLoadingApiProducts = false;
      notifyListeners();
    }
  }

  // Fetch available categories
  Future<void> fetchCategories() async {
    try {
      categories = await _apiService.fetchCategories();
      print('✅ Loaded ${categories.length} categories');
      notifyListeners();
    } catch (e) {
      apiError = 'Failed to fetch categories: $e';
      print('❌ Error: $apiError');
      notifyListeners();
    }
  }

  // Get single product details
  Future<ApiProduct?> fetchApiProductById(int productId) async {
    try {
      final product = await _apiService.fetchProductById(productId);
      return product;
    } catch (e) {
      apiError = 'Failed to fetch product: $e';
      notifyListeners();
      return null;
    }
  }

  // Search products in current list
  List<ApiProduct> searchApiProducts(String query) {
    if (query.isEmpty) return apiProducts;
    
    return apiProducts
        .where((product) =>
            product.title.toLowerCase().contains(query.toLowerCase()) ||
            product.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Filter by price range
  List<ApiProduct> filterApiProductsByPrice(double min, double max) {
    return apiProducts
        .where((product) => product.price >= min && product.price <= max)
        .toList();
  }

  // Filter by rating
  List<ApiProduct> filterApiProductsByRating(double minRating) {
    return apiProducts
        .where((product) => product.rating >= minRating)
        .toList();
  }

  // Get products by category from cache
  List<ApiProduct> getApiProductsByCategory(String category) {
    return apiProducts
        .where((product) =>
            product.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  // Clear cache
  void clearApiProducts() {
    apiProducts = [];
    apiError = null;
    notifyListeners();
  }
}
```

---

### 4. UI - Products List Screen

```dart
// lib/screens/api_products_screen.dart - Key sections

class _ApiProductsScreenState extends State<ApiProductsScreen> {
  late ProductProvider _productProvider;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productProvider = context.read<ProductProvider>();

    if (widget.category != null) {
      _productProvider.fetchApiProductsByCategory(widget.category!);
    } else {
      _productProvider.fetchApiProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category ?? 'API Products'),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          // LOADING STATE
          if (productProvider.isLoadingApiProducts) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Loading products...'),
                ],
              ),
            );
          }

          // ERROR STATE
          if (productProvider.apiError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(productProvider.apiError ?? 'Error'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.category != null) {
                        productProvider
                            .fetchApiProductsByCategory(widget.category!);
                      } else {
                        productProvider.fetchApiProducts();
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Filter products based on search
          final filtered =
              productProvider.searchApiProducts(_searchController.text);

          // EMPTY STATE
          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.grey.shade400,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text('No products found'),
                ],
              ),
            );
          }

          // SUCCESS STATE
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),

              // Product List
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return _buildProductCard(context, product);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ApiProduct product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApiProductDetailsScreen(
                product: product,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.image,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${product.rating.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' (${product.ratingCount})',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 5. UI - Categories Screen

```dart
// lib/screens/api_categories_screen.dart - Build method

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Shop by Category'),
      backgroundColor: Colors.green.shade700,
    ),
    body: Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // Loading
        if (productProvider.categories.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.green.shade700,
              ),
            ),
          );
        }

        // Error
        if (productProvider.apiError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(productProvider.apiError ?? 'Error'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => productProvider.fetchCategories(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Display categories as grid
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: productProvider.categories.length,
          itemBuilder: (context, index) {
            final category = productProvider.categories[index];
            return _buildCategoryCard(context, category);
          },
        );
      },
    ),
  );
}

Widget _buildCategoryCard(BuildContext context, String category) {
  final displayName = category[0].toUpperCase() + 
                      category.substring(1).replaceAll('&', '& ');

  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ApiProductsScreen(category: category),
        ),
      );
    },
    child: Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade400],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

---

## 🎯 Quick Reference: API URLs

### Test in Browser/Postman:
```
GET all products:
https://fakestoreapi.com/products

GET single product:
https://fakestoreapi.com/products/1

GET by category:
https://fakestoreapi.com/products/category/electronics
https://fakestoreapi.com/products/category/jewelery
https://fakestoreapi.com/products/category/men's%20clothing
https://fakestoreapi.com/products/category/women's%20clothing

GET categories:
https://fakestoreapi.com/products/categories
```

---

## ✅ Implementation Checklist

- [ ] Create `api_product.dart` with fromJson() and toJson()
- [ ] Update `api_service.dart` with 4 fetch methods
- [ ] Add API methods to `product_provider.dart`
- [ ] Create `api_products_screen.dart` with search and states
- [ ] Create `api_product_details_screen.dart` with full product view
- [ ] Create `api_categories_screen.dart` with category grid
- [ ] Update `buyer_dashboard_screen.dart` with API link
- [ ] Test all screens work without crashes
- [ ] Test loading, error, and empty states
- [ ] Test search functionality
- [ ] Verify images load properly
- [ ] Test navigation between screens

---

## 🚀 Running the App

```bash
# Clean and rebuild
flutter clean
flutter pub get

# Run with logs
flutter run

# Check for errors
flutter analyze

# Build APK for testing
flutter build apk

# Run tests (if added)
flutter test
```

---

## 🔗 JSON Parsing Reference

### Handling API Response
```dart
// Raw JSON from API
final response = await http.get(Uri.parse('https://fakestoreapi.com/products'));

// Decode JSON string to List
final jsonData = jsonDecode(response.body) as List;

// Map to Dart objects
final products = jsonData
    .map((json) => ApiProduct.fromJson(json as Map<String, dynamic>))
    .toList();
```

---

This completes the code implementation for LAB 9!

