import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/document_model.dart';
import 'document_service.dart';
import 'offline_storage_service.dart';

/// Service for synchronizing local and remote data
class SyncService {
  // Singleton instance
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DocumentService _documentService = DocumentService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();

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

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isOnline = results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet);

    debugPrint('SyncService: Connectivity changed, online: $isOnline');

    if (isOnline && _offlineStorage.hasPendingSync) {
      await syncPendingChanges();
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
      // The document was already created locally, now we need to sync to server
      // For now, we assume it's already in Supabase (created when online)
      debugPrint('SyncService: Sync create for $documentId');
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
      final document = DocumentModel.fromJson(data);
      final result = await _documentService.updateDocument(document);
      return result != null;
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
