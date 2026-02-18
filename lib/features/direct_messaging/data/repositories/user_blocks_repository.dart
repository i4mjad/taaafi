import '../../domain/entities/user_block_entity.dart';
import '../datasources/user_blocks_firestore_datasource.dart';
import '../models/user_block_model.dart';

/// Repository for user block operations
class UserBlocksRepository {
  final UserBlocksDataSource _dataSource;

  UserBlocksRepository(this._dataSource);

  /// Get a specific block
  Future<UserBlockEntity?> getBlock(
    String blockerCpId,
    String blockedCpId,
  ) async {
    final model = await _dataSource.getBlock(blockerCpId, blockedCpId);
    return model;
  }

  /// Get all blocks by a user
  Future<List<UserBlockEntity>> getBlocksByBlocker(String blockerCpId) async {
    final models = await _dataSource.getBlocksByBlocker(blockerCpId);
    return models.cast<UserBlockEntity>();
  }

  /// Check if user is blocked
  Future<bool> isBlocked(String blockerCpId, String blockedCpId) async {
    return await _dataSource.isBlocked(blockerCpId, blockedCpId);
  }

  /// Check if another user has blocked me
  Future<bool> hasBlockedMe(String myCpId, String otherCpId) async {
    return await _dataSource.hasBlockedMe(myCpId, otherCpId);
  }

  /// Block a user
  Future<void> blockUser(UserBlockEntity block) async {
    final model = UserBlockModel.fromEntity(block);
    await _dataSource.blockUser(model);
  }

  /// Unblock a user
  Future<void> unblockUser(String blockerCpId, String blockedCpId) async {
    await _dataSource.unblockUser(blockerCpId, blockedCpId);
  }
}

/// Factory for creating UserBlocksRepository
class UserBlocksRepositoryFactory {
  static UserBlocksRepository create(UserBlocksDataSource dataSource) {
    return UserBlocksRepository(dataSource);
  }
}


