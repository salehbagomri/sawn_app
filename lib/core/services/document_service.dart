import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/document_model.dart';
import '../models/reminder_model.dart';
import 'google_drive_service.dart';
import 'notification_service.dart';
import 'offline_storage_service.dart';

/// Service for managing documents
class DocumentService {
  // Singleton instance
  static final DocumentService _instance = DocumentService._internal();
  factory DocumentService() => _instance;
  DocumentService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleDriveService _driveService = GoogleDriveService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final _uuid = const Uuid();

  // User ID from our users table (not Supabase Auth)
  String? _userId;

  /// Set the current user ID (called after login)
  void setUserId(String? userId) {
    _userId = userId;
    debugPrint('DocumentService: User ID set to: $userId');
  }

  /// Get current user ID
  String? get userId => _userId;

  // ============ Documents ============

  /// Get all documents for current user
  Future<List<DocumentModel>> getDocuments({
    DocumentCategory? category,
    DocumentStatus? status,
    bool? isFavorite,
    String? searchQuery,
  }) async {
    if (_userId == null) return [];

    try {
      // Check if online
      final isOnline = await _offlineStorage.isOnline();

      if (!isOnline) {
        // Return cached documents when offline
        debugPrint('DocumentService: Offline mode - returning cached documents');
        return _getFilteredCachedDocuments(
          category: category,
          status: status,
          isFavorite: isFavorite,
          searchQuery: searchQuery,
        );
      }

      var query = _supabase
          .from('documents')
          .select()
          .eq('user_id', _userId!);

      if (category != null) {
        // We store category in document_type column
        query = query.eq('document_type', category.nameEn);
      }

      if (isFavorite == true) {
        query = query.eq('is_favorite', true);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,document_number.ilike.%$searchQuery%,notes.ilike.%$searchQuery%');
      }

      final response = await query.order('created_at', ascending: false);

      List<DocumentModel> documents = (response as List)
          .map((json) => DocumentModel.fromJson(json))
          .toList();

      // Cache documents for offline use
      await _offlineStorage.cacheDocuments(documents);

      // Filter by status locally since it's calculated
      if (status != null) {
        documents = documents.where((d) => d.status == status).toList();
      }

      return documents;
    } catch (e) {
      debugPrint('DocumentService: Error getting documents: $e');
      // On error, try to return cached documents
      return _getFilteredCachedDocuments(
        category: category,
        status: status,
        isFavorite: isFavorite,
        searchQuery: searchQuery,
      );
    }
  }

  /// Get filtered cached documents
  List<DocumentModel> _getFilteredCachedDocuments({
    DocumentCategory? category,
    DocumentStatus? status,
    bool? isFavorite,
    String? searchQuery,
  }) {
    var documents = _offlineStorage.getAllCachedDocuments();

    // Filter by user ID
    documents = documents.where((d) => d.userId == _userId).toList();

    if (category != null) {
      documents = documents.where((d) => d.category == category).toList();
    }

    if (isFavorite == true) {
      documents = documents.where((d) => d.isFavorite).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      documents = documents.where((d) =>
        d.title.toLowerCase().contains(query) ||
        (d.documentNumber?.toLowerCase().contains(query) ?? false) ||
        (d.notes?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    if (status != null) {
      documents = documents.where((d) => d.status == status).toList();
    }

    // Sort by created_at descending
    documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return documents;
  }

  /// Get documents expiring within given days
  Future<List<DocumentModel>> getExpiringDocuments({int days = 60}) async {
    if (_userId == null) return [];

    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));

    final response = await _supabase
        .from('documents')
        .select()
        .eq('user_id', _userId!)
        .not('expiry_date', 'is', null)
        .gte('expiry_date', now.toIso8601String().split('T').first)
        .lte('expiry_date', futureDate.toIso8601String().split('T').first)
        .order('expiry_date', ascending: true);

    return (response as List)
        .map((json) => DocumentModel.fromJson(json))
        .toList();
  }

  /// Get favorite documents
  Future<List<DocumentModel>> getFavoriteDocuments() async {
    return getDocuments(isFavorite: true);
  }

  /// Get recent documents
  Future<List<DocumentModel>> getRecentDocuments({int limit = 5}) async {
    if (_userId == null) return [];

    final response = await _supabase
        .from('documents')
        .select()
        .eq('user_id', _userId!)
        .order('updated_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => DocumentModel.fromJson(json))
        .toList();
  }

  /// Get single document by ID
  Future<DocumentModel?> getDocument(String id) async {
    if (_userId == null) return null;

    final response = await _supabase
        .from('documents')
        .select()
        .eq('id', id)
        .eq('user_id', _userId!)
        .maybeSingle();

    if (response == null) return null;
    return DocumentModel.fromJson(response);
  }

  /// Create new document
  Future<DocumentModel?> createDocument({
    required String title,
    required DocumentCategory category,
    String? documentType,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    File? file,
    List<int>? reminderDays,
  }) async {
    debugPrint('=== DocumentService.createDocument ===');
    debugPrint('User ID: $_userId');

    if (_userId == null) {
      debugPrint('ERROR: User ID is null - not authenticated');
      return null;
    }

    try {
      final id = _uuid.v4();
      debugPrint('Generated document ID: $id');
      String? driveFileId;
      String? driveFileUrl;

      // Try to upload to Google Drive if file provided
      // But don't fail the whole operation if Drive upload fails
      if (file != null) {
        try {
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
                customName: '$title-$id',
              );
              driveFileId = uploadResult?.id;
              driveFileUrl = uploadResult?.webViewLink;
            }
          }
        } catch (driveError, driveStack) {
          // Log Drive error but continue saving to database
          debugPrint('Warning: Could not upload to Google Drive: $driveError');
          debugPrint('Drive stack: $driveStack');
        }
      }

      final document = DocumentModel(
        id: id,
        userId: _userId!,
        category: category,
        title: title,
        documentType: documentType,
        documentNumber: documentNumber,
        issueDate: issueDate,
        expiryDate: expiryDate,
        notes: notes,
        driveFileId: driveFileId,
        driveFileUrl: driveFileUrl,
      );

      debugPrint('Document model created, inserting to Supabase...');
      debugPrint('Document JSON: ${document.toJson()}');

      await _supabase.from('documents').insert(document.toJson());
      debugPrint('Document inserted to Supabase successfully!');

      // Create reminders if expiry date and reminder days provided
      if (expiryDate != null && reminderDays != null && reminderDays.isNotEmpty) {
        for (final days in reminderDays) {
          await createReminder(
            documentId: id,
            expiryDate: expiryDate,
            daysBefore: days,
            documentTitle: title,
            category: category,
          );
        }
      }

      return document;
    } catch (e, stackTrace) {
      debugPrint('Error creating document: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Update document
  Future<DocumentModel?> updateDocument(DocumentModel document) async {
    if (_userId == null) return null;

    try {
      final updatedDoc = document.copyWith(updatedAt: DateTime.now());

      await _supabase
          .from('documents')
          .update(updatedDoc.toJson())
          .eq('id', document.id)
          .eq('user_id', _userId!);

      return updatedDoc;
    } catch (e) {
      debugPrint('Error updating document: $e');
      return null;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String documentId) async {
    if (_userId == null) return false;

    try {
      final doc = await getDocument(documentId);
      if (doc == null) return false;

      await _supabase
          .from('documents')
          .update({
            'is_favorite': !doc.isFavorite,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', documentId)
          .eq('user_id', _userId!);

      return true;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  /// Delete document
  Future<bool> deleteDocument(String documentId) async {
    if (_userId == null) return false;

    try {
      final doc = await getDocument(documentId);
      if (doc == null) return false;

      // Delete from Google Drive
      if (doc.driveFileId != null) {
        await _driveService.deleteFile(doc.driveFileId!);
      }

      // Delete reminders first (foreign key constraint)
      await _supabase
          .from('reminders')
          .delete()
          .eq('document_id', documentId);

      // Delete document
      await _supabase
          .from('documents')
          .delete()
          .eq('id', documentId)
          .eq('user_id', _userId!);

      return true;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return false;
    }
  }

  // ============ Categories ============

  /// Get document count per category
  /// Note: We use 'document_type' column to store category
  Future<Map<String, int>> getCategoryCounts() async {
    if (_userId == null) return {};

    try {
      final response = await _supabase
          .from('documents')
          .select('document_type')
          .eq('user_id', _userId!);

      final Map<String, int> counts = {};
      for (final doc in response as List) {
        final category = doc['document_type'] as String? ?? 'personal';
        counts[category] = (counts[category] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('Error getting category counts: $e');
      return {};
    }
  }

  // ============ Reminders ============

  /// Create reminder for document
  Future<ReminderModel?> createReminder({
    required String documentId,
    required DateTime expiryDate,
    required int daysBefore,
    String? documentTitle,
    DocumentCategory? category,
  }) async {
    if (_userId == null) return null;

    try {
      final id = _uuid.v4();
      final remindDate = expiryDate.subtract(Duration(days: daysBefore));

      final reminder = ReminderModel(
        id: id,
        documentId: documentId,
        userId: _userId!,
        remindDate: remindDate,
        daysBefore: daysBefore,
      );

      await _supabase.from('reminders').insert(reminder.toJson());

      // Schedule local notification
      if (documentTitle != null && category != null) {
        await NotificationService().scheduleReminder(
          reminder: reminder,
          documentTitle: documentTitle,
          category: category,
        );
      }

      return reminder;
    } catch (e) {
      debugPrint('Error creating reminder: $e');
      return null;
    }
  }

  /// Get all reminders for current user
  Future<List<ReminderModel>> getReminders({bool onlyUnread = false}) async {
    if (_userId == null) return [];

    try {
      // Note: We select document_type instead of category since that's where we store it
      var query = _supabase
          .from('reminders')
          .select('*, documents(title, document_type)')
          .eq('user_id', _userId!);

      if (onlyUnread) {
        query = query.eq('is_read', false);
      }

      final response = await query.order('remind_date', ascending: true);

      return (response as List)
          .map((json) => ReminderModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting reminders: $e');
      return [];
    }
  }

  /// Get due reminders (today and past)
  Future<List<ReminderModel>> getDueReminders() async {
    if (_userId == null) return [];

    try {
      final today = DateTime.now().toIso8601String().split('T').first;

      final response = await _supabase
          .from('reminders')
          .select('*, documents(title, document_type)')
          .eq('user_id', _userId!)
          .eq('is_read', false)
          .lte('remind_date', today)
          .order('remind_date', ascending: false);

      return (response as List)
          .map((json) => ReminderModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting due reminders: $e');
      return [];
    }
  }

  /// Mark reminder as read
  Future<bool> markReminderRead(String reminderId) async {
    if (_userId == null) return false;

    try {
      await _supabase
          .from('reminders')
          .update({'is_read': true})
          .eq('id', reminderId)
          .eq('user_id', _userId!);

      return true;
    } catch (e) {
      debugPrint('Error marking reminder as read: $e');
      return false;
    }
  }

  /// Delete reminder
  Future<bool> deleteReminder(String reminderId) async {
    if (_userId == null) return false;

    try {
      // Cancel the scheduled notification
      await NotificationService().cancelReminder(reminderId);

      await _supabase
          .from('reminders')
          .delete()
          .eq('id', reminderId)
          .eq('user_id', _userId!);

      return true;
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
      return false;
    }
  }

  // ============ Statistics ============

  /// Get document statistics
  Future<Map<String, dynamic>> getStatistics() async {
    if (_userId == null) {
      return {
        'total': 0,
        'expiringSoon': 0,
        'expired': 0,
        'favorites': 0,
      };
    }

    try {
      final documents = await getDocuments();

      return {
        'total': documents.length,
        'expiringSoon': documents.where((d) => d.status == DocumentStatus.expiringSoon).length,
        'expired': documents.where((d) => d.status == DocumentStatus.expired).length,
        'favorites': documents.where((d) => d.isFavorite).length,
      };
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {
        'total': 0,
        'expiringSoon': 0,
        'expired': 0,
        'favorites': 0,
      };
    }
  }
}
