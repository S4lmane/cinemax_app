import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  User? _user;
  String? _error;

  AuthProvider() {
    _initialize();
  }

  // Getters
  bool get isLoading => _isLoading;
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  // Initialisation auth state
  Future<void> _initialize() async {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signInWithEmailAndPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _authService.registerWithEmailAndPassword(email, password);

      // Create user profile in Firestore
      if (credential.user != null) {
        await FirebaseService.createUserProfile(
          uid: credential.user!.uid,
          email: email,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to sign out';
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithUsernameOrEmail(String usernameOrEmail, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Determine if input is email or username
      bool isEmail = usernameOrEmail.contains('@');

      if (isEmail) {
        // Direct login with email
        await _authService.signInWithEmailAndPassword(usernameOrEmail, password);
      } else {
        // Find email associated with username
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: usernameOrEmail)
            .limit(1)
            .get();

        if (userDoc.docs.isEmpty) {
          _isLoading = false;
          _error = 'No user found with this username';
          notifyListeners();
          return false;
        }

        // Get email from user document
        final email = userDoc.docs.first.data()['email'] as String;

        // Sign in with retrieved email
        await _authService.signInWithEmailAndPassword(email, password);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get readable error message
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Contact support.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}