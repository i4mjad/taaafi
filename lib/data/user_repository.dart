abstract class UserRepository {
  Future<bool> isAuthenticated();

  Future<void> authenticateAnonymously();

  Future<String> getUserId();

  Future<void> createNewUserDocument();
}