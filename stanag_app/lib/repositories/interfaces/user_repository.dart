abstract class UserRepository {
  Future<void> createUserDocumentIfNeeded(
    String uid, {
    String interfaceLang = 'pl',
  });
}
