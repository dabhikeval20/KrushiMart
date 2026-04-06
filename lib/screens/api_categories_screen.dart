import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import 'api_products_screen.dart';

class ApiCategoriesScreen extends StatefulWidget {
  const ApiCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<ApiCategoriesScreen> createState() => _ApiCategoriesScreenState();
}

class _ApiCategoriesScreenState extends State<ApiCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch categories on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop by Category'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          // Show loading state
          if (productProvider.categories.isEmpty &&
              productProvider.apiError == null) {
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
                    'Loading categories...',
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
                      productProvider.fetchCategories();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show categories grid
          final categoryNames = productProvider.categories
              .map((cat) =>
                  cat[0].toUpperCase() + cat.substring(1).replaceAll('&', '& '))
              .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: productProvider.categories.length,
            itemBuilder: (context, index) {
              final categoryKey = productProvider.categories[index];
              final categoryName = categoryNames[index];
              final categoryIcon = _getCategoryIcon(categoryKey);
              final categoryColor = _getCategoryColor(index);

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ApiProductsScreen(category: categoryKey),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          categoryColor.withOpacity(0.8),
                          categoryColor.withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          categoryIcon,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          categoryName,
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
            },
          );
        },
      ),
    );
  }

  // Get icon for each category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'jewelery':
        return Icons.diamond;
      case "men's clothing":
        return Icons.man;
      case "women's clothing":
        return Icons.woman;
      default:
        return Icons.shopping_bag;
    }
  }

  // Get color for each category
  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue.shade600,
      Colors.purple.shade600,
      Colors.orange.shade600,
      Colors.pink.shade600,
    ];
    return colors[index % colors.length];
  }
}
