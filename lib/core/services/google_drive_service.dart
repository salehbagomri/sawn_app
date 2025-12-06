import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';
import 'google_sign_in_service.dart';

/// Google Drive service for file operations
class GoogleDriveService {
  final GoogleSignIn _googleSignIn;
  drive.DriveApi? _driveApi;

  GoogleDriveService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignInService().googleSignIn;

  /// Initialize Drive API
  Future<bool> initialize() async {
    try {
      debugPrint('GoogleDriveService: Initializing...');
      debugPrint('GoogleDriveService: Current user: ${_googleSignIn.currentUser?.email}');

      if (_googleSignIn.currentUser == null) {
        debugPrint('GoogleDriveService: No signed-in user found');
        return false;
      }

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        debugPrint('GoogleDriveService: Failed to get authenticated client');
        return false;
      }

      _driveApi = drive.DriveApi(httpClient);
      debugPrint('GoogleDriveService: Drive API initialized successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('GoogleDriveService: Error initializing Drive API: $e');
      debugPrint('GoogleDriveService: Stack trace: $stackTrace');
      return false;
    }
  }

  /// Check if Drive API is ready
  bool get isReady => _driveApi != null;

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _driveApi = null;
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
  }

  /// Get or create the main Sawn folder
  Future<String?> getOrCreateMainFolder() async {
    if (_driveApi == null) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    try {
      // Search for existing folder
      final existingFolder = await _findFolder(AppConstants.driveFolderName);
      if (existingFolder != null) {
        return existingFolder;
      }

      // Create new folder
      return await _createFolder(AppConstants.driveFolderName);
    } catch (e) {
      debugPrint('Error getting/creating main folder: $e');
      return null;
    }
  }

  /// Get or create a category subfolder
  Future<String?> getOrCreateCategoryFolder(
    String categoryName,
    String parentFolderId,
  ) async {
    if (_driveApi == null) return null;

    try {
      // Search for existing subfolder
      final existingFolder = await _findFolder(categoryName, parentFolderId);
      if (existingFolder != null) {
        return existingFolder;
      }

      // Create new subfolder
      return await _createFolder(categoryName, parentFolderId);
    } catch (e) {
      debugPrint('Error getting/creating category folder: $e');
      return null;
    }
  }

  /// Find a folder by name
  Future<String?> _findFolder(String name, [String? parentId]) async {
    if (_driveApi == null) return null;

    try {
      String query = "name = '$name' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      if (parentId != null) {
        query += " and '$parentId' in parents";
      }

      final response = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (response.files != null && response.files!.isNotEmpty) {
        return response.files!.first.id;
      }

      return null;
    } catch (e) {
      debugPrint('Error finding folder: $e');
      return null;
    }
  }

  /// Create a folder
  Future<String?> _createFolder(String name, [String? parentId]) async {
    if (_driveApi == null) return null;

    try {
      final folder = drive.File()
        ..name = name
        ..mimeType = 'application/vnd.google-apps.folder';

      if (parentId != null) {
        folder.parents = [parentId];
      }

      final response = await _driveApi!.files.create(folder);
      return response.id;
    } catch (e) {
      debugPrint('Error creating folder: $e');
      return null;
    }
  }

  /// Upload a file to Drive
  Future<DriveFileResult?> uploadFile({
    required File file,
    required String folderId,
    String? customName,
  }) async {
    if (_driveApi == null) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    try {
      final fileName = customName ?? path.basename(file.path);
      final mimeType = _getMimeType(file.path);

      final driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId];

      final media = drive.Media(
        file.openRead(),
        file.lengthSync(),
      );

      final response = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, name, webViewLink, webContentLink, thumbnailLink',
      );

      return DriveFileResult(
        id: response.id!,
        name: response.name!,
        webViewLink: response.webViewLink,
        webContentLink: response.webContentLink,
        thumbnailLink: response.thumbnailLink,
      );
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  /// Download a file from Drive
  Future<Uint8List?> downloadFile(String fileId) async {
    if (_driveApi == null) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    try {
      final response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error downloading file: $e');
      return null;
    }
  }

  /// Delete a file from Drive
  Future<bool> deleteFile(String fileId) async {
    if (_driveApi == null) return false;

    try {
      await _driveApi!.files.delete(fileId);
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  /// Update/replace a file in Drive
  Future<DriveFileResult?> updateFile({
    required String fileId,
    required File newFile,
  }) async {
    if (_driveApi == null) return null;

    try {
      final media = drive.Media(
        newFile.openRead(),
        newFile.lengthSync(),
      );

      final response = await _driveApi!.files.update(
        drive.File(),
        fileId,
        uploadMedia: media,
        $fields: 'id, name, webViewLink, webContentLink, thumbnailLink',
      );

      return DriveFileResult(
        id: response.id!,
        name: response.name!,
        webViewLink: response.webViewLink,
        webContentLink: response.webContentLink,
        thumbnailLink: response.thumbnailLink,
      );
    } catch (e) {
      debugPrint('Error updating file: $e');
      return null;
    }
  }

  /// Get file metadata
  Future<drive.File?> getFileMetadata(String fileId) async {
    if (_driveApi == null) return null;

    try {
      return await _driveApi!.files.get(
        fileId,
        $fields: 'id, name, mimeType, size, createdTime, modifiedTime, webViewLink, thumbnailLink',
      ) as drive.File;
    } catch (e) {
      debugPrint('Error getting file metadata: $e');
      return null;
    }
  }

  /// List files in a folder
  Future<List<drive.File>> listFilesInFolder(String folderId) async {
    if (_driveApi == null) return [];

    try {
      final response = await _driveApi!.files.list(
        q: "'$folderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, mimeType, size, createdTime, thumbnailLink)',
      );

      return response.files ?? [];
    } catch (e) {
      debugPrint('Error listing files: $e');
      return [];
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.pdf':
        return 'application/pdf';
      case '.heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Result of a Drive file operation
class DriveFileResult {
  final String id;
  final String name;
  final String? webViewLink;
  final String? webContentLink;
  final String? thumbnailLink;

  const DriveFileResult({
    required this.id,
    required this.name,
    this.webViewLink,
    this.webContentLink,
    this.thumbnailLink,
  });
}
