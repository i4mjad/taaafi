import 'package:reboot_app_3/features/community/data/datasources/community_remote_datasource.dart';
import 'package:reboot_app_3/features/community/data/models/community_profile_model.dart';
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';
import 'package:reboot_app_3/features/community/domain/repositories/community_repository.dart';
import 'package:reboot_app_3/features/community/data/exceptions/community_exceptions.dart';

/// Implementation of CommunityRepository
///
/// This class implements the repository interface and acts as a bridge between
/// the domain layer and the data sources. It handles entity/model conversions
/// and provides a clean abstraction over data operations.
class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityRemoteDatasource _remoteDatasource;

  const CommunityRepositoryImpl(this._remoteDatasource);

  @override
  Future<void> createProfile(CommunityProfileEntity profile) async {
    try {
      final model = CommunityProfileModel.fromEntity(profile);
      await _remoteDatasource.createProfile(model);
    } catch (e) {
      if (e is CommunityException) {
        rethrow;
      }
      throw NetworkException('Failed to create profile: $e');
    }
  }

  @override
  Future<CommunityProfileEntity?> getProfile(String uid) async {
    print('🔄 Repository: Getting profile for UID: $uid');

    try {
      print('🔄 Repository: Calling remote datasource...');
      final model = await _remoteDatasource.getProfile(uid);

      if (model == null) {
        print('❌ Repository: Remote datasource returned null');
        return null;
      }

      print(
          '✅ Repository: Remote datasource returned model for: ${model.displayName}');
      print('🔄 Repository: Converting model to entity...');

      final entity = model.toEntity();
      print(
          '✅ Repository: Successfully converted to entity: ${entity.displayName} (isDeleted: ${entity.isDeleted})');

      return entity;
    } catch (e, stackTrace) {
      print('❌ Repository: Exception in getProfile: $e');
      print('❌ Repository: Stack trace: $stackTrace');

      if (e is CommunityException) {
        print('❌ Repository: Rethrowing CommunityException');
        rethrow;
      }

      print('❌ Repository: Throwing NetworkException');
      throw NetworkException('Failed to get profile: $e');
    }
  }

  @override
  Future<void> updateProfile(CommunityProfileEntity profile) async {
    try {
      final model = CommunityProfileModel.fromEntity(profile);
      await _remoteDatasource.updateProfile(model);
    } catch (e) {
      if (e is CommunityException) {
        rethrow;
      }
      throw NetworkException('Failed to update profile: $e');
    }
  }

  @override
  Future<void> deleteProfile(String uid) async {
    try {
      await _remoteDatasource.deleteProfile(uid);
    } catch (e) {
      if (e is CommunityException) {
        rethrow;
      }
      throw NetworkException('Failed to delete profile: $e');
    }
  }

  @override
  Future<bool> profileExists(String uid) async {
    try {
      return await _remoteDatasource.profileExists(uid);
    } catch (e) {
      if (e is CommunityException) {
        rethrow;
      }
      throw NetworkException('Failed to check profile existence: $e');
    }
  }

  @override
  Stream<CommunityProfileEntity?> watchProfile(String uid) {
    try {
      return _remoteDatasource.watchProfile(uid).map(
            (model) => model?.toEntity(),
          );
    } catch (e) {
      throw NetworkException('Failed to watch profile: $e');
    }
  }

  @override
  Future<void> recordInterest() async {
    try {
      await _remoteDatasource.recordInterest();
    } catch (e) {
      if (e is CommunityException) {
        rethrow;
      }
      throw NetworkException('Failed to record interest: $e');
    }
  }

  @override
  Future<void> updateGroupBio(String cpId, String bio) async {
    try {
      if (bio.length > 200) {
        throw ProfileUpdateException('Bio exceeds 200 character limit');
      }
      await _remoteDatasource.updateGroupBio(cpId, bio);
    } catch (e) {
      if (e is CommunityException) {
        rethrow;
      }
      throw NetworkException('Failed to update group bio: $e');
    }
  }

  @override
  Future<void> updateInterests(String cpId, List<String> interests) async {
    try {
      await _remoteDatasource.updateInterests(cpId, interests);
    } catch (e) {
      if (e is CommunityException) {
        rethrow;
      }
      throw NetworkException('Failed to update interests: $e');
    }
  }
}
