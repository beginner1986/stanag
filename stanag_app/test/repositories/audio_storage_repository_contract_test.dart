import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stanag_app/repositories/interfaces/audio_storage_repository.dart';

// In-memory fake that any real implementation must behave like.
class FakeAudioStorageRepository implements AudioStorageRepository {
  final Map<String, Uint8List> _store = {};

  @override
  Future<String> getAudioUrl(String exerciseId) async {
    if (!_store.containsKey(exerciseId)) {
      throw ArgumentError('No audio for exerciseId: $exerciseId');
    }
    return 'fake-url/$exerciseId';
  }

  @override
  Future<void> uploadAudio(String exerciseId, Uint8List bytes) async {
    _store[exerciseId] = bytes;
  }

  @override
  Future<void> deleteAudio(String exerciseId) async {
    _store.remove(exerciseId);
  }
}

void main() {
  group('AudioStorageRepository contract', () {
    late AudioStorageRepository repo;

    setUp(() => repo = FakeAudioStorageRepository());

    test('getAudioUrl returns a non-empty string after upload', () async {
      await repo.uploadAudio('ex-1', Uint8List.fromList([1, 2, 3]));

      final url = await repo.getAudioUrl('ex-1');
      expect(url, isNotEmpty);
    });

    test('getAudioUrl throws for an unknown exerciseId', () async {
      await expectLater(
        repo.getAudioUrl('unknown'),
        throwsA(anything),
      );
    });

    test('uploadAudio overwrites existing audio', () async {
      await repo.uploadAudio('ex-1', Uint8List.fromList([1, 2, 3]));
      await repo.uploadAudio('ex-1', Uint8List.fromList([9, 8, 7]));

      final url = await repo.getAudioUrl('ex-1');
      expect(url, isNotEmpty);
    });

    test('deleteAudio removes the entry so getAudioUrl throws afterwards', () async {
      await repo.uploadAudio('ex-1', Uint8List.fromList([1, 2, 3]));
      await repo.deleteAudio('ex-1');

      await expectLater(
        repo.getAudioUrl('ex-1'),
        throwsA(anything),
      );
    });

    test('deleteAudio on unknown exerciseId does not throw', () async {
      await expectLater(
        repo.deleteAudio('never-uploaded'),
        completes,
      );
    });
  });
}
