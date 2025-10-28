import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_block_model.dart';
import '../../domain/entities/user_block_entity.dart';

/// Abstract interface for user blocks data source
abstract class UserBlocksDataSource {
  Future<UserBlockModel?> getBlock(String blockerCpId, String blockedCpId);
  Future<List<UserBlockModel>> getBlocksByBlocker(String blockerCpId);
  Future<bool> isBlocked(String blockerCpId, String blockedCpId);
  Future<bool> hasBlockedMe(String myCpId, String otherCpId);
  Future<void> blockUser(UserBlockModel block);
  Future<void> unblockUser(String blockerCpId, String blockedCpId);
}

/// Firestore implementation of UserBlocksDataSource
class UserBlocksFirestoreDataSource implements UserBlocksDataSource {
  final FirebaseFirestore _firestore;

  UserBlocksFirestoreDataSource(this._firestore);

  CollectionReference<Map<String, dynamic>> get _blocksCollection =>
      _firestore.collection('user_blocks');

  @override
  Future<UserBlockModel?> getBlock(
    String blockerCpId,
    String blockedCpId,
  ) async {
    try {
      final blockId = UserBlockEntity.generateBlockId(blockerCpId, blockedCpId);
      final doc = await _blocksCollection.doc(blockId).get();

      if (!doc.exists) return null;

      return UserBlockModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      log('Error getting block: $e', stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<List<UserBlockModel>> getBlocksByBlocker(String blockerCpId) async {
    try {
      final querySnapshot = await _blocksCollection
          .where('blockerCpId', isEqualTo: blockerCpId)
          .get();

      return querySnapshot.docs
          .map((doc) => UserBlockModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      log('Error getting blocks by blocker: $e', stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<bool> isBlocked(String blockerCpId, String blockedCpId) async {
    final block = await getBlock(blockerCpId, blockedCpId);
    return block != null;
  }

  @override
  Future<bool> hasBlockedMe(String myCpId, String otherCpId) async {
    // Check if otherCpId has blocked myCpId
    return await isBlocked(otherCpId, myCpId);
  }

  @override
  Future<void> blockUser(UserBlockModel block) async {
    try {
      log('Blocking user: ${block.blockedCpId} by ${block.blockerCpId}');
      
      await _blocksCollection.doc(block.id).set(block.toFirestore());

      log('User blocked successfully');
    } catch (e, stackTrace) {
      log('Error blocking user: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> unblockUser(String blockerCpId, String blockedCpId) async {
    try {
      final blockId = UserBlockEntity.generateBlockId(blockerCpId, blockedCpId);
      log('Unblocking user: $blockedCpId by $blockerCpId');

      await _blocksCollection.doc(blockId).delete();

      log('User unblocked successfully');
    } catch (e, stackTrace) {
      log('Error unblocking user: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
}


