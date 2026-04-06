import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../services/image_service.dart';

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

  // 🖼️ Image-related state
  File? _selectedImage;

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
                      initialValue: _selectedCategory,
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
                        if (value == null || value.isEmpty) {
                          return 'Enter quantity';
                        }
                        final qty = int.tryParse(value);
                        if (qty == null || qty <= 0) {
                          return 'Enter valid quantity';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildImagePickerSection(),
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

  /// 🖼️ Build image picker section with camera/gallery options
  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Product Image'),
        const SizedBox(height: 16),
        if (_selectedImage != null)
          // Show selected image preview
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
              // Replace image button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _showImagePickerModal,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xFF2E7D32),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          // Show image picker buttons
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select Product Image',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImageFromCamera,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _pickImageFromGallery,
                          icon: const Icon(Icons.image_search_outlined),
                          label: const Text('Gallery'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Or paste URL below (optional)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (Optional)',
                  hintText: 'https://example.com/image.jpg',
                  prefixIcon: Icon(Icons.link_outlined),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Show image picker modal with camera/gallery options
  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Change Image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_search_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close_outlined, color: Colors.red),
              title: const Text(
                'Remove Image',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedImage = null);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 📷 Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final image = await ImageService.pickImageFromCamera();
      if (image != null) {
        setState(() => _selectedImage = image);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image captured successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: ${e.toString()}')),
        );
      }
    }
  }

  /// 🖼️ Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final image = await ImageService.pickImageFromGallery();
      if (image != null) {
        setState(() => _selectedImage = image);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image selected successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: ${e.toString()}')),
        );
      }
    }
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
        print('❌ User not authenticated');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login as a seller to add products'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('✅ User authenticated: ${authProvider.currentUser!.id}');
      setState(() => _isLoading = true);

      // 📤 Upload image to Firebase Storage if selected
      String imageUrl = _imageUrlController.text.trim();
      if (_selectedImage != null) {
        try {
          print('📷 Uploading image to Firebase Storage...');

          imageUrl = await ImageService.uploadProductImage(
            imageFile: _selectedImage!,
            userId: authProvider.currentUser!.id,
            productName: _nameController.text.trim(),
          );

          print('✅ Image uploaded: $imageUrl');
        } catch (e) {
          print('❌ Image upload failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final newProduct = Product(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        imageUrl: imageUrl, // Using uploaded or manual URL
        sellerId: authProvider.currentUser!.id,
        category: _selectedCategory,
        quantity: int.parse(_quantityController.text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('📦 Creating product: ${newProduct.name}');
      print('👤 Seller ID: ${newProduct.sellerId}');
      print('🖼️ Image: ${newProduct.imageUrl}');

      final success = await productProvider.addProduct(newProduct);

      print('📤 Add product result: $success');
      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          print('✅ Product added successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product listed successfully with image!'),
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
          setState(() {
            _selectedCategory = 'seeds';
            _selectedImage = null;
          });
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
}
