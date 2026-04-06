# LAB 8 – APP NAVIGATION & STATE MANAGEMENT
## KrushiMart - Complete Implementation Guide

---

## 📋 TABLE OF CONTENTS

1. [Navigation Architecture](#navigation-architecture)
2. [State Management with Provider](#state-management-with-provider)
3. [Data Passing Between Screens](#data-passing-between-screens)
4. [Session Management](#session-management)
5. [Code Examples](#code-examples)
6. [Best Practices](#best-practices)

---

## NAVIGATION ARCHITECTURE

### App Navigation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      SPLASH SCREEN                          │
│              (Check authentication status)                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
         ┌─────────────┴──────────────────┐
         │                                │
         ▼                                ▼
    ┌──────────────┐            ┌────────────────────┐
    │ No Session   │            │ Session Found      │
    │ (First Login)│            │ (Restore Session)  │
    └──────────────┘            └────────────────────┘
         │                                │
         ▼                                ▼
    ┌──────────────┐            ┌────────────────────┐
    │ LOGIN SCREEN │────────────▶│ BUYER/SELLER       │
    │              │            │ DASHBOARD          │
    └──────────────┘            └────────────────────┘
         │                                │
         ▼                                ▼
    ┌──────────────┐            ┌────────────────────┐
    │REGISTRATION  │            │ ROLE-BASED SCREENS │
    │   SCREEN     │            │   (See below)      │
    └──────────────┘            └────────────────────┘
```

### BUYER FLOW (Complete Navigation Tree)

```
BUYER DASHBOARD (Home)
│
├─▶ BOTTOM NAV TAB 1: HOME
│   ├─▶ Product List Screen
│   │   ├─ Search by name
│   │   ├─ Filter by category
│   │   └─▶ [Product Details] ◀────┐
│   │       ├─ View full details   │
│   │       ├─ Add to cart          │
│   │       └─ View seller          │
│   │
│   └─▶ Cart Screen
│       ├─ View cart items
│       ├─ Update quantities
│       ├─ Remove items
│       └─▶ [Checkout]
│           ├─ Confirm order
│           └─ Show success
│
├─▶ BOTTOM NAV TAB 2: BROWSE
│   └─▶ Product List Screen (via category filter)
│       └─▶ [Product Details]
│
└─▶ BOTTOM NAV TAB 3: PROFILE
    ├─ View profile info
    ├─▶ Edit Profile Screen
    │   ├─ Update name
    │   ├─ Update phone
    │   ├─ Update location
    │   └─ Save changes
    ├─ View order history
    ├─ Settings
    └─ Logout
```

### SELLER FLOW (Complete Navigation Tree)

```
SELLER DASHBOARD (Home)
│
├─▶ DRAWER MENU ITEM 1: DASHBOARD
│   ├─ View stats (Total Products, Sales, Revenue)
│   ├─ Recent 3 products
│   └─▶ View all products
│
├─▶ DRAWER MENU ITEM 2: MY PRODUCTS
│   ├─▶ Product List (StreamBuilder - Real-time)
│   │   └─▶ [Edit Product] ◀────────────────┐
│   │       ├─ Pre-filled form              │
│   │       ├─ Update all fields            │
│   │       └─ Save changes (includes ID)   │
│   │
│   └─ Delete Product (with confirmation)
│
├─▶ DRAWER MENU ITEM 3: ADD PRODUCT
│   └─▶ Add Product Screen
│       ├─ Product Name (required)
│       ├─ Description (required)
│       ├─ Price (required)
│       ├─ Category (dropdown)
│       ├─ Quantity (required)
│       ├─ Image URL (optional)
│       └─ Publish Listing
│
├─▶ DRAWER MENU ITEM 4: PROFILE
│   ├─ View profile info
│   ├─▶ Edit Profile Screen
│   │   ├─ Update name
│   │   ├─ Update phone
│   │   ├─ Update location
│   │   └─ Save changes
│   ├─ Bank details (optional)
│   └─ Settings
│
└─▶ DRAWER MENU ITEM 5: LOGOUT
    └─ Clear all session data
```

---

## STATE MANAGEMENT WITH PROVIDER

### What is Provider?

**Provider** is a state management library that helps:
- **Centralize app state** in dedicated classes (Providers)
- **Notify listeners** when state changes
- **Rebuild UI automatically** when state updates
- **Reduce prop drilling** (passing data through multiple widgets)

### Why Use Provider?

✅ Simpler than Redux  
✅ Less boilerplate than BLoC  
✅ Built-in dependency injection  
✅ Excellent for small to medium apps  
✅ Great for real-time updates (Firebase)  

### Key Concepts

#### 1. **ChangeNotifier**
A class that notifies listeners when data changes.

```dart
class AuthProvider with ChangeNotifier {
  String _username = '';
  
  String get username => _username;
  
  void setUsername(String name) {
    _username = name;
    notifyListeners(); // Notify all listeners of change
  }
}
```

#### 2. **MultiProvider**
Provides multiple providers to the entire app.

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => ProductProvider()),
  ],
  child: MaterialApp(...),
)
```

#### 3. **Consumer**
Listen to provider changes and rebuild the widget.

```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    return Text('User: ${authProvider.currentUser?.name}');
  },
)
```

#### 4. **Provider.of()**
Access provider in non-widget code (listeners: false for performance).

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);
print(authProvider.currentUser?.email);
```

### AuthProvider - Centralized Authentication State

```dart
class AuthProvider with ChangeNotifier {
  firebase_auth.FirebaseAuth _auth;
  user_model.User? _currentUser;
  bool _isLoading = false;
  
  // GETTERS - UI reads these values
  user_model.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  
  // METHODS - Update state
  Future<bool> loginUser(String email, String password) async {
    _isLoading = true;
    notifyListeners(); // Rebuild UI showing loading spinner
    
    try {
      // Call Firebase Auth
      final result = await _auth.signInWithEmailAndPassword(...);
      
      _isLoading = false;
      notifyListeners(); // Rebuild UI with user data
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners(); // Rebuild UI with error
      return false;
    }
  }
  
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners(); // Rebuild UI, return to login
  }
}
```

### ProductProvider - Product CRUD State

```dart
class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  
  List<Product> get products => _products;
  
  // Real-time stream (for StreamBuilder)
  Stream<List<Product>> getProducts() {
    return _firestore
        .collection('products')
        .snapshots()
        .map((snapshot) {
          _products = snapshot.docs
              .map((doc) => Product.fromMap(doc.data()))
              .toList();
          notifyListeners();
          return _products;
        });
  }
  
  // CRUD Operations
  Future<void> addProduct(Product product) async {
    final docRef = await _firestore.collection('products').add(product.toMap());
    product = product.copyWith(id: docRef.id);
    _products.add(product);
    notifyListeners(); // Update UI
  }
  
  Future<void> updateProduct(Product product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .update(product.toMap());
    
    // Update local list
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
      notifyListeners(); // Update UI
    }
  }
  
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
    _products.removeWhere((p) => p.id == productId);
    notifyListeners(); // Update UI
  }
}
```

---

## DATA PASSING BETWEEN SCREENS

### Method 1: Named Routes with Arguments

#### Navigate TO a screen with data

```dart
// Push to Product Details with product object
Navigator.pushNamed(
  context,
  '/product_details',
  arguments: product, // Pass the product
);
```

#### Receive data IN the screen

```dart
class ProductDetailsScreen extends StatefulWidget {
  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Product? _product;
  bool _initialized = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Safe to call ModalRoute here (after initState)
    if (!_initialized) {
      _product = ModalRoute.of(context)!.settings.arguments as Product?;
      _initialized = true;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_product == null) {
      return const Scaffold(body: Center(child: Text('No product data')));
    }
    
    return Scaffold(
      appBar: AppBar(title: Text(_product!.name)),
      body: Column(
        children: [
          Image.network(_product!.imageUrl),
          Text('₹${_product!.price}'),
        ],
      ),
    );
  }
}
```

### Method 2: Direct Constructor Parameters

```dart
// Pass data via constructor
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EditProductScreen(product: product),
  ),
);

// Receive in screen
class EditProductScreen extends StatefulWidget {
  final Product product;
  
  const EditProductScreen({required this.product});
  
  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}
```

### Method 3: Return Data from Screen

```dart
// Push and wait for result
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => EditProductScreen()),
);

if (result != null) {
  print('Updated product: ${result.name}');
  // Update UI with returned data
}

// In EditProductScreen, return the result
Navigator.pop(context, updatedProduct);
```

---

## SESSION MANAGEMENT

### What is Session Management?

**Session Management** = Remembering if a user is logged in, so they don't have to login every time they open the app.

### How It Works

1. User logs in → Save credentials to device storage (**SharedPreferences**)
2. App restarts → Check if credentials exist → Auto-login
3. User logs out → Clear credentials from device storage

### Implementation

#### Step 1: Add SharedPreferences Dependency

```yaml
# pubspec.yaml
dependencies:
  shared_preferences: ^2.2.2
```

#### Step 2: Save Login State

```dart
Future<void> saveSessionData() async {
  final prefs = await SharedPreferences.getInstance();
  
  if (_currentUser != null) {
    // Save user data
    await prefs.setString('user_id', _currentUser!.id);
    await prefs.setString('user_email', _currentUser!.email);
    await prefs.setString('user_role', _currentUser!.role.name);
    await prefs.setBool('is_logged_in', true);
    
    print('💾 Session saved');
  }
}

// Call after successful login
await loginUser(email, password);
await saveSessionData(); // Add this line
```

#### Step 3: Restore Login State on App Startup

```dart
Future<bool> restoreSessionData() async {
  final prefs = await SharedPreferences.getInstance();
  
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  
  if (isLoggedIn) {
    final userId = prefs.getString('user_id');
    if (userId != null) {
      // Load user from Firestore
      await _loadUserData(userId);
      print('📖 Session restored');
      return true;
    }
  }
  
  return false;
}
```

#### Step 4: Clear Session on Logout

```dart
Future<void> logout() async {
  await _auth.signOut();
  
  // Clear SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('user_id');
  await prefs.remove('user_email');
  await prefs.remove('user_role');
  await prefs.remove('is_logged_in');
  
  _currentUser = null;
  notifyListeners();
  
  print('✅ Logged out and session cleared');
}
```

### Modify AuthWrapper for Auto-Login

```dart
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show splash while checking auth state
        if (authProvider.isLoading) {
          return const SplashScreen();
        }
        
        // If authenticated, show dashboard
        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          final role = authProvider.currentUser!.role;
          
          if (role == UserRole.seller) {
            return const SellerDashboardScreen();
          } else {
            return const BuyerDashboardScreen();
          }
        }
        
        // Otherwise show login
        return const LoginScreen();
      },
    );
  }
}
```

---

## CODE EXAMPLES

### Example 1: Complete Navigation from Login to Dashboard

```dart
// LOGIN SCREEN
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  void _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Call login method
    final success = await authProvider.loginUser(
      _emailController.text,
      _passwordController.text,
    );
    
    if (success) {
      // Save session
      await authProvider.saveSessionData();
      
      // Navigate to dashboard (no back button)
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/buyer_dashboard');
      }
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Column(
        children: [
          TextField(controller: _emailController),
          TextField(controller: _passwordController),
          ElevatedButton(
            onPressed: _handleLogin,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
```

### Example 2: Pass Product to Details Screen

```dart
// PRODUCT LIST SCREEN
class ProductListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        return StreamBuilder<List<Product>>(
          stream: productProvider.getProducts(),
          builder: (context, snapshot) {
            final products = snapshot.data ?? [];
            
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                
                return GestureDetector(
                  onTap: () {
                    // Navigate to details with product data
                    Navigator.pushNamed(
                      context,
                      '/product_details',
                      arguments: product,
                    );
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Image.network(product.imageUrl),
                        Text(product.name),
                        Text('₹${product.price}'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// PRODUCT DETAILS SCREEN - Receive product data
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key});
  
  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Product? _product;
  bool _initialized = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_initialized) {
      // Get product from route arguments
      _product = ModalRoute.of(context)!.settings.arguments as Product?;
      _initialized = true;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_product == null) {
      return const Scaffold(
        body: Center(child: Text('No product found')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: Text(_product!.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(_product!.imageUrl),
            Text('₹${_product!.price}'),
            Text(_product!.description),
            ElevatedButton(
              onPressed: () {
                // Add to cart or buy
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added "${_product!.name}" to cart'),
                  ),
                );
              },
              child: const Text('Add to Cart'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example 3: Edit Product (Pass Product ID)

```dart
// MY PRODUCTS LIST - Edit action
PopupMenuButton<String>(
  onSelected: (value) {
    if (value == 'edit') {
      // Navigate to edit screen with product
      Navigator.pushNamed(
        context,
        '/edit_product',
        arguments: product, // Pass entire product object
      );
    }
  },
  itemBuilder: (context) => [
    const PopupMenuItem(value: 'edit', child: Text('Edit')),
  ],
)

// EDIT PRODUCT SCREEN - Receive and update product
class EditProductScreen extends StatefulWidget {
  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  Product? _product;
  late TextEditingController _nameController;
  bool _initialized = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_initialized) {
      _product = ModalRoute.of(context)!.settings.arguments as Product?;
      
      // Pre-fill form with product data
      _nameController = TextEditingController(text: _product?.name ?? '');
      
      _initialized = true;
    }
  }
  
  void _handleSaveProduct() async {
    if (_product == null) return;
    
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    
    // Create updated product with same ID
    final updatedProduct = _product!.copyWith(
      name: _nameController.text,
      // ... other fields ...
    );
    
    // Update in Firestore
    await productProvider.updateProduct(updatedProduct);
    
    // Pop back to previous screen
    if (mounted) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated!')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: TextField(controller: _nameController),
    );
  }
}
```

### Example 4: Prevent Back Navigation After Logout

```dart
// LOGOUT HANDLER in Dashboard
void _handleLogout() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  // Show confirmation dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            
            // Logout
            authProvider.logout();
            
            // Navigate to login (prevent going back)
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}
```

---

## BEST PRACTICES

### 1. Navigation Best Practices

✅ **Use Named Routes** for better readability
```dart
Navigator.pushNamed(context, '/product_details', arguments: product);
```

❌ **Avoid** direct widget construction in navigation
```dart
// Bad
Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen()));

// Good
Navigator.pushNamed(context, '/product_details', arguments: product);
```

✅ **Use `pushReplacement`** to prevent back navigation
```dart
// After login, don't allow back navigation
Navigator.pushReplacementNamed(context, '/buyer_dashboard');
```

✅ **Use `didChangeDependencies`** for safe route argument access
```dart
void didChangeDependencies() {
  super.didChangeDependencies();
  final data = ModalRoute.of(context)!.settings.arguments;
}
```

### 2. State Management Best Practices

✅ **Use Provider for global state** (auth, theme, settings)
```dart
final authProvider = Provider.of<AuthProvider>(context);
print(authProvider.currentUser?.email);
```

✅ **Use `listen: false`** in event handlers
```dart
final provider = Provider.of<AuthProvider>(context, listen: false);
provider.login(email, password);
```

✅ **Use StreamBuilder** for real-time updates
```dart
StreamBuilder<List<Product>>(
  stream: productProvider.getProducts(),
  builder: (context, snapshot) {
    return ListView(...);
  },
)
```

### 3. Session Management Best Practices

✅ **Save session** after every login
```dart
await authProvider.loginUser(email, password);
await authProvider.saveSessionData();
```

✅ **Clear session** on logout
```dart
await authProvider.logout();
Navigator.pushReplacementNamed(context, '/login');
```

✅ **Use SharedPreferences** only for non-sensitive data
```dart
// ✅ OK
await prefs.setBool('is_logged_in', true);
await prefs.setString('user_email', email);

// ❌ Never store passwords!
await prefs.setString('password', password); // WRONG
```

### 4. Performance Tips

✅ **Use `Consumer` with specific providers**
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    return Text(authProvider.currentUser?.name ?? '');
  },
)
```

✅ **Avoid rebuilding entire tree**
```dart
// Good - only rebuild specific widget
Consumer<ProductProvider>(
  builder: (context, productProvider, child) {
    return child!; // Child doesn't rebuild
  },
  child: ExpensiveWidget(),
)
```

### 5. Error Handling

✅ **Always handle errors in navigation**
```dart
try {
  if (mounted) {
    Navigator.pushNamed(context, '/dashboard');
  }
} catch (e) {
  print('Navigation error: $e');
}
```

✅ **Check `mounted` before setState**
```dart
if (mounted) {
  setState(() => _isLoading = false);
}
```

---

## NAVIGATION FLOW DIAGRAM (mermaid)

```
App Start
   │
   ├─▶ Check SessionData in SharedPreferences
   │   ├─ If logged in → Load user from Firestore
   │   └─ If not → Show login screen
   │
   ├─▶ AuthWrapper Consumer
   │   ├─ Show SplashScreen while loading
   │   ├─ isAuthenticated = false → LoginScreen
   │   └─ isAuthenticated = true → DashboardScreen
   │
   ├─▶ User Login/Register
   │   ├─ Email + Password ▶ Firebase Auth
   │   ├─ Create user doc ▶ Firestore users
   │   ├─ Save session ▶ SharedPreferences
   │   └─ Navigate ▶ Dashboard
   │
   ├─▶ BUYER DASHBOARD
   │   ├─ ProductList ▶ [ProductDetails] ◀─ Pass product
   │   ├─ CartScreen ▶ [Checkout]
   │   └─ ProfileScreen ▶ [EditProfile]
   │
   ├─▶ SELLER DASHBOARD
   │   ├─ Dashboard Stats
   │   ├─ MyProducts ▶ [EditProduct] ◀─ Pass product
   │   ├─ AddProduct ▶ [Success]
   │   └─ ProfileScreen ▶ [EditProfile]
   │
   └─▶ User Logout
       ├─ Clear Firebase Auth
       ├─ Clear SharedPreferences session
       └─ Navigate ▶ LoginScreen (pushReplacement)
```

---

## SUMMARY

### Key Concepts

1. **Navigation**: Push, Pop, PushReplacement for screen transitions
2. **State Management**: Provider for centralized state and automatic UI updates
3. **Data Passing**: Route arguments with ModalRoute in didChangeDependencies()
4. **Session Management**: SharedPreferences for persistent login state

### Implementation Checklist

- [x] Add SharedPreferences to pubspec.yaml
- [x] Implement session save/restore in AuthProvider
- [x] Use named routes for all navigation
- [x] Pass data via route arguments
- [x] Receive data in didChangeDependencies()
- [x] Use Consumer/Provider.of for state access
- [x] Clear session on logout
- [x] Prevent back navigation after logout (pushReplacement)

---

## REFERENCE CODE SNIPPETS

### Login Flow
```dart
// Step 1: User enters email/password
// Step 2: Call auth provider login
await authProvider.loginUser(email, password);

// Step 3: Save session
await authProvider.saveSessionData();

// Step 4: Navigate to dashboard
Navigator.pushReplacementNamed(context, '/buyer_dashboard');
```

### Product List to Details
```dart
// In product list
Navigator.pushNamed(
  context,
  '/product_details',
  arguments: product,
);

// In product details screen
Product? _product = ModalRoute.of(context)!.settings.arguments as Product?;
```

### Edit Product
```dart
// Pass product to edit screen
Navigator.pushNamed(context, '/edit_product', arguments: product);

// Update product
final updatedProduct = _product!.copyWith(name: 'New Name');
await productProvider.updateProduct(updatedProduct);

// Pop back
Navigator.pop(context);
```

---

**LAB 8 Complete!** 🎓✨

This guide covers all navigation and state management requirements for a production-ready Flutter app.
