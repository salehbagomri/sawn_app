import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

/// Authentication service using Google Sign-In
class AuthService {
  final GoogleSignIn _googleSignIn;
  final SupabaseClient _supabase;
  final FlutterSecureStorage _secureStorage;

  GoogleSignInAccount? _currentGoogleUser;
  UserModel? _currentUser;

  AuthService({
    GoogleSignIn? googleSignIn,
    SupabaseClient? supabase,
    FlutterSecureStorage? secureStorage,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [
                'email',
                'profile',
                'https://www.googleapis.com/auth/drive.file',
              ],
            ),
        _supabase = supabase ?? Supabase.instance.client,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Get current Google user
  GoogleSignInAccount? get currentGoogleUser => _currentGoogleUser;

  /// Get current app user
  UserModel? get currentUser => _currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _currentGoogleUser != null && _currentUser != null;

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Sign in with Google
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.cancelled();
      }

      _currentGoogleUser = googleUser;

      // Get or create user in Supabase
      final user = await _getOrCreateUser(googleUser);
      _currentUser = user;

      // Save auth state
      await _saveAuthState();

      return AuthResult.success(user);
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return AuthResult.error(e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentGoogleUser = null;
      _currentUser = null;
      await _clearAuthState();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  /// Check and restore previous session
  Future<AuthResult> checkAuthState() async {
    try {
      // Try to sign in silently (if previously signed in)
      final googleUser = await _googleSignIn.signInSilently();

      if (googleUser == null) {
        return AuthResult.noSession();
      }

      _currentGoogleUser = googleUser;

      // Get user from Supabase
      final user = await _getUserByGoogleId(googleUser.id);

      if (user == null) {
        // User exists in Google but not in our database
        // This shouldn't happen, but handle it
        await signOut();
        return AuthResult.noSession();
      }

      _currentUser = user;
      return AuthResult.success(user);
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      return AuthResult.error(e.toString());
    }
  }

  /// Get Google auth headers for API calls
  Future<Map<String, String>?> getAuthHeaders() async {
    try {
      final googleAuth = await _currentGoogleUser?.authentication;
      if (googleAuth?.accessToken == null) return null;

      return {
        'Authorization': 'Bearer ${googleAuth!.accessToken}',
      };
    } catch (e) {
      debugPrint('Error getting auth headers: $e');
      return null;
    }
  }

  /// Get or create user in Supabase
  Future<UserModel> _getOrCreateUser(GoogleSignInAccount googleUser) async {
    // Check if user exists
    final existingUser = await _getUserByGoogleId(googleUser.id);

    if (existingUser != null) {
      // Update user info if needed
      return await _updateUserInfo(existingUser, googleUser);
    }

    // Create new user
    return await _createUser(googleUser);
  }

  /// Get user by Google ID
  Future<UserModel?> _getUserByGoogleId(String googleId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('google_id', googleId)
          .maybeSingle();

      if (response == null) return null;

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Create new user
  Future<UserModel> _createUser(GoogleSignInAccount googleUser) async {
    final now = DateTime.now().toIso8601String();

    final userData = {
      'google_id': googleUser.id,
      'email': googleUser.email,
      'name': googleUser.displayName,
      'avatar_url': googleUser.photoUrl,
      'pin_enabled': false,
      'created_at': now,
      'updated_at': now,
    };

    final response =
        await _supabase.from('users').insert(userData).select().single();

    return UserModel.fromJson(response);
  }

  /// Update user info
  Future<UserModel> _updateUserInfo(
    UserModel existingUser,
    GoogleSignInAccount googleUser,
  ) async {
    // Only update if info changed
    if (existingUser.name == googleUser.displayName &&
        existingUser.avatarUrl == googleUser.photoUrl) {
      return existingUser;
    }

    final response = await _supabase
        .from('users')
        .update({
          'name': googleUser.displayName,
          'avatar_url': googleUser.photoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', existingUser.id)
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  /// Update user's Drive folder ID
  Future<UserModel?> updateDriveFolderId(String folderId) async {
    if (_currentUser == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .update({
            'drive_folder_id': folderId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentUser!.id)
          .select()
          .single();

      _currentUser = UserModel.fromJson(response);
      return _currentUser;
    } catch (e) {
      debugPrint('Error updating drive folder ID: $e');
      return null;
    }
  }

  /// Update PIN enabled status
  Future<UserModel?> updatePinEnabled(bool enabled) async {
    if (_currentUser == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .update({
            'pin_enabled': enabled,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentUser!.id)
          .select()
          .single();

      _currentUser = UserModel.fromJson(response);
      return _currentUser;
    } catch (e) {
      debugPrint('Error updating PIN status: $e');
      return null;
    }
  }

  /// Save auth state locally
  Future<void> _saveAuthState() async {
    if (_currentUser == null) return;

    await _secureStorage.write(key: 'user_id', value: _currentUser!.id);
    await _secureStorage.write(
        key: 'google_id', value: _currentUser!.googleId);
  }

  /// Clear auth state
  Future<void> _clearAuthState() async {
    await _secureStorage.delete(key: 'user_id');
    await _secureStorage.delete(key: 'google_id');
    await _secureStorage.delete(key: 'pin_code');
  }

  /// Delete account
  Future<bool> deleteAccount({String? reason, String? notes}) async {
    if (_currentUser == null) return false;

    try {
      // Save deletion reason (for analytics)
      if (reason != null) {
        await _supabase.from('deletion_reasons').insert({
          'reason': reason,
          'notes': notes,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Delete user (cascade will delete related data)
      await _supabase.from('users').delete().eq('id', _currentUser!.id);

      // Sign out
      await signOut();

      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }
}

/// Result of authentication operations
class AuthResult {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthResult._({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success(UserModel user) {
    return AuthResult._(status: AuthStatus.success, user: user);
  }

  factory AuthResult.cancelled() {
    return const AuthResult._(status: AuthStatus.cancelled);
  }

  factory AuthResult.noSession() {
    return const AuthResult._(status: AuthStatus.noSession);
  }

  factory AuthResult.error(String message) {
    return AuthResult._(status: AuthStatus.error, errorMessage: message);
  }

  bool get isSuccess => status == AuthStatus.success;
  bool get isCancelled => status == AuthStatus.cancelled;
  bool get hasNoSession => status == AuthStatus.noSession;
  bool get hasError => status == AuthStatus.error;
}

enum AuthStatus {
  success,
  cancelled,
  noSession,
  error,
}
