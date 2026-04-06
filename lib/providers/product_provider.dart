import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/api_product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _apiService = ApiService();

  List<Product> products = [];
  
  // API Product properties
  List<ApiProduct> apiProducts = [];
  List<String> categories = [];
  bool isLoadingApiProducts = false;
  String? apiError;

  // Test Firestore connection
  Future<bool> testConnection() async {
    try {
      print('🔍 Testing Firestore connection...');
      await _firestore
          .collection('test')
          .doc('connection')
          .get();
      print('✅ Firestore connection successful');
      return true;
    } catch (e) {
      print('❌ Firestore connection failed: $e');
      return false;
    }
  }

  // Get all products as a stream
  Stream<List<Product>> getProducts() {
    try {
      return _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            print('📊 Found ${snapshot.docs.length} products in Firestore');
            return snapshot.docs.map((doc) {
              return Product.fromMap(doc.data(), doc.id);
            }).toList();
          });
    } catch (e) {
      print('❌ Error in getProducts: $e');
      return Stream.value([]);
    }
  }

  // Get products by seller - FIXED: Remove compound query to avoid index error
  Stream<List<Product>> getProductsBySeller(String sellerId) {
    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Product.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('products')
          .doc(productId)
          .get();
      if (doc.exists) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting product: $e');
      return null;
    }
  }

  // Add new product
  Future<bool> addProduct(Product product) async {
    try {
      print('🔥 Adding product to Firestore: ${product.name}');
      print('📊 Product data: ${product.toMap()}');

      await _firestore.collection('products').add(product.toMap());

      print('✅ Product added successfully to Firestore');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error adding product: $e');
      return false;
    }
  }

  // Update existing product
  Future<bool> updateProduct(String productId, Product updatedProduct) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        ...updatedProduct.toMap(),
        'updatedAt': Timestamp.now(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  // Search products
  Stream<List<Product>> searchProducts(String query) {
    return _firestore
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Product.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get products by category - FIXED: Remove orderBy to avoid index requirement
  Stream<List<Product>> getProductsByCategory(String category) {
    try {
      return _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .snapshots()
          .map((snapshot) {
            print(
              '📊 Found ${snapshot.docs.length} products in category: $category',
            );
            return snapshot.docs.map((doc) {
              return Product.fromMap(doc.data(), doc.id);
            }).toList();
          });
    } catch (e) {
      print('❌ Error in getProductsByCategory: $e');
      return Stream.value([]);
    }
  }

  // ============================================
  // API PRODUCT METHODS (FakeStore API Integration)
  // ============================================

  // Fetch all products from FakeStore API
  Future<void> fetchApiProducts() async {
    try {
      isLoadingApiProducts = true;
      apiError = null;
      notifyListeners();

      apiProducts = await _apiService.fetchProducts();
      print('✅ Fetched ${apiProducts.length} products from API');

      isLoadingApiProducts = false;
      notifyListeners();
    } catch (e) {
      apiError = 'Failed to fetch products: $e';
      print('❌ Error fetching API products: $apiError');
      isLoadingApiProducts = false;
      notifyListeners();
    }
  }

  // Fetch products by category from API
  Future<void> fetchApiProductsByCategory(String category) async {
    try {
      isLoadingApiProducts = true;
      apiError = null;
      notifyListeners();

      apiProducts = await _apiService.fetchProductsByCategory(category);
      print('✅ Fetched ${apiProducts.length} products from category: $category');

      isLoadingApiProducts = false;
      notifyListeners();
    } catch (e) {
      apiError = 'Failed to fetch products: $e';
      print('❌ Error fetching API products by category: $apiError');
      isLoadingApiProducts = false;
      notifyListeners();
    }
  }

  // Fetch categories from API
  Future<void> fetchCategories() async {
    try {
      categories = await _apiService.fetchCategories();
      print('✅ Fetched ${categories.length} categories: $categories');
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching categories: $e');
      apiError = 'Failed to fetch categories: $e';
      notifyListeners();
    }
  }

  // Get single product by ID from API
  Future<ApiProduct?> fetchApiProductById(int productId) async {
    try {
      final product = await _apiService.fetchProductById(productId);
      return product;
    } catch (e) {
      print('❌ Error fetching product $productId: $e');
      apiError = 'Failed to fetch product details: $e';
      notifyListeners();
      return null;
    }
  }

  // Search API products by title
  List<ApiProduct> searchApiProducts(String query) {
    if (query.isEmpty) {
      return apiProducts;
    }
    return apiProducts
        .where((product) =>
            product.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Filter API products by price range
  List<ApiProduct> filterApiProductsByPrice(double minPrice, double maxPrice) {
    return apiProducts
        .where((product) =>
            product.price >= minPrice && product.price <= maxPrice)
        .toList();
  }

  // Filter API products by rating
  List<ApiProduct> filterApiProductsByRating(double minRating) {
    return apiProducts
        .where((product) => product.rating >= minRating)
        .toList();
  }

  // Get all API products (getter)
  List<ApiProduct> get allApiProducts => apiProducts;

  // Get API products by category (from cached list)
  List<ApiProduct> getApiProductsByCategory(String category) {
    return apiProducts
        .where((product) =>
            product.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  // Clear API products cache
  void clearApiProducts() {
    apiProducts = [];
    apiError = null;
    notifyListeners();
  }
}
