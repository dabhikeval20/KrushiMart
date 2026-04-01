import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/user.dart' as user_model;
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedCategory = 'seeds';
  bool _isLoading = false;

  final List<String> _categories = [
    'seeds',
    'fertilizers',
    'tools',
    'machines',
    'vegetables',
    'fruits',
    'grains',
    'dairy',
    'spices',
    'other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List New Product')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_business_rounded,
                      size: 40,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sell Your Produce',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Basic Details'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        hintText: 'e.g., Organic Wheat',
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter product name'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Tell buyers about your product...',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter description'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Pricing & Media'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (₹)',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter price' : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Select a category' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity (kg)',
                        hintText: 'e.g., 50',
                        prefixIcon: Icon(Icons.scale_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Enter quantity';
                        final qty = int.tryParse(value);
                        if (qty == null || qty <= 0)
                          return 'Enter valid quantity';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL (Optional)',
                        hintText: 'https://example.com/image.jpg',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                      validator: (value) => null, // Optional field
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleAddProduct,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Publish Listing'),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Save as Draft',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  void _handleAddProduct() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      print('🔍 Checking authentication...');
      if (authProvider.currentUser == null) {
        print('⚠️ User not authenticated - using test user for debugging');
        // Temporarily create a test user for debugging
        final testUserId = 'test-user-123';

        // For debugging, we'll proceed with the test user
        final newProduct = Product(
          id: '', // Will be set by Firestore
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          imageUrl: _imageUrlController.text.trim(),
          sellerId: testUserId, // Use test user ID
          category: _selectedCategory,
          quantity: int.parse(_quantityController.text),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        print('📦 Creating product with test user: ${newProduct.name}');
        print('👤 Test Seller ID: ${newProduct.sellerId}');

        setState(() => _isLoading = true);
        final success = await productProvider.addProduct(newProduct);
        setState(() => _isLoading = false);

        print('📤 Add product result: $success');

        if (success) {
          print('✅ Product added successfully with test user');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product listed successfully! (Test Mode)'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          print('❌ Failed to add product with test user');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add product. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Handle authenticated user case
      print('✅ User authenticated: ${authProvider.currentUser!.id}');
      setState(() => _isLoading = true);

      final newProduct = Product(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        imageUrl: _imageUrlController.text.trim(),
        sellerId: authProvider.currentUser!.id,
        category: _selectedCategory,
        quantity: int.parse(_quantityController.text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('📦 Creating product: ${newProduct.name}');
      print('👤 Seller ID: ${newProduct.sellerId}');

      final success = await productProvider.addProduct(newProduct);

      print('📤 Add product result: $success');
      setState(() => _isLoading = false);

      if (success) {
        print('✅ Product added successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product listed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form
        _formKey.currentState!.reset();
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _imageUrlController.clear();
        _quantityController.clear();
        setState(() => _selectedCategory = 'seeds');
      } else {
        print('❌ Failed to add product');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to add product. Please check your connection and try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
