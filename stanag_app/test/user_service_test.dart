import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stanag_app/services/user_service.dart';

void main() {
  group('UserService.createUserDocumentIfNeeded', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UserService userService;

    const uid = 'test-uid-123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      userService = UserService(fakeFirestore);
    });

    test('creates document with correct fields on first launch', () async {
      await userService.createUserDocumentIfNeeded(uid);

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
      await userService.createUserDocumentIfNeeded(uid, interfaceLang: 'en');

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()!['interface_lang'], 'en');
    });

    test('defaults interface_lang to pl', () async {
      await userService.createUserDocumentIfNeeded(uid);

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()!['interface_lang'], 'pl');
    });

    test('does not overwrite an existing document', () async {
      await fakeFirestore.collection('users').doc(uid).set({
        'uid': uid,
        'is_anonymous': false,
        'custom_field': 'preserved',
      });

      await userService.createUserDocumentIfNeeded(uid);

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()!['is_anonymous'], isFalse);
      expect(doc.data()!['custom_field'], 'preserved');
    });
  });
}
