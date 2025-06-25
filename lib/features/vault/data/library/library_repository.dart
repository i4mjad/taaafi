import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'models/cursor_content.dart';
import 'models/cursor_content_list.dart';
import 'models/cursor_content_type.dart';
import 'models/cursor_content_category.dart';
import 'models/cursor_content_owner.dart';

class LibraryRepository {
  final FirebaseFirestore _firestore;
  final Ref ref;

  LibraryRepository(this._firestore, this.ref);

  CursorContentType _mapDocumentToType(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return CursorContentType(
        id: doc.id,
        name: data['contentTypeName'] as String,
        nameAr: data['contentTypeNameAr'] as String?,
        iconName: data['contentTypeIconName'] as String,
        isActive: data['isActive'] as bool,
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  CursorContentOwner _mapDocumentToOwner(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return CursorContentOwner(
        id: doc.id,
        name: data['ownerName'] as String,
        nameAr: data['ownerNameAr'] as String?,
        source: data['ownerSource'] as String,
        isActive: data['isActive'] as bool,
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  CursorContentCategory _mapDocumentToCategory(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return CursorContentCategory(
        id: doc.id,
        name: data['categoryName'] as String,
        nameAr: data['categoryNameAr'] as String?,
        iconName: data['contentCategoryIconName'] as String,
        isActive: data['isActive'] as bool,
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<CursorContent> _mapDocumentToContent(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;

      final categoryDoc = await _firestore
          .collection('contentCategories')
          .doc(data['contentCategoryId'] as String)
          .get();

      final ownerDoc = await _firestore
          .collection('contentOwners')
          .doc(data['contentOwnerId'] as String)
          .get();

      final typeDoc = await _firestore
          .collection('contentTypes')
          .doc(data['contentTypeId'] as String)
          .get();

      return CursorContent(
        id: doc.id,
        category: _mapDocumentToCategory(categoryDoc),
        language: data['contentLanguage'] as String,
        link: data['contentLink'] as String,
        name: data['contentName'] as String,
        nameAr: data['contentNameAr'] as String?,
        owner: _mapDocumentToOwner(ownerDoc),
        type: _mapDocumentToType(typeDoc),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        isActive: data['isActive'] as bool,
        isDeleted: data['isDeleted'] as bool,
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<CursorContentList> _mapDocumentToList(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;

      final contentIds = List<String>.from(data['listContentIds'] as List);
      final contents = await Future.wait(
        contentIds.map((id) async {
          final contentDoc =
              await _firestore.collection('content').doc(id).get();
          return _mapDocumentToContent(contentDoc);
        }),
      );

      return CursorContentList(
        id: doc.id,
        iconName: data['contentListIconName'] as String,
        isActive: data['isActive'] as bool,
        isFeatured: data['isFeatured'] as bool,
        contents:
            contents.where((content) => content.isDeleted == false).toList(),
        description: data['listDescription'] as String,
        descriptionAr: data['listDescriptionAr'] as String?,
        name: data['listName'] as String,
        nameAr: data['listNameAr'] as String?,
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<List<CursorContent>> getLatestContent() async {
    try {
      final querySnapshot = await _firestore
          .collection('content')
          .where('isActive', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(6)
          .get();

      return Future.wait(
        querySnapshot.docs.map(_mapDocumentToContent),
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<List<CursorContentList>> getFeaturedLists() async {
    try {
      final querySnapshot = await _firestore
          .collection('contentLists')
          .where('isActive', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .get();

      return Future.wait(
        querySnapshot.docs.map(_mapDocumentToList),
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<List<CursorContentList>> getAllLists() async {
    try {
      final querySnapshot = await _firestore
          .collection('contentLists')
          .where('isActive', isEqualTo: true)
          .get();

      return Future.wait(
        querySnapshot.docs.map(_mapDocumentToList),
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<CursorContentList> getListDetails(String listId) async {
    try {
      final docSnapshot =
          await _firestore.collection('contentLists').doc(listId).get();

      if (!docSnapshot.exists) {
        throw Exception('Content list not found');
      }

      return _mapDocumentToList(docSnapshot);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<List<CursorContentType>> getAllContentTypes() async {
    try {
      final querySnapshot = await _firestore
          .collection('contentTypes')
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.map(_mapDocumentToType).toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<CursorContentType> getContentTypeById(String typeId) async {
    try {
      final docSnapshot =
          await _firestore.collection('contentTypes').doc(typeId).get();

      if (!docSnapshot.exists) {
        throw Exception('Content type not found');
      }

      return _mapDocumentToType(docSnapshot);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<List<CursorContent>> getContentByType(String typeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('content')
          .where('contentTypeId', isEqualTo: typeId)
          .where('isActive', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .get();

      return Future.wait(
        querySnapshot.docs.map(_mapDocumentToContent),
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<(List<CursorContent>, List<CursorContentList>)> search(
      String text) async {
    try {
      final lowercaseText = text.toLowerCase();

      final contentSnapshot = await _firestore
          .collection('content')
          .where('isActive', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .get();

      final listsSnapshot = await _firestore
          .collection('contentLists')
          .where('isActive', isEqualTo: true)
          .get();

      final contents =
          await Future.wait(contentSnapshot.docs.map(_mapDocumentToContent));

      final lists =
          await Future.wait(listsSnapshot.docs.map(_mapDocumentToList));

      final filteredContents = contents
          .where((content) =>
              content.name.toLowerCase().contains(lowercaseText) ||
              (content.nameAr?.toLowerCase().contains(lowercaseText) ?? false))
          .toList();

      final filteredLists = lists
          .where((list) =>
              list.name.toLowerCase().contains(lowercaseText) ||
              (list.nameAr?.toLowerCase().contains(lowercaseText) ?? false) ||
              list.description.toLowerCase().contains(lowercaseText) ||
              (list.descriptionAr?.toLowerCase().contains(lowercaseText) ??
                  false))
          .toList();

      return (filteredContents, filteredLists);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<List<CursorContent>> getPaginatedContent({
    required int limit,
    CursorContent? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('content')
          .where('isActive', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        final lastDoc =
            await _firestore.collection('content').doc(lastDocument.id).get();
        query = query.startAfterDocument(lastDoc);
      }

      final querySnapshot = await query.get();
      return Future.wait(
        querySnapshot.docs.map(_mapDocumentToContent),
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<(List<CursorContent>, List<CursorContentList>)> searchPaginated(
    String text, {
    required int limit,
    CursorContent? lastDocument,
  }) async {
    try {
      final lowercaseText = text.toLowerCase();

      Query contentQuery = _firestore
          .collection('content')
          .where('isActive', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .limit(limit);

      if (lastDocument != null) {
        final lastDoc =
            await _firestore.collection('content').doc(lastDocument.id).get();
        contentQuery = contentQuery.startAfterDocument(lastDoc);
      }

      final contentSnapshot = await contentQuery.get();
      final contents =
          await Future.wait(contentSnapshot.docs.map(_mapDocumentToContent));

      final filteredContents = contents
          .where(
              (content) => content.name.toLowerCase().contains(lowercaseText))
          .toList();

      final listsSnapshot = await _firestore
          .collection('contentLists')
          .where('isActive', isEqualTo: true)
          .get();

      final lists =
          await Future.wait(listsSnapshot.docs.map(_mapDocumentToList));
      final filteredLists = lists
          .where((list) =>
              list.name.toLowerCase().contains(lowercaseText) ||
              list.description.toLowerCase().contains(lowercaseText))
          .toList();

      return (filteredContents, filteredLists);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }
}
