import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

// Models
import 'models/user.dart' as user_model;

// Providers
import 'providers/product_provider.dart';
import 'providers/auth_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/seller_dashboard_screen.dart';
import 'screens/buyer_dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/edit_product_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/farming_tips_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 Background message received: ${message.messageId}');
  // Let FCM display the notification automatically in the system tray.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService.init();

  print("🔥 Firebase Connected Successfully");

  // Test Firestore connection
  final productProvider = ProductProvider();
  await productProvider.testConnection();

  // 📖 Initialize AuthProvider and restore session if available
  final authProvider = AuthProvider();
  final hasSession = await authProvider.hasActiveSession();
  print('📖 Checking for saved session: ${hasSession ? 'Found' : 'Not found'}');

  runApp(const KrushiMartApp());
}

class KrushiMartApp extends StatelessWidget {
  const KrushiMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        navigatorKey: NotificationService.navigatorKey,
        title: 'KrushiMart',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            primary: const Color(0xFF2E7D32),
            secondary: const Color(0xFF1B5E20),
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            elevation: 10,
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF2E7D32),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(fontSize: 12),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            prefixIconColor: const Color(0xFF2E7D32),
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
            titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
            bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegistrationScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/seller_dashboard': (context) => const SellerDashboardScreen(),
          '/buyer_dashboard': (context) => const BuyerDashboardScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/edit_product': (context) => const EditProductScreen(),
          '/product_details': (context) => const ProductDetailsScreen(),
          '/edit_profile': (context) => const EditProfileScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/product_list': (context) => const ProductListScreen(),
          '/add_product': (context) => const AddProductScreen(),
          '/farming_tips': (context) => const FarmingTipsScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show splash screen while checking auth state or loading user data
        if (authProvider.isLoading) {
          print('⏳ Auth loading...');
          return const SplashScreen();
        }

        // If not authenticated, show login
        if (!authProvider.isAuthenticated) {
          print('🔒 Not authenticated - showing login');
          return const LoginScreen();
        }

        // If authenticated but no user data loaded yet, show splash
        if (authProvider.currentUser == null) {
          print('⏳ Authenticated but no user data - showing splash');
          return const SplashScreen();
        }

        // Get user role and return the proper home screen directly.
        final role = authProvider.currentUser!.role;
        print('🎯 Returning screen based on role: ${role.name}');

        switch (role) {
          case user_model.UserRole.seller:
            return const SellerDashboardScreen();
          case user_model.UserRole.buyer:
            return const BuyerDashboardScreen();
        }
      },
    );
  }
}
