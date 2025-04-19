import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository for handling community-related data operations
class CommunityRepository {
  final FirebaseFirestore _firestore;

  CommunityRepository(this._firestore);

  /// Records user interest in the community feature by incrementing the counter
  /// in the features collection under the community document
  Future<void> recordInterest() async {
    try {
      final featuresRef = _firestore.collection('features').doc('community');

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(featuresRef);

        if (!snapshot.exists) {
          // Initialize the document if it doesn't exist
          transaction.set(featuresRef, {'interest_count': 1});
        } else {
          // Increment the counter
          transaction
              .update(featuresRef, {'interest_count': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      // Let the service layer handle the error
      rethrow;
    }
  }
}
