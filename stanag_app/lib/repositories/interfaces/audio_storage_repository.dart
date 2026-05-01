import 'dart:typed_data';

abstract class AudioStorageRepository {
  Future<String> getAudioUrl(String exerciseId);
  Future<void> uploadAudio(String exerciseId, Uint8List bytes);
  Future<void> deleteAudio(String exerciseId);
}
