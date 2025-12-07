import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'google_sign_in_service.dart';

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
  })  : _googleSignIn = googleSignIn ?? GoogleSignInService().googleSignIn,
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
      debugPrint('AuthService: Starting Google sign in...');

      // Sign in with Google
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('AuthService: Google sign in cancelled');
        return AuthResult.cancelled();
      }

      debugPrint('AuthService: Google sign in successful: ${googleUser.email}');
      _currentGoogleUser = googleUser;

      // Get or create user in Supabase
      final user = await _getOrCreateUser(googleUser);
      _currentUser = user;
      debugPrint('AuthService: User from Supabase: ${user.name} (${user.id})');

      // Save auth state for offline access
      await _saveUserDataForOffline(user);

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
      debugPrint('AuthService: Checking auth state...');

      // Try to sign in silently (if previously signed in)
      final googleUser = await _googleSignIn.signInSilently();
      debugPrint('AuthService: signInSilently result: ${googleUser?.email ?? 'null'}');

      if (googleUser == null) {
        // No Google session, check if we have saved credentials for offline mode
        debugPrint('AuthService: No Google session, checking offline session...');
        return await _checkOfflineSession();
      }

      _currentGoogleUser = googleUser;

      // Try to get user from Supabase
      debugPrint('AuthService: Getting user from Supabase...');
      try {
        final user = await _getUserByGoogleIdWithError(googleUser.id);

        if (user == null) {
          // User exists in Google but not in our database
          // This shouldn't happen, but handle it
          debugPrint('AuthService: User not found in database, signing out');
          await signOut();
          return AuthResult.noSession();
        }

        _currentUser = user;
        debugPrint('AuthService: User authenticated successfully: ${user.name}');

        // Save user data for offline access
        await _saveUserDataForOffline(user);

        return AuthResult.success(user);
      } catch (e) {
        // Network error while getting user from Supabase
        // Try to use cached data instead of signing out
        debugPrint('AuthService: Network error getting user, trying offline session...');
        final offlineResult = await _checkOfflineSession();
        if (offlineResult.isSuccess) {
          return offlineResult;
        }
        // If no cached data, re-throw the error
        rethrow;
      }
    } catch (e) {
      debugPrint('AuthService: Error checking auth state: $e');
      // If network error, try offline session
      if (e.toString().contains('network') ||
          e.toString().contains('connection') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        debugPrint('AuthService: Network error detected, trying offline session...');
        return await _checkOfflineSession();
      }
      return AuthResult.error(e.toString());
    }
  }

  /// Get user by Google ID - throws error on network failure
  Future<UserModel?> _getUserByGoogleIdWithError(String googleId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('google_id', googleId)
        .maybeSingle();

    if (response == null) return null;

    return UserModel.fromJson(response);
  }

  /// Check for offline session using cached data
  Future<AuthResult> _checkOfflineSession() async {
    try {
      debugPrint('AuthService: _checkOfflineSession - Reading cached data...');

      final userId = await _secureStorage.read(key: 'user_id');
      final googleId = await _secureStorage.read(key: 'google_id');
      final userName = await _secureStorage.read(key: 'user_name');
      final userEmail = await _secureStorage.read(key: 'user_email');

      debugPrint('AuthService: Cached userId: $userId');
      debugPrint('AuthService: Cached googleId: $googleId');
      debugPrint('AuthService: Cached userName: $userName');
      debugPrint('AuthService: Cached userEmail: $userEmail');

      if (userId == null || googleId == null) {
        debugPrint('AuthService: No cached credentials found, returning noSession');
        return AuthResult.noSession();
      }

      // Create user from cached data
      _currentUser = UserModel(
        id: userId,
        googleId: googleId,
        email: userEmail ?? '',
        name: userName ?? 'مستخدم',
        avatarUrl: await _secureStorage.read(key: 'user_avatar'),
        driveFolderId: await _secureStorage.read(key: 'drive_folder_id'),
        pinEnabled: (await _secureStorage.read(key: 'pin_enabled')) == 'true',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint('AuthService: Restored offline session for user: ${_currentUser!.name} ($userId)');
      return AuthResult.success(_currentUser!);
    } catch (e) {
      debugPrint('AuthService: Error checking offline session: $e');
      return AuthResult.noSession();
    }
  }

  /// Save user data for offline access
  Future<void> _saveUserDataForOffline(UserModel user) async {
    debugPrint('AuthService: Saving user data for offline access...');
    debugPrint('AuthService: Saving userId: ${user.id}');
    debugPrint('AuthService: Saving googleId: ${user.googleId}');
    debugPrint('AuthService: Saving userName: ${user.name}');

    await _secureStorage.write(key: 'user_id', value: user.id);
    await _secureStorage.write(key: 'google_id', value: user.googleId);
    await _secureStorage.write(key: 'user_email', value: user.email);
    await _secureStorage.write(key: 'user_name', value: user.name);
    if (user.avatarUrl != null) {
      await _secureStorage.write(key: 'user_avatar', value: user.avatarUrl);
    }
    if (user.driveFolderId != null) {
      await _secureStorage.write(key: 'drive_folder_id', value: user.driveFolderId);
    }
    await _secureStorage.write(key: 'pin_enabled', value: user.pinEnabled.toString());

    debugPrint('AuthService: User data saved for offline access');
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

  /// Clear auth state
  Future<void> _clearAuthState() async {
    await _secureStorage.delete(key: 'user_id');
    await _secureStorage.delete(key: 'google_id');
    await _secureStorage.delete(key: 'user_email');
    await _secureStorage.delete(key: 'user_name');
    await _secureStorage.delete(key: 'user_avatar');
    await _secureStorage.delete(key: 'drive_folder_id');
    await _secureStorage.delete(key: 'pin_enabled');
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
