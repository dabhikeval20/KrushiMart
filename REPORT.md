# KrushiMart App - Lab Report (Labs 9-11)

## Student Information
- **Name**: [Your Name]
- **Roll Number**: [Your Roll Number]
- **Course**: Mobile Application Development (MAD)
- **Semester**: 6
- **Subject**: Flutter Development

## Project Overview
KrushiMart is a Flutter-based marketplace application designed for agricultural products. The app supports two user roles: Buyers and Sellers, with features for product listing, browsing, and purchasing. This report covers the implementation of three advanced features: API Integration (Lab 9), Notifications (Lab 10), and Image Upload (Lab 11).

## Lab 9: API Integration with FakeStore API

### Objective
Integrate external API data into the KrushiMart app to display products from FakeStore API, demonstrating REST API consumption and JSON parsing in Flutter.

### Implementation Details

#### Dependencies Added
```yaml
dependencies:
  http: ^1.2.1
```

#### Service Layer: ApiService
```dart
class ApiService {
  static const String _fakeStoreApi = 'https://fakestoreapi.com';
  
  Future<List<ApiProduct>> fetchProducts() async {
    try {
      final uri = Uri.parse('$_fakeStoreApi/products');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('API request timed out'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        final products = data.map((item) => 
          ApiProduct.fromJson(item as Map<String, dynamic>)
        ).toList();
        return products;
      } else {
        throw Exception('Failed to fetch products. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  Future<List<ApiProduct>> fetchProductsByCategory(String category) async {
    final uri = Uri.parse('$_fakeStoreApi/products/category/$category');
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data.map((item) => 
        ApiProduct.fromJson(item as Map<String, dynamic>)
      ).toList();
    } else {
      throw Exception('Failed to fetch $category products');
    }
  }

  Future<ApiProduct> fetchProductById(int productId) async {
    final uri = Uri.parse('$_fakeStoreApi/products/$productId');
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return ApiProduct.fromJson(data);
    } else {
      throw Exception('Product not found');
    }
  }

  Future<List<String>> fetchCategories() async {
    final uri = Uri.parse('$_fakeStoreApi/products/categories');
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data.map((item) => item as String).toList();
    } else {
      throw Exception('Failed to fetch categories');
    }
  }
}
```

#### Data Model: ApiProduct
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

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
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
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'image': image,
      'category': category,
      'rating': {'rate': rating, 'count': ratingCount},
    };
  }
}
```

#### UI Implementation
- Created `ApiProductListScreen` to display products in a grid layout
- Added category filtering functionality
- Implemented product details screen with full product information
- Added loading states and error handling

### Key Features
1. **Product Listing**: Grid view of all FakeStore products
2. **Category Filtering**: Filter products by electronics, jewelry, clothing, etc.
3. **Product Details**: Detailed view with image, description, rating, and price
4. **Error Handling**: Network timeouts, invalid responses, and user feedback
5. **Loading States**: Progress indicators during API calls

### Challenges Faced
- JSON parsing with nullable fields
- Handling network timeouts and errors
- Maintaining consistent UI state during async operations

## Lab 10: Notifications (Local & Push)

### Objective
Implement comprehensive notification system using local notifications and Firebase Cloud Messaging (FCM) for real-time push notifications.

### Implementation Details

#### Dependencies Added
```yaml
dependencies:
  flutter_local_notifications: ^14.1.0
  firebase_messaging: ^14.7.10
  timezone: ^0.9.2
```

#### Service Layer: NotificationService
```dart
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'krushimart_notifications',
    'KrushiMart Notifications',
    description: 'Notifications for KrushiMart users',
    importance: Importance.high,
  );

  static Future<void> init() async {
    // Initialize timezone
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Etc/UTC'));

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationPayload(response.payload);
      },
    );

    // Create notification channel for Android
    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // Request FCM permissions
    if (!kIsWeb) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Configure foreground presentation
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle FCM messages
    FirebaseMessaging.onMessage.listen((message) {
      _showMessageInForeground(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessageNavigation(message);
    });
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  static Future<void> scheduleDailyReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9, // 9 AM
      0,
    ).add(const Duration(days: 1));

    await _localNotifications.zonedSchedule(
      100,
      'KrushiMart Reminder',
      'Check new products and offers today.',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  static Future<void> _showMessageInForeground(RemoteMessage message) async {
    final title = message.notification?.title ?? 'New KrushiMart update';
    final body = message.notification?.body ?? 'Tap to see the latest product.';
    final payload = message.data['productId'];
    await showLocalNotification(title: title, body: body, payload: payload);
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    final payload = message.data['productId'];
    if (payload != null && payload.isNotEmpty) {
      _handleNotificationPayload(payload);
    }
  }

  static void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;

    final productId = int.tryParse(payload);
    if (productId == null) return;

    _navigateToProductDetail(productId);
  }

  static Future<void> _navigateToProductDetail(int productId) async {
    final apiService = ApiService();
    try {
      final product = await apiService.fetchProductById(productId);
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      navigator.push(
        MaterialPageRoute(
          builder: (context) => ApiProductDetailsScreen(product: product),
        ),
      );
    } catch (e) {
      debugPrint('Notification navigation failed: $e');
    }
  }
}
```

### Key Features
1. **Local Notifications**: Immediate notifications for user actions
2. **Scheduled Notifications**: Daily reminders at 9 AM
3. **Push Notifications**: Real-time FCM messages
4. **Foreground Handling**: Display notifications when app is open
5. **Deep Linking**: Navigate to product details from notifications
6. **Platform Support**: Android and iOS compatibility

### Firebase Configuration
- Added FCM configuration in `firebase_options.dart`
- Updated `AndroidManifest.xml` for notification permissions
- Configured notification channels for Android

### Challenges Faced
- Handling different notification states (foreground/background/terminated)
- Timezone management for scheduled notifications
- Deep linking and navigation from notification taps
- Platform-specific permission handling

## Lab 11: Image Upload with Camera/Gallery

### Objective
Implement image capture and upload functionality using device camera/gallery and Firebase Storage for product images.

### Implementation Details

#### Dependencies Added
```yaml
dependencies:
  image_picker: ^1.0.4
  firebase_storage: ^13.1.0
```

#### Service Layer: ImageService
```dart
class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      throw Exception('Failed to capture image from camera: $e');
    }
  }

  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      throw Exception('Failed to select image from gallery: $e');
    }
  }

  static Future<String> uploadProductImage({
    required File imageFile,
    required String userId,
    required String productName,
  }) async {
    try {
      // Create unique file path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'product_${userId}_$timestamp.jpg';
      final ref = _storage.ref().child('products/$userId/$fileName');

      // Upload file
      await ref.putFile(imageFile);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Upload failed: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<void> deleteProductImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Non-critical operation
    }
  }

  static Future<String> replaceProductImage({
    required File newImageFile,
    required String? oldImageUrl,
    required String userId,
    required String productName,
  }) async {
    try {
      // Delete old image if exists
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteProductImage(oldImageUrl);
      }

      // Upload new image
      final newImageUrl = await uploadProductImage(
        imageFile: newImageFile,
        userId: userId,
        productName: productName,
      );

      return newImageUrl;
    } catch (e) {
      rethrow;
    }
  }
}
```

#### UI Implementation: Enhanced AddProductScreen
```dart
class _AddProductScreenState extends State<AddProductScreen> {
  // Image-related state
  File? _selectedImage;

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

  void _handleAddProduct() async {
    // ... existing validation code ...

    // Upload image to Firebase Storage if selected
    String imageUrl = _imageUrlController.text.trim();
    if (_selectedImage != null) {
      try {
        imageUrl = await ImageService.uploadProductImage(
          imageFile: _selectedImage!,
          userId: authProvider.currentUser!.id,
          productName: _nameController.text.trim(),
        );
      } catch (e) {
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
      // ... other fields ...
      imageUrl: imageUrl, // Using uploaded or manual URL
      // ... other fields ...
    );

    final success = await productProvider.addProduct(newProduct);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product listed successfully with image!'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form including image
        setState(() {
          _selectedImage = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add product. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

### Key Features
1. **Camera Integration**: Capture images directly from device camera
2. **Gallery Selection**: Choose images from device gallery
3. **Image Preview**: Live preview of selected images
4. **Firebase Storage**: Secure cloud storage for product images
5. **Fallback URL**: Option to use direct image URLs
6. **Error Handling**: Comprehensive error handling for all operations
7. **Image Compression**: Automatic quality optimization (80%)

### Firebase Storage Structure
```
products/
  {userId}/
    product_{userId}_{timestamp}.jpg
```

### Challenges Faced
- Permission handling for camera and gallery access
- Image compression and optimization
- Firebase Storage security rules
- Handling large image files
- Memory management for image files

## Overall Project Summary

### Technologies Used
- **Flutter**: Cross-platform mobile development
- **Firebase**: Authentication, Firestore, Storage, Messaging
- **HTTP**: REST API communication
- **Provider**: State management
- **Image Picker**: Camera and gallery access
- **Local Notifications**: Scheduled notifications
- **Timezone**: Time zone handling

### Key Learnings
1. **API Integration**: RESTful API consumption, JSON parsing, error handling
2. **Notifications**: Local and push notification implementation, FCM integration
3. **Image Handling**: Camera/gallery access, image upload to cloud storage
4. **Firebase Services**: Multiple Firebase services integration
5. **State Management**: Provider pattern for complex app state
6. **Error Handling**: Comprehensive error handling and user feedback
7. **UI/UX**: Material Design implementation, responsive layouts

### Testing & Validation
- All features tested on Android emulator
- API endpoints validated with real data
- Notification permissions and delivery tested
- Image upload and storage verified
- Form validation and error states confirmed

### Future Enhancements
- Offline data synchronization
- Advanced image editing features
- Push notification analytics
- Multi-language support
- Advanced search and filtering

---

**Declaration**: I hereby declare that the above implementation is my own work and has been done as part of the Mobile Application Development course requirements.

**Date**: [Current Date]  
**Signature**: ___________________________