# LAB 9: API Integration - GET Requests & Data Display

## 📚 Learning Objectives

By the end of this lab, you will:
1. Understand REST API concepts and HTTP methods
2. Implement GET requests to fetch data from an external API
3. Parse JSON responses into Dart objects
4. Manage API loading, error, and empty states
5. Display API data in a Flutter UI using Provider state management
6. Handle network errors and timeouts gracefully

---

## 🔗 What is an API?

### REST API Basics
- **REST** = Representational State Transfer
- **API** = Application Programming Interface
- A REST API allows applications to communicate over HTTP/HTTPS
- Uses standard HTTP methods: GET, POST, PUT, DELETE, PATCH

### HTTP Methods
| Method | Purpose | Example |
|--------|---------|---------|
| **GET** | Retrieve data | Fetch list of products |
| **POST** | Create new data | Add a new product |
| **PUT** | Update existing data | Modify a product |
| **DELETE** | Remove data | Delete a product |

### Request/Response Cycle
```
┌─────────────┐         HTTP REQUEST          ┌─────────────┐
│   CLIENT    │ ──────────────────────────>   │   SERVER    │
│  (Flutter   │  GET /api/products            │  (API)      │
│   App)      │                               │             │
└─────────────┘         HTTP RESPONSE         └─────────────┘
                <──────────────────────────
                 200 OK
                 [{"id": 1, "title": "..."},
                  {"id": 2, "title": "..."}]
```

---

## 📦 JSON (JavaScript Object Notation)

### What is JSON?
- Lightweight data format
- Human-readable
- Used extensively in APIs
- Maps easily to Dart objects

### JSON Structure
```json
{
  "id": 1,
  "title": "Laptop",
  "price": 999.99,
  "description": "High-performance laptop",
  "image": "https://...",
  "category": "electronics",
  "rating": 4.5,
  "ratingCount": 128
}
```

### Dart Object Mapping
```dart
// JSON from API
Map<String, dynamic> json = {
  "id": 1,
  "title": "Laptop",
  "price": 999.99,
  ...
};

// Convert to Dart object
ApiProduct product = ApiProduct.fromJson(json);
```

---

## 🌐 FakeStore API

### Why FakeStore?
- **Free** - No authentication required
- **Reliable** - Stable mock data
- **Educational** - Perfect for learning
- **Real-world** - Mimics production APIs

### Base URL
```
https://fakestoreapi.com
```

### Available Endpoints

#### 1. Get All Products
```http
GET https://fakestoreapi.com/products
```
**Response:** Array of 20 products

#### 2. Get Product by ID
```http
GET https://fakestoreapi.com/products/1
```
**Response:** Single product object

#### 3. Get Products by Category
```http
GET https://fakestoreapi.com/products/category/{category}
```
**Response:** Products matching category

#### 4. Get All Categories
```http
GET https://fakestoreapi.com/products/categories
```
**Response:** Array of category names

### Available Categories
```
- electronics
- jewelery
- men's clothing
- women's clothing
```

### Example Response
```json
[
  {
    "id": 1,
    "title": "Fjallraven - Foldsack No. 1 Backpack",
    "price": 109.95,
    "description": "Your perfect pack for everyday use...",
    "category": "electronics",
    "image": "https://fakestoreapi.com/img/81fPKd-2AzL._AC_SL1500_.jpg",
    "rating": {
      "rate": 3.9,
      "count": 120
    }
  }
]
```

---

## 🏗️ Implementation Architecture

### Layered Architecture
```
┌─────────────────────────┐
│   UI LAYER              │  ← api_products_screen.dart
│   (Screens & Widgets)   │      api_categories_screen.dart
└────────────┬────────────┘
             │
┌────────────▼──────────────┐
│   STATE MANAGEMENT        │  ← product_provider.dart
│   (Provider Pattern)      │    (ChangeNotifier)
└────────────┬──────────────┘
             │
┌────────────▼──────────────┐
│   SERVICE LAYER           │  ← api_service.dart
│   (HTTP Requests)         │    (API calls)
└────────────┬──────────────┘
             │
┌────────────▼──────────────┐
│   MODEL LAYER             │  ← api_product.dart
│   (Data Classes)          │    (fromJson, toJson)
└─────────────────────────┘
     │
┌────────────────────────┐
│   EXTERNAL API          │
│   (FakeStore API)       │
└────────────────────────┘
```

---

## 💾 Dependencies

### pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0        # State management
  http: ^1.2.1            # HTTP requests
  firebase_core: ^2.16.0  # Firebase (from LAB 8)
  cloud_firestore: ^4.13.0 # Firestore (from LAB 8)
  shared_preferences: ^2.1.1 # Session management (from LAB 8)
```

---

## 🔧 Project Structure

### Files Created/Modified for LAB 9

```
lib/
├── models/
│   ├── api_product.dart          ✨ NEW: API Product model
│   ├── product.dart              (existing: Firestore Product)
│   └── user.dart                 (existing)
│
├── services/
│   └── api_service.dart          ✏️ UPDATED: API methods
│
├── providers/
│   ├── product_provider.dart     ✏️ UPDATED: API methods
│   └── auth_provider.dart        (existing)
│
└── screens/
    ├── api_products_screen.dart       ✨ NEW: Product listing
    ├── api_product_details_screen.dart ✨ NEW: Product details
    ├── api_categories_screen.dart      ✨ NEW: Category browsing
    ├── buyer_dashboard_screen.dart    ✏️ UPDATED: API link
    └── ... (other screens)
```

---

## 🚀 Key Features Implemented

### 1. API Product Model
- Represents products from FakeStore API
- Implements `fromJson()` for parsing API responses
- Implements `toJson()` for serialization
- Includes `copyWith()` for immutable updates

### 2. API Service Layer
- Centralized API communication
- Methods: `fetchProducts()`, `fetchProductsByCategory()`, `fetchProductById()`, `fetchCategories()`
- Error handling with try-catch
- Timeout configuration (10 seconds)
- User-friendly error messages

### 3. State Management
- Provider pattern for reactive UI updates
- Properties: `apiProducts`, `isLoadingApiProducts`, `apiError`, `categories`
- Methods for fetching, filtering, searching, and caching

### 4. UI Components
- **ApiProductsScreen**: Lists products with search
- **ApiProductDetailsScreen**: Detailed product view
- **ApiCategoriesScreen**: Category grid for browsing
- Loading spinner during fetch
- Error message display with retry
- Empty state when no products

### 5. Error Handling
- Network connectivity errors
- Timeout errors
- JSON parsing errors
- User-friendly error messages
- Retry functionality

---

## 📊 Data Flow Diagram

### Loading API Products
```
User taps "Browse"
    ↓
ApiCategoriesScreen loads
    ↓
fetchCategories() called in ProductProvider
    ↓
ApiService.fetchCategories() makes HTTP GET request
    ↓
Response parsed: List<String> of categories
    ↓
notifyListeners() → UI rebuilds with categories
    ↓
User selects category
    ↓
Navigate to ApiProductsScreen(category)
    ↓
fetchApiProductsByCategory() called
    ↓
ApiService.fetchProductsByCategory() → HTTP GET request
    ↓
Response parsed: List<ApiProduct>
    ↓
notifyListeners() → ListView displays products
    ↓
User taps product card
    ↓
Navigate to ApiProductDetailsScreen(product)
    ↓
Display detailed view with image, title, price, rating, description
```

---

## ✅ Testing Your Implementation

### Manual Testing Checklist
- [ ] API products load when app starts
- [ ] Categories display correctly as grid
- [ ] Tapping category shows products
- [ ] Search filters products by title
- [ ] Product images load (or show fallback)
- [ ] Tapping product shows details
- [ ] Ratings display correctly
- [ ] Prices show with $ symbol
- [ ] Network error shows retry button
- [ ] No products state shows empty message
- [ ] Loading spinner shows during fetch
- [ ] Timeout after 10 seconds shows error

---

## 🐛 Troubleshooting

### Issue: Products not loading
**Solution:**
1. Check internet connection
2. Verify FakeStore API is accessible (test in browser)
3. Check logcat for error messages
4. Ensure http package is in pubspec.yaml

### Issue: Images not loading
**Solution:**
1. Check image URL is valid
2. Some devices may block external images
3. App uses errorBuilder for fallback display

### Issue: JSON parsing error
**Solution:**
1. Verify API response format matches expected structure
2. Check for null values in API response
3. ApiProduct.fromJson() includes null safety checks

### Issue: App crashes on fast navigation
**Solution:**
1. States are reset with `clearApiProducts()`
2. Use `FutureBuilder` or `Consumer` for proper state handling
3. Avoid setState() with API calls

---

## 🎓 Key Learnings

1. **REST APIs** follow standard patterns that apply everywhere
2. **JSON parsing** is essential for data integration
3. **Error handling** makes apps robust and user-friendly
4. **Loading states** improve user experience
5. **Provider pattern** scales well with complex state
6. **Separation of concerns** (models, services, providers) keeps code maintainable
7. **Timeouts** prevent app hanging on slow networks

---

## 📚 Next Steps

### Extend the Implementation
1. Add product filtering (by price, rating)
2. Implement favoriting with Firestore
3. Create shopping cart with local storage
4. Add product reviews (mock data)
5. Implement pagination for large datasets
6. Add image zoom feature in details screen

### Production Considerations
1. Implement proper API versioning
2. Add request caching strategies
3. Use secure API key management
4. Implement proper logging and analytics
5. Add user authentication to API calls
6. Implement rate limiting on client side

---

## 🔗 Resources

- **FakeStore API Docs**: https://fakestoreapi.com/docs
- **Flutter http Package**: https://pub.dev/packages/http
- **Provider Documentation**: https://pub.dev/packages/provider
- **REST API Best Practices**: https://restfulapi.net
- **JSON Format Guide**: https://www.json.org

---

## ✨ Summary

LAB 9 demonstrates:
- ✅ Fetching data from a real API (FakeStore)
- ✅ Parsing JSON into Dart objects
- ✅ Managing API states (loading, error, success, empty)
- ✅ Building responsive UIs with API data
- ✅ Handling errors gracefully
- ✅ Implementing search and filter functionality
- ✅ Following clean architecture principles

This implementation is production-ready and follows Flutter best practices!

