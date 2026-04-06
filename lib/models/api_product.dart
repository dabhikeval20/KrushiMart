/// API Product Model - For FakeStore API integration
/// This model represents products fetched from an external API

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

  /// Convert JSON from API to ApiProduct object
  /// JSON structure from FakeStore API:
  /// {
  ///   "id": 1,
  ///   "title": "Fjallraven - Backpack",
  ///   "price": 109.95,
  ///   "description": "...",
  ///   "image": "https://...",
  ///   "category": "electronics",
  ///   "rating": {
  ///     "rate": 3.9,
  ///     "count": 120
  ///   }
  /// }
  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    try {
      final rating = json['rating'] as Map<String, dynamic>?;
      
      return ApiProduct(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? 'Unknown Product',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] as String? ?? 'No description',
        image: json['image'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        rating: (rating?['rate'] as num?)?.toDouble() ?? 0.0,
        ratingCount: rating?['count'] as int? ?? 0,
      );
    } catch (e) {
      print('❌ Error parsing ApiProduct: $e');
      rethrow;
    }
  }

  /// Convert ApiProduct to JSON
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

  /// Create a copy with updated fields
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
  String toString() {
    return 'ApiProduct(id: $id, title: $title, price: $price, category: $category)';
  }
}
