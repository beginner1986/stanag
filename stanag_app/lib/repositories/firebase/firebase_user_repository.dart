import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stanag_app/repositories/interfaces/user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirebaseUserRepository(this._firestore);

  @override
  Future<void> createUserDocumentIfNeeded(
    String uid, {
    String interfaceLang = 'pl',
  }) async {
    final docRef = _firestore.collection('users').doc(uid);

    final doc = await docRef
        .get(const GetOptions(source: Source.cache))
        .catchError((_) => docRef.get(const GetOptions(source: Source.server)));

    if (doc.exists) return;

    await docRef.set({
      'uid': uid,
      'email': null,
      'display_name': null,
      'interface_lang': interfaceLang,
      'created_at': FieldValue.serverTimestamp(),
      'is_anonymous': true,
      'is_premium': false,
      'premium_until': null,
      'current_level_id': null,
    });
  }
}
