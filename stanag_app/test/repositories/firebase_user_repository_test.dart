import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stanag_app/repositories/firebase/firebase_user_repository.dart';

void main() {
  group('FirebaseUserRepository.createUserDocumentIfNeeded', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseUserRepository repository;

    const uid = 'test-uid-123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirebaseUserRepository(fakeFirestore);
    });

    test('creates document with correct fields on first launch', () async {
      await repository.createUserDocumentIfNeeded(uid);

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['uid'], uid);
      expect(data['is_anonymous'], isTrue);
      expect(data['is_premium'], isFalse);
      expect(data['email'], isNull);
      expect(data['display_name'], isNull);
      expect(data['premium_until'], isNull);
      expect(data['current_level_id'], isNull);
    });

    test('uses detected interface_lang when provided', () async {
      await repository.createUserDocumentIfNeeded(uid, interfaceLang: 'en');

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()!['interface_lang'], 'en');
    });

    test('defaults interface_lang to pl', () async {
      await repository.createUserDocumentIfNeeded(uid);

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()!['interface_lang'], 'pl');
    });

    test('does not overwrite an existing document', () async {
      await fakeFirestore.collection('users').doc(uid).set({
        'uid': uid,
        'is_anonymous': false,
        'custom_field': 'preserved',
      });

      await repository.createUserDocumentIfNeeded(uid);

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()!['is_anonymous'], isFalse);
      expect(doc.data()!['custom_field'], 'preserved');
    });
  });
}
