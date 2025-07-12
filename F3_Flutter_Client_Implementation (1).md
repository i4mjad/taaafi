
# Flutter Client Implementation Guide (Revision C)

## Firestore helpers

```dart
final postsRef = FirebaseFirestore.instance.collection('forumPosts');

Future<void> addComment(String postId, String body,
    {String? parentFor, String? parentId}) {
  return postsRef
      .doc(postId)
      .collection('comments')
      .add({
        'authorCPId': currentCPId,
        'body': body,
        'parentFor': parentFor ?? 'post',
        'parentId': parentId ?? postId,
        'isAnonymous': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
}

Future<void> voteOnComment(String postId, String commentId, int value) {
  return postsRef
      .doc(postId)
      .collection('comments')
      .doc(commentId)
      .collection('votes')
      .doc(currentCPId)
      .set({'voterCPId': currentCPId, 'value': value, 'createdAt': Timestamp.now()});
}
```

## Referral code save

```dart
FirebaseFirestore.instance
  .collection('users')
  .doc(FirebaseAuth.instance.currentUser!.uid)
  .update({'referralCode': code});
```

## Global challenge paths

```dart
FirebaseFirestore.instance
  .collection('globalChallenges')
  .doc(chalId)
  .collection('tasks');
```
