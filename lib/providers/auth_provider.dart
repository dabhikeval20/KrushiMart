import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as user_model;

class AuthProvider with ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  firebase_auth.User? _firebaseUser;
  user_model.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  firebase_auth.User? get firebaseUser => _firebaseUser;
  user_model.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser.uid);
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      print('📡 Fetching user data from Firestore for UID: $uid');

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        print('📄 User document exists');
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('📊 Firestore data: $data');

        _currentUser = user_model.User.fromMap(data);
        print(
          '👤 User loaded: ${_currentUser!.name}, Role: ${_currentUser!.role.name}',
        );
      } else {
        print(
          '⚠️ User document does NOT exist - creating default buyer profile',
        );
        // Create a default user profile if document doesn't exist
        _currentUser = user_model.User(
          id: uid,
          name: 'User', // Default name
          email: _firebaseUser?.email ?? '',
          phone: '',
          location: '',
          role: user_model.UserRole.buyer, // Default to buyer
        );

        // Optionally save this default user to Firestore
        try {
          await _firestore
              .collection('users')
              .doc(uid)
              .set(_currentUser!.toMap());
          print('💾 Default user profile saved to Firestore');
        } catch (saveError) {
          print('⚠️ Failed to save default profile: $saveError');
          // Continue anyway - user can still use the app
        }
      }
    } catch (e) {
      print('❌ Firestore error: $e');
      _errorMessage = 'Failed to load user data: $e';

      // Create a fallback user if Firestore fails (offline/network issues)
      if (_firebaseUser != null) {
        print('🔄 Creating offline fallback user');
        _currentUser = user_model.User(
          id: _firebaseUser!.uid,
          name: _firebaseUser!.displayName ?? 'User',
          email: _firebaseUser!.email ?? '',
          phone: '',
          location: '',
          role: user_model.UserRole.buyer, // Default fallback
        );
      }
    }
  }

  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
    required user_model.UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      firebase_auth.UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user document in Firestore
      user_model.User newUser = user_model.User(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        phone: '', // Will be updated later in profile
        location: '', // Will be updated later in profile
        role: role,
      );

      await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());

      _currentUser = newUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Registration failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    // Input validation
    if (email.trim().isEmpty || password.isEmpty) {
      _errorMessage = 'Email and password are required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔐 Attempting login for email: $email');

      firebase_auth.UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      print('✅ Firebase Auth success - UID: ${userCredential.user!.uid}');

      // Wait for user data to be loaded from Firestore
      await _loadUserData(userCredential.user!.uid);

      // Save session for auto-login on next app launch
      await saveSessionData();

      _isLoading = false;
      notifyListeners();

      print(
        '🎉 Login complete - User: ${_currentUser?.name ?? 'Unknown'}, Role: ${_currentUser?.role.name ?? 'No role'}',
      );

      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e);
      print('❌ Auth error: ${e.code} - $_errorMessage');
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Login failed: $e';
      print('❌ Login error: $e');
      notifyListeners();
      return false;
    }
  }

  /// 🔐 Logout user and clear session data
  Future<void> logout() async {
    try {
      // Clear Firebase Auth
      await _auth.signOut();

      // Clear SharedPreferences session
      await clearSessionData();

      // Reset current user
      _currentUser = null;
      _errorMessage = null;

      print('✅ User logged out successfully');
      notifyListeners();
    } catch (e) {
      print('❌ Logout error: $e');
      _errorMessage = 'Logout failed: $e';
      notifyListeners();
    }
  }

  /// 💾 Save session data to SharedPreferences after successful login
  Future<void> saveSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_currentUser != null) {
        // Save user ID and email for reference
        await prefs.setString('user_id', _currentUser!.id);
        await prefs.setString('user_email', _currentUser!.email);
        await prefs.setString('user_name', _currentUser!.name);
        await prefs.setString('user_role', _currentUser!.role.name);

        // Mark as logged in
        await prefs.setBool('is_logged_in', true);

        // Save timestamp for analytics
        await prefs.setInt('last_login', DateTime.now().millisecondsSinceEpoch);

        print(
          '💾 Session saved: ${_currentUser!.email} (${_currentUser!.role.name})',
        );
      }
    } catch (e) {
      print('⚠️ Failed to save session: $e');
    }
  }

  /// 📖 Restore session from SharedPreferences on app startup
  Future<bool> restoreSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user was previously logged in
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (!isLoggedIn) {
        print('📖 No previous session found');
        return false;
      }

      // Get saved user data
      final userId = prefs.getString('user_id');
      final email = prefs.getString('user_email');

      if (userId != null && email != null) {
        // Try to load user from Firestore
        await _loadUserData(userId);
        print('📖 Session restored: $email');
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('⚠️ Failed to restore session: $e');
    }

    return false;
  }

  /// 🗑️ Clear all session data from SharedPreferences
  Future<void> clearSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_role');
      await prefs.remove('is_logged_in');
      await prefs.remove('last_login');

      print('🗑️ Session data cleared');
    } catch (e) {
      print('⚠️ Failed to clear session: $e');
    }
  }

  /// 🔍 Check if user session exists
  Future<bool> hasActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      print('⚠️ Failed to check session: $e');
      return false;
    }
  }

  /// ⏱️ Get last login time
  Future<DateTime?> getLastLoginTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_login');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      print('⚠️ Failed to get last login time: $e');
    }
    return null;
  }

  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? location,
  }) async {
    if (_currentUser == null || _firebaseUser == null) return;

    try {
      user_model.User updatedUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
        location: location,
      );

      await _firestore.collection('users').doc(_firebaseUser!.uid).update({
        'name': name,
        'phone': phone,
        'location': location,
      });

      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
    }
  }

  String _getAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled. Please contact support.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  /// 🔑 Send password reset email
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📧 Sending password reset email to: $email');

      await _auth.sendPasswordResetEmail(email: email.trim());

      _isLoading = false;
      notifyListeners();

      print('✅ Password reset email sent successfully');
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e);
      print('❌ Password reset error: ${e.code} - $_errorMessage');
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to send reset email: $e';
      print('❌ Password reset error: $e');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
