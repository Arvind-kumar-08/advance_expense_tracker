import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Provider for authentication state management
class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  // State variables
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUser?.uid;

  /// Initialize auth state
  Future<void> initializeAuth() async {
    _setLoading(true);
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
      }
    } catch (e) {
      _setError('Failed to initialize auth: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Listen to auth state changes
  void listenToAuthChanges() {
    _authRepository.authStateChanges.listen((user) {
      _currentUser = user;
      _isAuthenticated = user != null;
      notifyListeners();
    });
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      _currentUser = user;
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Login existing user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );

      _currentUser = user;
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authRepository.logout();
      _currentUser = null;
      _isAuthenticated = false;
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.deleteAccount();
      _currentUser = null;
      _isAuthenticated = false;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Update email
  Future<bool> updateEmail(String newEmail) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.updateEmail(newEmail);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(email: newEmail);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Update password
  Future<bool> updatePassword(String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.updatePassword(newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Re-authenticate user
  Future<bool> reauthenticate(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.reauthenticate(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message manually
  void clearError() {
    _clearError();
  }
}