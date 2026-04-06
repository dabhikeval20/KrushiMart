# LAB 9: Testing & Error Handling Guide

## 🧪 Testing Your Implementation

### Important: Before Testing

Ensure you have:

1. ✅ Updated all 3 screens (api_products_screen.dart, api_product_details_screen.dart, api_categories_screen.dart)
2. ✅ Updated product_provider.dart with API methods
3. ✅ Updated api_service.dart with 4 fetch methods
4. ✅ Created api_product.dart model
5. ✅ Updated buyer_dashboard_screen.dart with API link
6. ✅ Device has internet connection (or emulator with internet)

---

## 🔍 Manual Testing Scenarios

### Test 1: Categories Loading

**Steps:**

1. Run the app
2. Login as buyer
3. Tap "Browse Global Products" button
4. Observe: Spinner → Loading → Categories grid

**Expected Results:**

- ✅ 4 categories display: electronics, jewelery, men's clothing, women's clothing
- ✅ Each has icon and colored background
- ✅ No loading spinner after categories appear

**If fails:**

```
Problem: Spinner stays forever
Solution: Check internet, verify api.dart has fetchCategories() method

Problem: Blank screen
Solution: Check logcat for exceptions, ensure Consumer<ProductProvider> wraps UI

Problem: Categories not tappable
Solution: InkWell needs borderRadius, check api_categories_screen.dart line 60+
```

---

### Test 2: Loading Products by Category

**Steps:**

1. From Categories screen, tap any category (e.g., "Electronics")
2. Observe: Spinner appears, then product list loads
3. Confirm product count and names match category

**Expected Results:**

- ✅ Spinner shows during loading
- ✅ Products list displays with images, titles, prices, ratings
- ✅ All 13-20 products appear (depends on category)
- ✅ Search box shows at top

**If fails:**

```
Problem: "No products found" state shows
Solution: Check logcat for API errors
- Error 404: Category name might be wrong (use lowercase)
- JSON parsing error: Check ApiProduct.fromJson() handles null safely
- Timeout: API might be slow, check if > 10 seconds

Problem: Images don't load, only fallback icons show
Solution: This is OK - network restrictions. Check image URL format in logs
- Should be: https://fakestoreapi.com/img/...
- If blank: Check ApiProduct.fromJson() image field parsing

Problem: Prices show as $0.00
Solution: Check JSON parsing in ApiProduct.fromJson()
- Should be: (json['price'] ?? 0.0).toDouble()
- Log the raw JSON to verify field names
```

---

### Test 3: Search Functionality

**Steps:**

1. Load products for any category
2. Type in search box: "shirt"
3. Observe: List filters to matching products
4. Clear search, observe: All products reappear

**Expected Results:**

- ✅ Filters by title and description
- ✅ Case-insensitive search
- ✅ Updates in real-time as you type
- ✅ "X products found" count updates

**If fails:**

```
Problem: Search doesn't filter
Solution: Check _searchController.text in searchApiProducts()
- Ensure setState(() {}) triggers rebuild
- Check TextEditingController is disposed in dispose()

Problem: Case-sensitive search only
Solution: Check searchApiProducts() uses .toLowerCase()
```

---

### Test 4: Product Details Screen

**Steps:**

1. Load products in ApiProductsScreen
2. Tap any product card
3. Observe: Details screen navigates
4. Review product info displayed

**Expected Results:**

- ✅ Large product image displays
- ✅ Title, description, category show clearly
- ✅ Price highlighted in green with $ symbol
- ✅ Rating shows with star icon and review count
- ✅ "Add to Cart" and "Add to Wishlist" buttons visible
- ✅ Product ID shows at bottom

**If fails:**

```
Problem: Image doesn't display on details screen
Solution: Check Image.network() has correct errorBuilder
- Fallback icon should show if image fails

Problem: Navigation doesn't happen
Solution: Check InkWell.onTap navigates with:
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => ApiProductDetailsScreen(product: product),
  ),
);

Problem: "Product ID" section doesn't show
Solution: Check Container at bottom of details screen wraps all content
- Should be inside SingleChildScrollView
```

---

### Test 5: Error Handling - No Internet

**Steps:**

1. Turn off internet connection
2. Reload app or navigate to categories
3. Observe: Error screen appears

**Expected Results:**

- ✅ Error icon displays (red, outlined)
- ✅ Error message shows: "Failed to fetch products..."
- ✅ "Retry" button is clickable
- ✅ Tapping "Retry" after reconnecting reloads data

**If fails:**

```
Problem: App crashes instead of showing error
Solution: Check try-catch blocks in:
- fetchApiProducts() in product_provider.dart
- fetchCategories() in product_provider.dart
- ErrorWidget might be missing - add error handling to Consumer

Problem: Error message is generic/unhelpful
Solution: Check error message includes error type:
- "Failed to fetch: SocketException: Connection refused"
- "Failed to fetch: TimeoutException"
- This helps debugging network issues

Problem: Retry button doesn't work
Solution: Verify onPressed() calls fetchApiProducts() again:
ElevatedButton(
  onPressed: () => productProvider.fetchApiProducts(),
  child: const Text('Retry'),
)
```

---

### Test 6: Empty State

**Steps:**

1. In search box, search for something that doesn't exist: "xyz9999"
2. Observe: Empty state displays

**Expected Results:**

- ✅ Shopping bag icon displays (gray, outlined)
- ✅ "No products found" message shows
- ✅ Helpful secondary text appears
- ✅ Search box is still visible for new search

**If fails:**

```
Problem: Empty state doesn't show, products still appear
Solution: Check searchApiProducts() filter logic:
return apiProducts
    .where((product) =>
        product.title.toLowerCase().contains(query.toLowerCase()))
    .toList();

Problem: Items still show but shouldn't
Solution: Ensure filtered list length is checked:
if (productsToDisplay.isEmpty) {
  return /* empty state */;
}
```

---

### Test 7: Rating Display

**Steps:**

1. Load products
2. Check that each product card shows:
   - Star icon (yellow)
   - Rating number (e.g., "4.5")
   - Review count (e.g., "(128)")

**Expected Results:**

- ✅ All 3 elements display correctly
- ✅ Ratings between 0.0 and 5.0
- ✅ Review counts are positive integers

**If fails:**

```
Problem: Rating shows as "0.0"
Solution: Check ApiProduct.fromJson() parses nested field:
rating: (json['rating']?['rate'] ?? 0.0).toDouble()
- API returns {"rating": {"rate": 4.5, "count": 128}}
- Must access nested 'rate' field

Problem: Rating Count shows as 0
Solution: Similar check for ratingCount:
ratingCount: json['rating']?['count'] ?? 0
```

---

## 🐛 Common Errors & Solutions

### Error: "Failed to load products: 404"

```
Cause: Wrong API endpoint or category name
Solution:
- Check base URL: https://fakestoreapi.com (not /api/v1/)
- Category names must be lowercase: "electronics", not "Electronics"
- Verify in ApiService: Uri.parse('$baseUrl/products')
```

### Error: "SocketException: Connection refused"

```
Cause: No internet connection
Solution:
- Check device internet works (test in browser)
- Emulator: Make sure internet is enabled
- Check ApiService timeout is reasonable (10 seconds)
```

### Error: "TimeoutException after 0:00:10"

```
Cause: API taking longer than 10 seconds
Solution:
- Check API is responding (test in Postman)
- Increase timeout: Duration(seconds: 15)
- Check network latency (weak wifi/mobile)
```

### Error: "NoSuchMethodError: method not found in ApiProduct"

```
Cause: Missing method in api_product.dart
Solution:
- Ensure fromJson() factory method exists:
  factory ApiProduct.fromJson(Map<String, dynamic> json) { ... }
- Check method signature matches usage in api_service.dart
```

### Error: "Provider not found" during build

```
Cause: Consumer<ProductProvider> can't access provider
Solution:
- Ensure ProductProvider is provided at top level in main.dart:
  ChangeNotifierProvider(create: (_) => ProductProvider())
- Check import: import '../providers/product_provider.dart'
- Verify ProductProvider with ChangeNotifier
```

### Error: App crashes on navigate to ApiProductsScreen

```
Cause: apiProducts might be null or uninitialized
Solution:
- Check apiProducts = [] in ProductProvider __init__
- Ensure fetchApiProducts() is called in initState()
- Use Consumer to listen to provider changes
```

---

## 📊 Logging & Debugging

### Enable Detailed Logs

```dart
// In ApiService methods, add logs:
print('🔄 Fetching from $url');
print('📥 Response: ${response.statusCode}');
print('📦 Parsed: ${products.length} products');
print('❌ Error: $e');

// In ProductProvider:
print('✅ Loaded ${apiProducts.length} API products');
print('⏱️ Load took ${DateTime.now().difference(startTime).inMilliseconds}ms');
```

### Read Logs in Android Studio

```
- Open View → Tool Windows → Logcat
- Filter by package name: krushimart
- Search for 🔄 🔥 ❌ emoji to find logs
- Ctrl+F to search for "ApiProduct" or "ApiService"
```

### Test API in Postman

```
1. Download Postman (or use https://www.postman.com/downloads/)
2. Create GET request to: https://fakestoreapi.com/products
3. View response structure
4. Compare with ApiProduct.fromJson() parsing logic
5. Testing individual endpoints before app integration helps!
```

---

## ✅ Pre-Submission Checklist

### Code Quality

- [ ] No analyzer warnings: `flutter analyze`
- [ ] No unused variables
- [ ] No print() statements in production code (or remove them)
- [ ] Proper indentation (2 spaces in Dart)
- [ ] No magic strings - use constants for API URLs

### Functionality

- [ ] All 4 API endpoints working (products, products/category, products/id, categories)
- [ ] Image loading (shows image or fallback icon)
- [ ] Search filtering works
- [ ] Navigation between screens works
- [ ] Back button returns to previous screen

### Error Handling

- [ ] Loading spinner shows while fetching
- [ ] Error message displays on network error
- [ ] Retry button works
- [ ] Empty state shows when no products
- [ ] No app crashes during operations

### UI/UX

- [ ] Text is readable (proper contrast)
- [ ] Buttons are easily tappable (48dp minimum)
- [ ] Images scale properly (no distortion)
- [ ] Price shows with $ and decimals
- [ ] Rating shows with star icon and count

### Documentation

- [ ] README.md updated with LAB 9 info
- [ ] LAB_9_API_INTEGRATION_GUIDE.md exists
- [ ] LAB_9_CODE_EXAMPLES.md exists
- [ ] Code comments explain complex logic
- [ ] Architecture documented clearly

---

## 🎓 What You've Learned

✅ **REST API concepts** - Request/response cycle, HTTP methods
✅ **JSON parsing** - Convert API responses to Dart objects
✅ **Error handling** - Graceful error UI with retry
✅ **State management** - Provider pattern with API integration
✅ **Async operations** - Future, async/await, try-catch
✅ **UI patterns** - Loading, error, empty, success states
✅ **Navigation** - Push/pop between API-powered screens
✅ **Search/filter** - Real-time filtering of API data

---

## 🚀 Next Enhancements

After LAB 9, you could:

1. Add product favoriting (save to Firestore)
2. Implement shopping cart (local storage)
3. Add product reviews (mock data)
4. Implement pagination (load more products)
5. Add image zoom feature
6. Create order checkout flow
7. Add user ratings & reviews
8. Implement real-time product search
9. Add product comparison
10. Create admin panel for managing API integration

---

## 📞 Support

**If you encounter issues:**

1. Check logcat for error messages
2. Verify API is accessible (test in browser)
3. Check internet connection
4. Review code examples in LAB_9_CODE_EXAMPLES.md
5. Compare your code with expected structure
6. Check that all imports are present
7. Rebuild the app: `flutter clean && flutter pub get`

---

Good luck with LAB 9! 🚀
