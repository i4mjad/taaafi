import 'package:promize_sdk/core/models/user.dart';

User createPromizeUser(String name, String email, String uid) {
  return new User(email: email, name: name, userId: uid);
}
