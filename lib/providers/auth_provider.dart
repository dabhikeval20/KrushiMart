import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
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

      _isLoading = false;
      notifyListeners();

      print(
        '🎉 Login complete - User: ${_currentUser?.name ?? 'Unknown'}, Role: ${_currentUser?.role.name ?? 'No role'}',
      );

      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e);
      print('❌ Auth error: ${e.code} - ${_errorMessage}');
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

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
