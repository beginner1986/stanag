import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanag_app/services/local_storage_service.dart';

final localStorageProvider = Provider<LocalStorageService>(
  (ref) => const SharedPreferencesLocalStorageService(),
);
