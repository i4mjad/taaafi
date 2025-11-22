import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/features/authentication/data/models/user_document.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_document_provider.g.dart';

@riverpod
class UserDocumentsNotifier extends _$UserDocumentsNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription;

  @override
  FutureOr<UserDocument?> build() async {
    // Listen to auth state changes and refetch user document accordingly
    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user != null) {
        // User logged in, fetch their document
        final document = await getUserDocument(user.uid);
        state = AsyncValue.data(document);
      } else {
        // User logged out
        state = const AsyncValue.data(null);
      }
    });

    // Clean up subscription when provider is disposed
    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    return await getUserDocument(currentUser.uid);
  }

  Future<UserDocument?> getUserDocument(String uid) async {
    try {
      // Validate the uid before making the Firestore call
      if (uid.isEmpty) {
        ref.read(errorLoggerProvider).logException(
              'Invalid UID: Empty string provided for document path',
              StackTrace.current,
            );
        return null;
      }

      print('📥 FETCHING USER DOCUMENT for UID: $uid');

      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(GetOptions(source: Source.server));

      if (!doc.exists) {
        print('⚠️ USER DOCUMENT: Document does not exist for UID: $uid');
        return null; // No document found
      }

      final data = doc.data();
      if (data == null) {
        print('⚠️ USER DOCUMENT: Document exists but data is null for UID: $uid');
        return null;
      }

      // Check if the document has any non-null fields
      final hasAnyData = data.values.any((value) => value != null);
      if (!hasAnyData) {
        print('⚠️ USER DOCUMENT: Document exists but all fields are null for UID: $uid');
        return null;
      }

      print('📄 USER DOCUMENT RAW DATA:');
      data.forEach((key, value) {
        print('   - $key: $value');
      });

      var userDocument = UserDocument.fromFirestore(doc);
      
      if (userDocument.uid == null) {
        print('⚠️ USER DOCUMENT: Parsed document has null uid field');
      } else {
        print('✅ USER DOCUMENT: Successfully loaded document with uid: ${userDocument.uid}');
      }
      
      return userDocument.uid != null ? userDocument : null;
    } catch (e, stackTrace) {
      print('❌ USER DOCUMENT ERROR: $e');
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return null;
    }
  }

  bool isLegacyUserDocument(UserDocument? userDocument) {
    if (userDocument == null) return false;

    // Check if all fields are null except messagingToken
    final allFieldsNull = userDocument.uid == null &&
        userDocument.devicesIds == null &&
        userDocument.displayName == null &&
        userDocument.email == null &&
        userDocument.gender == null &&
        userDocument.locale == null &&
        userDocument.dayOfBirth == null &&
        userDocument.userFirstDate == null &&
        userDocument.role == null &&
        userDocument.userRelapses == null &&
        userDocument.userMasturbatingWithoutWatching == null &&
        userDocument.userWatchingWithoutMasturbating == null;

    if (allFieldsNull) return false;

    final isLegacy = userDocument.devicesIds == null ||
        userDocument.messagingToken == null ||
        userDocument.role == null;
    
    if (isLegacy) {
      final legacyFields = <String>[];
      if (userDocument.devicesIds == null) legacyFields.add('devicesIds');
      if (userDocument.messagingToken == null) legacyFields.add('messagingToken');
      if (userDocument.role == null) legacyFields.add('role');
      
      print('🔍 USER DOCUMENT IS LEGACY: Missing ${legacyFields.join(', ')}');
      print('📋 Legacy check values:');
      print('   - devicesIds: ${userDocument.devicesIds}');
      print('   - messagingToken: ${userDocument.messagingToken}');
      print('   - role: ${userDocument.role}');
    }
    
    return isLegacy;
  }

  bool isNewUserDocument(UserDocument userDocument) {
    return userDocument.devicesIds != null &&
        userDocument.messagingToken != null &&
        userDocument.role != null;
  }

  bool hasMissingData(UserDocument userDocument) {
    final missingFields = <String>[];
    
    if (userDocument.displayName == null) missingFields.add('displayName');
    if (userDocument.email == null) missingFields.add('email');
    if (userDocument.locale == null) missingFields.add('locale');
    if (userDocument.uid == null) missingFields.add('uid');
    if (userDocument.dayOfBirth == null) missingFields.add('dayOfBirth');
    if (userDocument.userFirstDate == null) missingFields.add('userFirstDate');
    
    final hasMissing = missingFields.isNotEmpty;
    
    if (hasMissing) {
      print('🔍 USER DOCUMENT MISSING DATA: ${missingFields.join(', ')}');
      print('📋 Current document values:');
      print('   - displayName: ${userDocument.displayName}');
      print('   - email: ${userDocument.email}');
      print('   - locale: ${userDocument.locale}');
      print('   - uid: ${userDocument.uid}');
      print('   - dayOfBirth: ${userDocument.dayOfBirth}');
      print('   - userFirstDate: ${userDocument.userFirstDate}');
    }
    
    return hasMissing;
  }

  Future<bool> hasOldStructure() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = UserDocument.fromFirestore(doc);

    return data != null && data.role == null;
  }
}
