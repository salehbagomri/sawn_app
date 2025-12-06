import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/document_model.dart';

/// Service for offline storage using Hive
class OfflineStorageService {
  // Singleton instance
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  // Box names
  static const String _documentsBox = 'documents_cache';
  static const String _pendingSyncBox = 'pending_sync';
  static const String _settingsBox = 'offline_settings';

  Box<Map>? _documents;
  Box<Map>? _pendingSync;
  Box? _settings;

  bool _isInitialized = false;

  /// Initialize the offline storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('OfflineStorageService: Initializing...');

    try {
      _documents = await Hive.openBox<Map>(_documentsBox);
      _pendingSync = await Hive.openBox<Map>(_pendingSyncBox);
      _settings = await Hive.openBox(_settingsBox);

      _isInitialized = true;
      debugPrint('OfflineStorageService: Initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('OfflineStorageService: Error initializing: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Check if online
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.ethernet);
  }

  /// Listen to connectivity changes
  Stream<bool> get connectivityStream {
    return Connectivity().onConnectivityChanged.map((results) {
      return results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.ethernet);
    });
  }

  // ============ Documents Cache ============

  /// Cache a document locally
  Future<void> cacheDocument(DocumentModel document) async {
    if (!_isInitialized) await initialize();

    try {
      await _documents?.put(document.id, document.toJson());
      debugPrint('OfflineStorageService: Cached document ${document.id}');
    } catch (e) {
      debugPrint('OfflineStorageService: Error caching document: $e');
    }
  }

  /// Cache multiple documents
  Future<void> cacheDocuments(List<DocumentModel> documents) async {
    if (!_isInitialized) await initialize();

    try {
      final entries = <String, Map>{};
      for (final doc in documents) {
        entries[doc.id] = doc.toJson();
      }
      await _documents?.putAll(entries);
      debugPrint('OfflineStorageService: Cached ${documents.length} documents');
    } catch (e) {
      debugPrint('OfflineStorageService: Error caching documents: $e');
    }
  }

  /// Get cached document by ID
  DocumentModel? getCachedDocument(String id) {
    if (_documents == null) return null;

    try {
      final data = _documents!.get(id);
      if (data == null) return null;

      return DocumentModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('OfflineStorageService: Error getting cached document: $e');
      return null;
    }
  }

  /// Get all cached documents
  List<DocumentModel> getAllCachedDocuments() {
    if (_documents == null) return [];

    try {
      return _documents!.values.map((data) {
        return DocumentModel.fromJson(Map<String, dynamic>.from(data));
      }).toList();
    } catch (e) {
      debugPrint('OfflineStorageService: Error getting cached documents: $e');
      return [];
    }
  }

  /// Remove cached document
  Future<void> removeCachedDocument(String id) async {
    if (!_isInitialized) await initialize();

    try {
      await _documents?.delete(id);
      debugPrint('OfflineStorageService: Removed cached document $id');
    } catch (e) {
      debugPrint('OfflineStorageService: Error removing cached document: $e');
    }
  }

  /// Clear all cached documents
  Future<void> clearDocumentsCache() async {
    if (!_isInitialized) await initialize();

    try {
      await _documents?.clear();
      debugPrint('OfflineStorageService: Cleared documents cache');
    } catch (e) {
      debugPrint('OfflineStorageService: Error clearing cache: $e');
    }
  }

  // ============ Pending Sync Queue ============

  /// Add operation to pending sync queue
  Future<void> addPendingSync({
    required String operationType, // 'create', 'update', 'delete'
    required String documentId,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final syncItem = {
        'operationType': operationType,
        'documentId': documentId,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _pendingSync?.put(documentId, syncItem);
      debugPrint('OfflineStorageService: Added pending sync for $documentId');
    } catch (e) {
      debugPrint('OfflineStorageService: Error adding pending sync: $e');
    }
  }

  /// Get all pending sync items
  List<Map<String, dynamic>> getPendingSyncItems() {
    if (_pendingSync == null) return [];

    try {
      return _pendingSync!.values.map((data) {
        return Map<String, dynamic>.from(data);
      }).toList();
    } catch (e) {
      debugPrint('OfflineStorageService: Error getting pending sync items: $e');
      return [];
    }
  }

  /// Remove pending sync item
  Future<void> removePendingSync(String documentId) async {
    if (!_isInitialized) await initialize();

    try {
      await _pendingSync?.delete(documentId);
      debugPrint('OfflineStorageService: Removed pending sync for $documentId');
    } catch (e) {
      debugPrint('OfflineStorageService: Error removing pending sync: $e');
    }
  }

  /// Get pending sync count
  int get pendingSyncCount => _pendingSync?.length ?? 0;

  /// Check if has pending sync
  bool get hasPendingSync => pendingSyncCount > 0;

  /// Clear all pending sync items
  Future<void> clearPendingSync() async {
    if (!_isInitialized) await initialize();

    try {
      await _pendingSync?.clear();
      debugPrint('OfflineStorageService: Cleared pending sync');
    } catch (e) {
      debugPrint('OfflineStorageService: Error clearing pending sync: $e');
    }
  }

  // ============ Settings ============

  /// Get last sync time
  DateTime? get lastSyncTime {
    final timestamp = _settings?.get('lastSyncTime') as String?;
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  /// Set last sync time
  Future<void> setLastSyncTime(DateTime time) async {
    await _settings?.put('lastSyncTime', time.toIso8601String());
  }

  /// Check if offline mode is enabled
  bool get offlineModeEnabled {
    return _settings?.get('offlineModeEnabled', defaultValue: true) ?? true;
  }

  /// Set offline mode enabled
  Future<void> setOfflineModeEnabled(bool enabled) async {
    await _settings?.put('offlineModeEnabled', enabled);
  }

  // ============ File Cache ============

  /// Get local cache directory
  Future<Directory> get _cacheDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/document_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Cache file locally
  Future<String?> cacheFile(String documentId, File file) async {
    try {
      final cacheDir = await _cacheDir;
      final extension = file.path.split('.').last;
      final cachedPath = '${cacheDir.path}/$documentId.$extension';

      await file.copy(cachedPath);
      debugPrint('OfflineStorageService: Cached file at $cachedPath');

      return cachedPath;
    } catch (e) {
      debugPrint('OfflineStorageService: Error caching file: $e');
      return null;
    }
  }

  /// Get cached file
  File? getCachedFile(String documentId, String extension) {
    try {
      // Sync operation - check if file exists
      final appDocPath = Platform.environment['APPDATA'] ?? '';
      if (appDocPath.isEmpty) return null;

      // This is a simplified check - in production you'd want to use path_provider properly
      return null; // Will be implemented with proper async handling
    } catch (e) {
      debugPrint('OfflineStorageService: Error getting cached file: $e');
      return null;
    }
  }

  /// Delete cached file
  Future<void> deleteCachedFile(String documentId) async {
    try {
      final cacheDir = await _cacheDir;
      final files = await cacheDir.list().toList();

      for (final file in files) {
        if (file.path.contains(documentId)) {
          await file.delete();
          debugPrint('OfflineStorageService: Deleted cached file ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('OfflineStorageService: Error deleting cached file: $e');
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _cacheDir;
      int totalSize = 0;

      await for (final file in cacheDir.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('OfflineStorageService: Error getting cache size: $e');
      return 0;
    }
  }

  /// Clear file cache
  Future<void> clearFileCache() async {
    try {
      final cacheDir = await _cacheDir;
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
      debugPrint('OfflineStorageService: Cleared file cache');
    } catch (e) {
      debugPrint('OfflineStorageService: Error clearing file cache: $e');
    }
  }

  /// Close all boxes
  Future<void> close() async {
    await _documents?.close();
    await _pendingSync?.close();
    await _settings?.close();
    _isInitialized = false;
  }
}
