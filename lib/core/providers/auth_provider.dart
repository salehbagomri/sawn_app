import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/google_sign_in_service.dart';
import '../models/user_model.dart';

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for current user state
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AsyncValue<UserModel?>>((ref) {
  return CurrentUserNotifier(ref.watch(authServiceProvider));
});

/// Notifier for current user state
class CurrentUserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  CurrentUserNotifier(this._authService) : super(const AsyncValue.loading()) {
    _checkAuthState();
  }

  /// Check initial auth state
  Future<void> _checkAuthState() async {
    state = const AsyncValue.loading();

    final result = await _authService.checkAuthState();

    if (result.isSuccess) {
      state = AsyncValue.data(result.user);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    state = const AsyncValue.loading();

    final result = await _authService.signInWithGoogle();

    if (result.isSuccess) {
      state = AsyncValue.data(result.user);
    } else if (result.hasError) {
      state = AsyncValue.error(result.errorMessage!, StackTrace.current);
    } else {
      state = const AsyncValue.data(null);
    }

    return result;
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  /// Update Drive folder ID
  Future<void> updateDriveFolderId(String folderId) async {
    final user = await _authService.updateDriveFolderId(folderId);
    if (user != null) {
      state = AsyncValue.data(user);
    }
  }

  /// Update PIN status
  Future<void> updatePinEnabled(bool enabled) async {
    final user = await _authService.updatePinEnabled(enabled);
    if (user != null) {
      state = AsyncValue.data(user);
    }
  }

  /// Delete account
  Future<bool> deleteAccount({String? reason, String? notes}) async {
    final success = await _authService.deleteAccount(reason: reason, notes: notes);
    if (success) {
      state = const AsyncValue.data(null);
    }
    return success;
  }
}

/// Provider for auth state (simple boolean)
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

/// Provider for checking if user has set up Drive folder
final hasDriveFolderProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(
    data: (user) => user?.driveFolderId != null,
    orElse: () => false,
  );
});

/// Provider for checking if PIN is enabled
final isPinEnabledProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(
    data: (user) => user?.pinEnabled ?? false,
    orElse: () => false,
  );
});

/// Provider for Google user info (name, email, photo)
final googleUserInfoProvider = Provider<({String? displayName, String? email, String? photoUrl})>((ref) {
  final googleUser = GoogleSignInService().currentUser;
  return (
    displayName: googleUser?.displayName,
    email: googleUser?.email,
    photoUrl: googleUser?.photoUrl,
  );
});
