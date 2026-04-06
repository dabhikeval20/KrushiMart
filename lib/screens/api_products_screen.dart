import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/api_product.dart';
import '../providers/product_provider.dart';
import 'api_product_details_screen.dart';

class ApiProductsScreen extends StatefulWidget {
  final String? category;

  const ApiProductsScreen({
    Key? key,
    this.category,
  }) : super(key: key);

  @override
  State<ApiProductsScreen> createState() => _ApiProductsScreenState();
}

class _ApiProductsScreenState extends State<ApiProductsScreen> {
  late ProductProvider _productProvider;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productProvider = context.read<ProductProvider>();

    // Fetch products on screen load
    if (widget.category != null) {
      _productProvider.fetchApiProductsByCategory(widget.category!);
    } else {
      _productProvider.fetchApiProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category ?? 'API Products'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          // Show loading state
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
                  const Text(
                    'Loading products...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Show error state
          if (productProvider.apiError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    productProvider.apiError ?? 'An error occurred',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
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

          // Get filtered products based on search
          List<ApiProduct> productsToDisplay =
              productProvider.searchApiProducts(_searchController.text);

          // Show empty state
          if (productsToDisplay.isEmpty) {
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
                  const Text(
                    'No products found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchController.text.isNotEmpty
                        ? 'Try a different search term'
                        : 'No products available in this category',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          // Show products list
          return Column(
            children: [
              // Search bar
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              // Product count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${productsToDisplay.length} products found',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
              // Product list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: productsToDisplay.length,
                  itemBuilder: (context, index) {
                    final product = productsToDisplay[index];
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

  // Build product card widget
  Widget _buildProductCard(BuildContext context, ApiProduct product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
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
              // Product image
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
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
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
                    // Category
                    Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price and rating row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        // Rating
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
