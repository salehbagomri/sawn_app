import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_drive_service.dart';

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
