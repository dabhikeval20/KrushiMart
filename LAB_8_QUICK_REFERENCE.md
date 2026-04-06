# LAB 8 – QUICK REFERENCE GUIDE
## Copy-Paste Ready Code & Visual Flows

---

## 🔐 SESSION MANAGEMENT FLOW

### Step 1: Save Session After Login
```dart
// In LoginScreen._handleLogin()

Future<bool> success = await authProvider.loginUser(
  email: _emailController.text,
  password: _passwordController.text,
);

if (success) {
  // Session is saved automatically in loginUser()
  print('✅ Session saved');
  
  // Navigate to dashboard
  Navigator.pushReplacementNamed(context, '/buyer_dashboard');
}
```

### Step 2: Restore Session on App Startup
```dart
// In main.dart - AuthWrapper

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // If user is authenticated, show dashboard
        if (authProvider.isAuthenticated) {
          return const BuyerDashboardScreen();
        }
        
        // Otherwise show login
        return const LoginScreen();
      },
    );
  }
}

// Firebase auth automatically restores session
// (built into FirebaseAuth.authStateChanges())
```

### Step 3: Clear Session on Logout
```dart
// In Dashboard._handleLogout()

void _handleLogout() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Confirm logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            
            // Logout clears session automatically
            Provider.of<AuthProvider>(context, listen: false).logout();
            
            // Navigate back to login (prevent back button)
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

## 📤 PASS DATA BETWEEN SCREENS

### Scenario 1: Product List → Product Details

#### Step A: Navigate with Product Data
```dart
// In ProductListScreen.dart
// When user clicks a product card

GestureDetector(
  onTap: () {
    // 📤 PASS PRODUCT TO DETAILS SCREEN
    Navigator.pushNamed(
      context,
      '/product_details',
      arguments: product,  // ← Pass product object here
    );
  },
  child: ProductCard(product: product),
)
```

#### Step B: Receive Product Data
```dart
// In ProductDetailsScreen.dart

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
    
    // 📥 RECEIVE PRODUCT DATA SAFELY
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Product) {
        _product = args;
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_product == null) {
      return const Scaffold(body: Center(child: Text('No product found')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_product!.name)),
      body: Column(
        children: [
          Image.network(_product!.imageUrl),
          Text('₹${_product!.price}'),
          ElevatedButton(
            onPressed: () {
              // Add to cart, etc.
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }
}
```

---

### Scenario 2: Product List → Edit Product

#### Step A: Pass Product to Edit Screen
```dart
// In MyProductsScreen.dart (Seller)
// In edit button tap

PopupMenuButton<String>(
  onSelected: (value) {
    if (value == 'edit') {
      // 📤 PASS PRODUCT TO EDIT SCREEN
      Navigator.pushNamed(
        context,
        '/edit_product',
        arguments: product,  // ← Pass entire product
      );
    }
  },
  itemBuilder: (context) => [
    const PopupMenuItem(
      value: 'edit',
      child: Text('Edit'),
    ),
  ],
)
```

#### Step B: Pre-fill Edit Form
```dart
// In EditProductScreen.dart

class EditProductScreenState extends State<EditProductScreen> {
  Product? _product;
  bool _initialized = false;

  late TextEditingController _nameController;
  late TextEditingController _priceController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 📥 RECEIVE AND PRE-FILL
    if (!_initialized) {
      _product = ModalRoute.of(context)?.settings.arguments as Product?;
      
      if (_product != null) {
        // Pre-fill controllers with existing data
        _nameController = TextEditingController(text: _product!.name);
        _priceController = TextEditingController(text: '${_product!.price}');
      }
      
      _initialized = true;
    }
  }

  void _handleSave() async {
    if (_product == null) return;

    // Create updated product with SAME ID
    final updatedProduct = _product!.copyWith(
      name: _nameController.text,
      price: double.parse(_priceController.text),
      updatedAt: DateTime.now(),
    );

    // Update in Firestore
    await Provider.of<ProductProvider>(context, listen: false)
        .updateProduct(updatedProduct);

    // Go back to previous screen
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSave,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎨 STATE MANAGEMENT PATTERN

###Example 1: Using Consumer to Listen to Auth Changes
```dart
// In any screen that needs to show current user

Widget build(BuildContext context) {
  return Consumer<AuthProvider>(
    builder: (context, authProvider, _) {
      // This widget rebuilds when authProvider.notifyListeners() is called
      
      if (authProvider.isLoading) {
        return const CircularProgressIndicator();
      }

      if (authProvider.currentUser == null) {
        return const Text('Not logged in');
      }

      // Show user data
      return Text('Welcome, ${authProvider.currentUser!.name}');
    },
  );
}
```

### Example 2: Using Provider.of() for One-Time Operations
```dart
// In event handler (like button press)

void _handleAddProduct() {
  // Use listen: false because we don't need to rebuild on every change
  final productProvider = Provider.of<ProductProvider>(
    context,
    listen: false,
  );

  // Call method once
  productProvider.addProduct(product);

  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Product added!')),
  );
}
```

---

## 🔄 NAVIGATION PATTERNS

### Pattern 1: Navigate with Named Route
```dart
// Simple navigation
Navigator.pushNamed(context, '/product_details');

// With arguments
Navigator.pushNamed(
  context,
  '/product_details',
  arguments: product,
);
```

### Pattern 2: Navigate with Data and Get Result
```dart
// Push and wait for result
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const EditProductScreen()),
);

// Handle result
if (result != null && result is Product) {
  print('Updated product: ${result.name}');
  setState(() {
    // Update UI with returned data
  });
}

// In EditProductScreen, return result
Navigator.pop(context, updatedProduct);
```

### Pattern 3: Replace Entire Screen (No Back Button)
```dart
// ✅ After login - user cannot go back to login
Navigator.pushReplacementNamed(context, '/buyer_dashboard');

// ✅ After logout - user cannot go back to dashboard
Navigator.pushReplacementNamed(context, '/login');
```

---

## 📋 COMPLETE FLOW EXAMPLES

### Flow 1: Complete Login to Dashboard Journey

```
┌─────────────────────────────────────────────────────┐
│ 1. User opens app                                   │
│    AuthWrapper checks: isAuthenticated?             │
│    ├─ No  → Show LoginScreen                        │
│    └─ Yes → Show Dashboard                          │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│ 2. User enters email/password & clicks LOGIN        │
│    LoginScreen._handleLogin()                       │
│    ├─ Call: authProvider.loginUser(email, pass)   │
│    ├─ Inside loginUser():                          │
│    │  ├─ Firebase Auth.signInWithEmailAndPassword()│
│    │  ├─ Load user from Firestore                  │
│    │  ├─ Call: saveSessionData()                   │
│    │  └─ Return true                               │
│    └─ Back in _handleLogin()                       │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│ 3. Navigate to Dashboard                            │
│    Navigator.pushReplacementNamed(                  │
│      context,                                       │
│      '/buyer_dashboard'  // or '/seller_dashboard' │
│    )                                                │
│    - No back button (pushReplacement)               │
│    - Cannot go back to login                        │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│ 4. User navigates through app                       │
│    Product List → Click product                     │
│    ├─ Navigator.pushNamed(                          │
│    │   '/product_details',                          │
│    │   arguments: product  ← Pass data             │
│    │ )                                              │
│    └─ Has back button (push, not pushReplacement)  │
│                                                     │
│    Product Details receives data                    │
│    ├─ didChangeDependencies() called              │
│    ├─ ModalRoute.of(context).settings.arguments    │
│    └─ Safe access to product data                  │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│ 5. User clicks Logout                               │
│    Dashboard._handleLogout()                        │
│    ├─ Show confirmation dialog                      │
│    ├─ Call: authProvider.logout()                   │
│    │  ├─ Firebase Auth.signOut()                    │
│    │  ├─ Call: clearSessionData()                   │
│    │  └─ Set: _currentUser = null                   │
│    ├─ Call: notifyListeners()                       │
│    └─ Navigate:                                     │
│        Navigator.pushReplacementNamed(              │
│          context,                                   │
│          '/login'  ← Back to login                  │
│        )                                            │
│        - No back button                             │
│        - Session cleared from device                │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│ 6. User closes and reopens app                      │
│    AuthWrapper checks: isAuthenticated?             │
│    ├─ Firebase session gone (logged out)            │
│    ├─ Is null → Show LoginScreen                    │
│    └─ User must login again                         │
└─────────────────────────────────────────────────────┘
```

---

### Flow 2: Seller Add/Edit Product Journey

```
┌──────────────────────────────────────────────────┐
│ Seller Dashboard                                 │
│ ├─ Drawer: "Add Product" click                   │
│ └─ Navigation:                                   │
│    Navigator.pushNamed(context, '/add_product')  │
└──────────────────────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────────┐
│ Add Product Screen                               │
│ ├─ Fill form (name, price, etc.)                 │
│ ├─ Click "Publish"                               │
│ ├─ Call: productProvider.addProduct(product)     │
│ ├─ Inside addProduct():                          │
│ │  ├─ Save to Firestore                          │
│ │  ├─ Add to local list                          │
│ │  └─ Call: notifyListeners()  ← Rebuild UI     │
│ └─ Navigate back:                                │
│    Navigator.pop(context)  ← Has back button    │
└──────────────────────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────────┐
│ Seller Dashboard (rebuilt)                       │
│ ├─ New product appears in list                   │
│ ├─ (Listening to productProvider stream)         │
│ └─ User sees: "2 products total"                 │
└──────────────────────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────────┐
│ Seller clicks "My Products" in drawer            │
│ └─ Show list of seller's products                │
└──────────────────────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────────┐
│ Product List                                     │
│ ├─ StreamBuilder watching Firestore              │
│ ├─ Shows real-time product list                  │
│ └─ Click "Edit" popup menu button                │
└──────────────────────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────────┐
│ Edit Product Screen                              │
│ ├─ Receiving product data:                       │
│ │  Navigator.pushNamed(                          │
│ │    '/edit_product',                            │
│ │    arguments: product  ← PASS DATA            │
│ │  )                                              │
│ │                                                 │
│ │  didChangeDependencies() {                      │
│ │    _product = ModalRoute.of(context)            │
│ │             .settings.arguments as Product?     │
│ │  }                                              │
│ │                                                 │
│ ├─ Pre-fill form:                                │
│ │  _nameController = TextEditingController(       │
│ │    text: _product!.name                        │
│ │  )                                              │
│ │                                                 │
│ ├─ User changes data and clicks "Save"           │
│ │  updatedProduct = _product!.copyWith(           │
│ │    name: newName,                               │
│ │    price: newPrice,                             │
│ │    updatedAt: DateTime.now()                    │
│ │  )                                              │
│ │                                                 │
│ ├─ Call: productProvider.updateProduct()          │
│ │  ├─ Update Firestore (by product.id)            │
│ │  ├─ Update local list                           │
│ │  └─ Call: notifyListeners()                     │
│ │                                                 │
│ └─ Navigate back:                                │
│    Navigator.pop(context)                        │
└──────────────────────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────────┐
│ My Products List (rebuilt)                       │
│ ├─ Product shows with updated name                │
│ ├─ StreamBuilder rebuilds automatically           │
│ │  (listening to Firestore changes)               │
│ └─ Success! ✅                                    │
└──────────────────────────────────────────────────┘
```

---

## ⚡ QUICK COPY-PASTE SNIPPETS

### Snippet 1: Login with Session Save
```dart
void _handleLogin() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  final success = await authProvider.loginUser(
    email: _emailController.text,
    password: _passwordController.text,
  );
  
  if (success && mounted) {
    Navigator.pushReplacementNamed(context, '/buyer_dashboard');
  }
}
```

### Snippet 2: Pass Product Data
```dart
Navigator.pushNamed(
  context,
  '/product_details',
  arguments: product,
);
```

### Snippet 3: Receive Product Data
```dart
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_initialized) {
    _product = ModalRoute.of(context)?.settings.arguments as Product?;
    _initialized = true;
  }
}
```

### Snippet 4: Update Product (Save with ID)
```dart
final updatedProduct = _product!.copyWith(
  name: _nameController.text,
  price: double.parse(_priceController.text),
);
await productProvider.updateProduct(updatedProduct);
```

### Snippet 5: Logout with Session Clear
```dart
void _handleLogout() {
  Provider.of<AuthProvider>(context, listen: false).logout();
  Navigator.pushReplacementNamed(context, '/login');
}
```

### Snippet 6: Auto-Login (Session Restore)
```dart
// In AuthWrapper
if (authProvider.isAuthenticated) {
  return const BuyerDashboardScreen();
}
return const LoginScreen();
```

---

## 🎯 INTEGRATION CHECKLIST

- [ ] Add SharedPreferences to pubspec.yaml: `shared_preferences: ^2.2.2`
- [ ] Import in auth_provider.dart: `import 'package:shared_preferences/shared_preferences.dart';`
- [ ] Add session methods to AuthProvider
- [ ] Update loginUser() to call saveSessionData()
- [ ] Update logout() to call clearSessionData()
- [ ] Update registerUser() to call saveSessionData()
- [ ] Configure all routes in main.dart
- [ ] Create AuthWrapper with role-based routing
- [ ] Use didChangeDependencies() for route arguments
- [ ] Use pushReplacement for auth navigation
- [ ] Test complete login-logout flow
- [ ] Test product data passing
- [ ] Test session persistence (close/reopen app)
- [ ] Verify no back button after logout

---

**Ready to copy-paste!** 🚀✨
