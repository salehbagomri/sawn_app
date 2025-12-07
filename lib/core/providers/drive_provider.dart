import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_drive_service.dart';
import '../services/google_sign_in_service.dart';

/// Provider for GoogleDriveService
final driveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService();
});

/// Provider for Drive initialization state
final driveInitializedProvider = FutureProvider<bool>((ref) async {
  final driveService = ref.watch(driveServiceProvider);
  return await driveService.initialize();
});

/// Provider for main Sawn folder ID
final mainFolderIdProvider = FutureProvider<String?>((ref) async {
  final driveService = ref.watch(driveServiceProvider);
  return await driveService.getOrCreateMainFolder();
});

/// Drive connection status info
class DriveStatus {
  final bool isConnected;
  final String? userEmail;
  final String? userName;
  final String? avatarUrl;

  const DriveStatus({
    required this.isConnected,
    this.userEmail,
    this.userName,
    this.avatarUrl,
  });
}

/// Provider for Drive connection status
final driveStatusProvider = Provider<DriveStatus>((ref) {
  final googleSignIn = GoogleSignInService().googleSignIn;
  final currentUser = googleSignIn.currentUser;

  if (currentUser == null) {
    return const DriveStatus(isConnected: false);
  }

  return DriveStatus(
    isConnected: true,
    userEmail: currentUser.email,
    userName: currentUser.displayName,
    avatarUrl: currentUser.photoUrl,
  );
});
