import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_model.dart';
import 'document_service.dart';
import 'offline_storage_service.dart';
import 'google_drive_service.dart';

/// Service for synchronizing local and remote data
class SyncService {
  // Singleton instance
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DocumentService _documentService = DocumentService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final GoogleDriveService _driveService = GoogleDriveService();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  /// Sync status notifier
  final ValueNotifier<SyncStatus> syncStatus = ValueNotifier(SyncStatus.idle);

  /// Initialize sync service and start listening for connectivity changes
  Future<void> initialize() async {
    debugPrint('SyncService: Initializing...');

    await _offlineStorage.initialize();

    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Check initial connectivity and sync if online
    final isOnline = await _offlineStorage.isOnline();
    if (isOnline && _offlineStorage.hasPendingSync) {
      await syncPendingChanges();
    }

    debugPrint('SyncService: Initialized');
  }

  /// Callback to refresh providers after sync
  VoidCallback? onDataRefreshNeeded;

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isOnline = results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet);

    debugPrint('SyncService: Connectivity changed, online: $isOnline');

    if (isOnline) {
      // First sync pending changes to server
      if (_offlineStorage.hasPendingSync) {
        debugPrint('SyncService: Syncing pending changes first...');
        await syncPendingChanges();
        // Longer delay to ensure server processed the changes
        await Future.delayed(const Duration(seconds: 1));
      }

      // Then refresh data from server and MERGE with cache (never replace)
      debugPrint('SyncService: Refreshing data from server...');
      await refreshAndMergeData();

      // Notify listeners to refresh UI
      debugPrint('SyncService: Notifying UI to refresh...');
      onDataRefreshNeeded?.call();
    }
  }

  /// Sync pending changes to server
  Future<SyncResult> syncPendingChanges() async {
    if (_isSyncing) {
      debugPrint('SyncService: Already syncing, skipping...');
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    final isOnline = await _offlineStorage.isOnline();
    if (!isOnline) {
      debugPrint('SyncService: Offline, cannot sync');
      return SyncResult(success: false, message: 'No internet connection');
    }

    _isSyncing = true;
    syncStatus.value = SyncStatus.syncing;

    try {
      debugPrint('SyncService: Starting sync...');

      final pendingItems = _offlineStorage.getPendingSyncItems();
      debugPrint('SyncService: Found ${pendingItems.length} pending items');

      int successCount = 0;
      int failCount = 0;

      for (final item in pendingItems) {
        final operationType = item['operationType'] as String;
        final documentId = item['documentId'] as String;
        final data = item['data'] as Map<String, dynamic>?;

        bool success = false;

        switch (operationType) {
          case 'create':
            success = await _syncCreate(documentId, data);
            break;
          case 'update':
            success = await _syncUpdate(documentId, data);
            break;
          case 'delete':
            success = await _syncDelete(documentId);
            break;
        }

        if (success) {
          await _offlineStorage.removePendingSync(documentId);
          successCount++;
        } else {
          failCount++;
        }
      }

      await _offlineStorage.setLastSyncTime(DateTime.now());

      syncStatus.value = SyncStatus.idle;
      _isSyncing = false;

      final message = 'Synced $successCount items, $failCount failed';
      debugPrint('SyncService: $message');

      return SyncResult(
        success: failCount == 0,
        message: message,
        syncedCount: successCount,
        failedCount: failCount,
      );
    } catch (e, stackTrace) {
      debugPrint('SyncService: Error syncing: $e');
      debugPrint('Stack trace: $stackTrace');

      syncStatus.value = SyncStatus.error;
      _isSyncing = false;

      return SyncResult(success: false, message: e.toString());
    }
  }

  /// Sync create operation
  Future<bool> _syncCreate(String documentId, Map<String, dynamic>? data) async {
    if (data == null) return false;

    try {
      debugPrint('SyncService: Syncing create for document $documentId');

      // Remove reminder_days from data before inserting to Supabase
      final reminderDays = data.remove('reminder_days') as List<dynamic>?;

      // Mark as synced (not offline anymore)
      data['is_offline'] = false;

      // Try to upload file to Google Drive if auto backup is enabled
      // ONLY if file hasn't been uploaded yet (no drive_file_id)
      String? driveFileId = data['drive_file_id'] as String?;
      String? driveFileUrl = data['drive_file_url'] as String?;

      if (driveFileId == null && _offlineStorage.autoBackupEnabled) {
        final cachedFilePath = await _offlineStorage.getCachedFilePath(documentId);
        if (cachedFilePath != null) {
          final file = File(cachedFilePath);
          if (await file.exists()) {
            try {
              debugPrint('SyncService: Uploading file to Google Drive...');
              final category = DocumentCategory.fromString(data['document_type'] as String? ?? 'personal');
              final title = data['title'] as String? ?? 'مستند';

              // Get main folder first
              final mainFolder = await _driveService.getOrCreateMainFolder();
              if (mainFolder != null) {
                // Get or create category folder
                final categoryFolder = await _driveService.getOrCreateCategoryFolder(
                  category.nameAr,
                  mainFolder,
                );
                if (categoryFolder != null) {
                  final uploadResult = await _driveService.uploadFile(
                    file: file,
                    folderId: categoryFolder,
                    customName: '$title-$documentId',
                  );
                  driveFileId = uploadResult?.id;
                  driveFileUrl = uploadResult?.webViewLink;
                  debugPrint('SyncService: File uploaded to Drive: $driveFileId');
                }
              }
            } catch (driveError) {
              debugPrint('SyncService: Warning - Could not upload to Drive: $driveError');
              // Continue without Drive upload
            }
          }
        }
      } else if (driveFileId != null) {
        debugPrint('SyncService: File already uploaded to Drive, skipping upload');
      }

      // Update data with Drive info if uploaded
      if (driveFileId != null) {
        data['drive_file_id'] = driveFileId;
        data['drive_file_url'] = driveFileUrl;
      }

      // Insert to Supabase
      await Supabase.instance.client
          .from('documents')
          .insert(data);

      debugPrint('SyncService: Document synced to Supabase successfully');

      // Update local cache to mark as synced with Drive info
      final document = DocumentModel.fromJson(data);
      await _offlineStorage.cacheDocument(document.copyWith(
        isOffline: false,
        driveFileId: driveFileId,
        driveFileUrl: driveFileUrl,
      ));

      // Mark as recently synced to protect from stale server data
      _offlineStorage.markAsRecentlySynced(documentId);

      // Create reminders in Supabase if we have reminder days
      if (reminderDays != null && reminderDays.isNotEmpty && data['expiry_date'] != null) {
        final expiryDate = DateTime.parse(data['expiry_date'] as String);
        final category = DocumentCategory.fromString(data['document_type'] as String? ?? 'personal');

        for (final days in reminderDays) {
          await _documentService.createReminder(
            documentId: documentId,
            expiryDate: expiryDate,
            daysBefore: days as int,
            documentTitle: data['title'] as String?,
            category: category,
          );
        }
        debugPrint('SyncService: Created ${reminderDays.length} reminders');
      }

      return true;
    } catch (e) {
      debugPrint('SyncService: Error syncing create: $e');
      return false;
    }
  }

  /// Sync update operation
  Future<bool> _syncUpdate(String documentId, Map<String, dynamic>? data) async {
    if (data == null) return false;

    try {
      debugPrint('SyncService: Syncing update for document $documentId with data: $data');

      // Get current user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('SyncService: No user ID, cannot sync update');
        return false;
      }

      // Update only the specific fields in Supabase
      await Supabase.instance.client
          .from('documents')
          .update(data)
          .eq('id', documentId)
          .eq('user_id', userId);

      debugPrint('SyncService: Update synced successfully');

      // Update local cache with the synced values to ensure consistency
      final cachedDoc = _offlineStorage.getCachedDocument(documentId);
      if (cachedDoc != null) {
        // Apply the synced changes to cached document
        DocumentModel updatedDoc = cachedDoc;
        if (data.containsKey('is_favorite')) {
          updatedDoc = updatedDoc.copyWith(isFavorite: data['is_favorite'] as bool);
        }
        if (data.containsKey('updated_at')) {
          updatedDoc = updatedDoc.copyWith(
            updatedAt: DateTime.parse(data['updated_at'] as String),
          );
        }
        // Mark as synced (not offline)
        updatedDoc = updatedDoc.copyWith(isOffline: false);
        await _offlineStorage.cacheDocument(updatedDoc);

        // Mark as recently synced to protect from stale server data
        _offlineStorage.markAsRecentlySynced(documentId);
        debugPrint('SyncService: Updated local cache with synced values');
      }

      return true;
    } catch (e) {
      debugPrint('SyncService: Error syncing update: $e');
      return false;
    }
  }

  /// Sync delete operation
  Future<bool> _syncDelete(String documentId) async {
    try {
      return await _documentService.deleteDocument(documentId);
    } catch (e) {
      debugPrint('SyncService: Error syncing delete: $e');
      return false;
    }
  }

  /// Fetch and cache documents from server
  Future<void> refreshDocumentsCache() async {
    final isOnline = await _offlineStorage.isOnline();
    if (!isOnline) {
      debugPrint('SyncService: Offline, cannot refresh cache');
      return;
    }

    try {
      syncStatus.value = SyncStatus.syncing;

      final documents = await _documentService.getDocuments();
      await _offlineStorage.cacheDocuments(documents);
      await _offlineStorage.setLastSyncTime(DateTime.now());

      syncStatus.value = SyncStatus.idle;
      debugPrint('SyncService: Refreshed cache with ${documents.length} documents');
    } catch (e) {
      debugPrint('SyncService: Error refreshing cache: $e');
      syncStatus.value = SyncStatus.error;
    }
  }

  /// Refresh data from server and merge with local cache
  /// preserveLocalChanges: if false, replace cache completely (after successful sync)
  Future<void> refreshAndMergeData({bool preserveLocalChanges = true}) async {
    final isOnline = await _offlineStorage.isOnline();
    if (!isOnline) {
      debugPrint('SyncService: Offline, cannot refresh');
      return;
    }

    try {
      syncStatus.value = SyncStatus.syncing;
      debugPrint('SyncService: Refreshing data from server (preserveLocalChanges: $preserveLocalChanges)...');

      // Get user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('SyncService: No user ID');
        syncStatus.value = SyncStatus.idle;
        return;
      }

      // Fetch fresh documents from server
      final response = await Supabase.instance.client
          .from('documents')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final serverDocuments = (response as List)
          .map((json) => DocumentModel.fromJson(json))
          .toList();

      debugPrint('SyncService: Fetched ${serverDocuments.length} documents from server');

      // Cache all documents (preserve local changes if needed)
      await _offlineStorage.cacheDocuments(serverDocuments, preserveLocalChanges: preserveLocalChanges);
      await _offlineStorage.setLastSyncTime(DateTime.now());

      syncStatus.value = SyncStatus.idle;
      debugPrint('SyncService: Data refresh complete');
    } catch (e) {
      debugPrint('SyncService: Error refreshing data: $e');
      syncStatus.value = SyncStatus.error;
    }
  }

  /// Get documents (from cache if offline, from server if online)
  Future<List<DocumentModel>> getDocuments({bool forceRefresh = false}) async {
    final isOnline = await _offlineStorage.isOnline();

    if (isOnline && (forceRefresh || !_hasFreshCache())) {
      try {
        final documents = await _documentService.getDocuments();
        await _offlineStorage.cacheDocuments(documents);
        await _offlineStorage.setLastSyncTime(DateTime.now());
        return documents;
      } catch (e) {
        debugPrint('SyncService: Error fetching documents, using cache: $e');
        return _offlineStorage.getAllCachedDocuments();
      }
    } else {
      // Offline or cache is fresh
      return _offlineStorage.getAllCachedDocuments();
    }
  }

  /// Check if cache is fresh (less than 5 minutes old)
  bool _hasFreshCache() {
    final lastSync = _offlineStorage.lastSyncTime;
    if (lastSync == null) return false;

    final difference = DateTime.now().difference(lastSync);
    return difference.inMinutes < 5;
  }

  /// Get document by ID (from cache if offline)
  Future<DocumentModel?> getDocument(String id) async {
    final isOnline = await _offlineStorage.isOnline();

    if (isOnline) {
      try {
        final document = await _documentService.getDocument(id);
        if (document != null) {
          await _offlineStorage.cacheDocument(document);
        }
        return document;
      } catch (e) {
        debugPrint('SyncService: Error fetching document, using cache: $e');
        return _offlineStorage.getCachedDocument(id);
      }
    } else {
      return _offlineStorage.getCachedDocument(id);
    }
  }

  /// Get pending sync count
  int get pendingSyncCount => _offlineStorage.pendingSyncCount;

  /// Check if has pending sync
  bool get hasPendingSync => _offlineStorage.hasPendingSync;

  /// Get last sync time
  DateTime? get lastSyncTime => _offlineStorage.lastSyncTime;

  /// Dispose
  void dispose() {
    _connectivitySubscription?.cancel();
    syncStatus.dispose();
  }
}

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  error,
}

/// Result of sync operation
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;

  const SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.failedCount = 0,
  });
}
