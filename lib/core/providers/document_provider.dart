import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document_model.dart';
import '../models/reminder_model.dart';
import '../services/document_service.dart';
import './auth_provider.dart';

/// Provider for DocumentService
/// This provider watches auth state and sets userId accordingly
final documentServiceProvider = Provider<DocumentService>((ref) {
  final service = DocumentService();

  // Watch the current user and update service whenever it changes
  final userAsync = ref.watch(currentUserProvider);
  userAsync.whenData((user) {
    debugPrint('documentServiceProvider: Setting userId to ${user?.id}');
    service.setUserId(user?.id);
  });

  return service;
});

/// Provider for all documents
final documentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  final service = ref.watch(documentServiceProvider);
  return await service.getDocuments();
});

/// Provider for documents by category
final documentsByCategoryProvider = FutureProvider.family<List<DocumentModel>, DocumentCategory>((ref, category) async {
  final service = ref.watch(documentServiceProvider);
  return await service.getDocuments(category: category);
});

/// Provider for expiring documents (within 60 days)
final expiringDocumentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  final service = ref.watch(documentServiceProvider);
  return await service.getExpiringDocuments(days: 60);
});

/// Provider for favorite documents
final favoriteDocumentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  final service = ref.watch(documentServiceProvider);
  return await service.getFavoriteDocuments();
});

/// Provider for recent documents
final recentDocumentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  final service = ref.watch(documentServiceProvider);
  return await service.getRecentDocuments(limit: 5);
});

/// Provider for category counts
final categoryCounts = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.watch(documentServiceProvider);
  return await service.getCategoryCounts();
});

/// Provider for document statistics
final documentStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(documentServiceProvider);
  return await service.getStatistics();
});

/// Provider for single document
final documentProvider = FutureProvider.family<DocumentModel?, String>((ref, id) async {
  final service = ref.watch(documentServiceProvider);
  return await service.getDocument(id);
});

/// Alias for documentProvider (for better readability)
final documentByIdProvider = documentProvider;

/// Provider for document reminders
final documentRemindersProvider = FutureProvider.family<List<ReminderModel>, String>((ref, documentId) async {
  final service = ref.watch(documentServiceProvider);
  final allReminders = await service.getReminders();
  return allReminders.where((r) => r.documentId == documentId).toList();
});

/// Provider for all reminders
final remindersProvider = FutureProvider<List<ReminderModel>>((ref) async {
  final service = ref.watch(documentServiceProvider);
  return await service.getReminders();
});

/// Provider for due reminders
final dueRemindersProvider = FutureProvider<List<ReminderModel>>((ref) async {
  final service = ref.watch(documentServiceProvider);
  return await service.getDueReminders();
});

/// Provider for unread reminders count
final unreadRemindersCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(documentServiceProvider);
  final reminders = await service.getDueReminders();
  return reminders.length;
});

/// Notifier for managing documents state
class DocumentsNotifier extends StateNotifier<AsyncValue<List<DocumentModel>>> {
  final DocumentService _service;
  final Ref _ref;

  DocumentsNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    state = const AsyncValue.loading();
    try {
      final documents = await _service.getDocuments();
      state = AsyncValue.data(documents);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await loadDocuments();
    // Invalidate related providers
    _ref.invalidate(expiringDocumentsProvider);
    _ref.invalidate(favoriteDocumentsProvider);
    _ref.invalidate(recentDocumentsProvider);
    _ref.invalidate(categoryCounts);
    _ref.invalidate(documentStatsProvider);
  }

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
    final doc = await _service.createDocument(
      title: title,
      category: category,
      documentType: documentType,
      documentNumber: documentNumber,
      issueDate: issueDate,
      expiryDate: expiryDate,
      notes: notes,
      file: file,
      reminderDays: reminderDays,
    );

    if (doc != null) {
      await refresh();
    }

    return doc;
  }

  Future<bool> updateDocument(DocumentModel document) async {
    final updated = await _service.updateDocument(document);
    if (updated != null) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> toggleFavorite(String documentId) async {
    final success = await _service.toggleFavorite(documentId);
    if (success) {
      await refresh();
    }
    return success;
  }

  Future<bool> deleteDocument(String documentId) async {
    final success = await _service.deleteDocument(documentId);
    if (success) {
      await refresh();
    }
    return success;
  }
}

/// Provider for documents notifier
final documentsNotifierProvider = StateNotifierProvider<DocumentsNotifier, AsyncValue<List<DocumentModel>>>((ref) {
  final service = ref.watch(documentServiceProvider);
  return DocumentsNotifier(service, ref);
});

/// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered documents based on search
final filteredDocumentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final service = ref.watch(documentServiceProvider);
  return await service.getDocuments(searchQuery: query);
});

/// Selected category filter provider
final selectedCategoryProvider = StateProvider<DocumentCategory?>((ref) => null);

/// Selected status filter provider
final selectedStatusProvider = StateProvider<DocumentStatus?>((ref) => null);
