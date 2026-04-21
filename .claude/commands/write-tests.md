For the file I specify, write Flutter/Dart tests covering:
- Happy path for each public method or widget state
- At least one edge case or unexpected input per method
- Error paths: what happens when Firebase calls fail or return unexpected data

Testing conventions for this project:
- Test files go in `stanag_app/test/`, mirroring the `lib/` structure (e.g. `lib/services/foo.dart` → `test/services/foo_test.dart`)
- Use `flutter_test` for all tests
- Mock Firestore with `fake_cloud_firestore` (already in dev dependencies)
- Mock Firebase Auth by passing a plain `String uid` where possible — services are designed to accept uid directly rather than `User` objects
- Test Riverpod providers using `ProviderContainer` with dependency overrides, not the full widget tree
- Test widgets using `WidgetTester`; wrap in `ProviderScope` with overridden providers for any Firebase dependencies

Do not move on to another file until I approve the tests.
