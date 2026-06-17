import '../datasources/local/hive_datasources.dart';
import '../datasources/remote/auth_datasource.dart';
import '../datasources/remote/firestore_datasource.dart';
import '../models/user_model.dart';

/// Repository for authentication operations
/// Combines Firebase Auth and local storage
class AuthRepository {
  final AuthDataSource _authDataSource;
  final FirestoreDataSource _firestoreDataSource;
  final HiveDataSource _hiveDataSource;

  AuthRepository({
    required AuthDataSource authDataSource,
    required FirestoreDataSource firestoreDataSource,
    required HiveDataSource hiveDataSource,
  })  : _authDataSource = authDataSource,
        _firestoreDataSource = firestoreDataSource,
        _hiveDataSource = hiveDataSource;

  /// Check if user is logged in
  bool get isLoggedIn => _authDataSource.isLoggedIn;

  /// Get current user ID
  String? get currentUserId => _authDataSource.currentUserId;

  /// Stream of auth state changes
  Stream<UserModel?> get authStateChanges {
    return _authDataSource.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      // Try to get user from local storage first
      var user = _hiveDataSource.getCurrentUser();
      if (user == null || user.uid != firebaseUser.uid) {
        // If not found locally, fetch from Firestore
        user = await _firestoreDataSource.getUser(firebaseUser.uid);
        if (user != null) {
          await _hiveDataSource.saveUser(user);
        }
      }
      return user;
    });
  }

  /// Register new user
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Register with Firebase Auth
      final user = await _authDataSource.registerWithEmailPassword(
        email: email,
        password: password,
        name: name,
      );

      // Save to Firestore
      await _firestoreDataSource.saveUser(user);

      // Save to local storage
      await _hiveDataSource.saveUser(user);

      return user;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Login existing user
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // Login with Firebase Auth
      final user = await _authDataSource.loginWithEmailPassword(
        email: email,
        password: password,
      );

      // Try to get user from Firestore
      final firestoreUser = await _firestoreDataSource.getUser(user.uid);
      final finalUser = firestoreUser ?? user;

      // Save to local storage
      await _hiveDataSource.saveUser(finalUser);

      return finalUser;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authDataSource.sendPasswordResetEmail(email);
    } catch (e) {
      throw Exception('Failed to send reset email: ${e.toString()}');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Sign out from Firebase
      await _authDataSource.logout();

      // Clear local storage
      await _hiveDataSource.clearAllData();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      // Try local storage first
      var user = _hiveDataSource.getCurrentUser();

      if (user == null && _authDataSource.currentUserId != null) {
        // If not found locally but user is logged in, fetch from Firestore
        user = await _firestoreDataSource.getUser(_authDataSource.currentUserId!);
        if (user != null) {
          await _hiveDataSource.saveUser(user);
        }
      }

      return user;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      final userId = _authDataSource.currentUserId;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      // Delete from Firestore
      await _firestoreDataSource.deleteUser(userId);
      await _firestoreDataSource.deleteAllTransactions(userId);

      // Delete from Firebase Auth
      await _authDataSource.deleteAccount();

      // Clear local storage
      await _hiveDataSource.clearAllData();
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  /// Update user email
  Future<void> updateEmail(String newEmail) async {
    try {
      await _authDataSource.updateEmail(newEmail);

      final user = _hiveDataSource.getCurrentUser();
      if (user != null) {
        final updatedUser = user.copyWith(email: newEmail);
        await _hiveDataSource.saveUser(updatedUser);
        await _firestoreDataSource.saveUser(updatedUser);
      }
    } catch (e) {
      throw Exception('Failed to update email: ${e.toString()}');
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _authDataSource.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }

  /// Re-authenticate user
  Future<void> reauthenticate(String email, String password) async {
    try {
      await _authDataSource.reauthenticate(email, password);
    } catch (e) {
      throw Exception('Re-authentication failed: ${e.toString()}');
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _authDataSource.sendEmailVerification();
    } catch (e) {
      throw Exception('Failed to send verification email: ${e.toString()}');
    }
  }

  /// Check if email is verified
  bool get isEmailVerified => _authDataSource.isEmailVerified;
}