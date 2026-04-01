# KrushiMart - Farmer Marketplace App

A complete Flutter application for buying and selling farming tools, seeds, and fertilizers.

## Features
- **Splash Screen**: Animated entry.
- **Authentication**: Login/Register (Dummy).
- **Dashboard**: Home, Market, Profile tabs.
- **Product Listing**: Filter by category, sort by price, search.
- **Product Details**: View details, call/WhatsApp seller.
- **Sell Product**: Add new products with validation.
- **Clean Architecture**: Provider for state management.

## Prerequisites
- Flutter SDK (Latest Stable)
- Android Studio / VS Code
- Android Emulator or Physical Device

## How to Run
1. Open the project folder `KrushiMart` in Android Studio or VS Code.
2. Open terminal and run:
   ```bash
   flutter pub get
   ```
3. improved functionality:
   - Ensure you have an Android emulator running or device connected.
4. Run the app:
   ```bash
   flutter run
   ```

## Login Credentials (Dummy)
- **Phone**: Any 10 digit number (e.g., `9876543210`)
- **Password**: Any string >= 4 chars (e.g., `1234`)

## Project Structure
- `lib/models`: Data models (Product, User)
- `lib/providers`: State management (AuthProvider, ProductProvider)
- `lib/screens`: UI Screens (Auth, Home, Product, Profile)
- `lib/widgets`: Reusable widgets (ProductCard, CustomTextField)
- `lib/data`: Dummy data

## Tech Stack
- Flutter & Dart
- Provider (State Management)
- Material 3 Design
