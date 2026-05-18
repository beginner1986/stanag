import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/providers/firebase_providers.dart';
import 'package:stanag_app/repositories/firebase/firebase_user_repository.dart';
import 'package:stanag_app/repositories/interfaces/user_repository.dart';
import 'package:stanag_app/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthService(firebaseAuth);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseUserRepository(firestore);
});

final userStateProvider = StreamProvider<UserState>((ref) async* {
  final auth = ref.watch(firebaseAuthProvider);
  await for (final user in auth.idTokenChanges()) {
    if (user == null || user.isAnonymous) {
      yield UserState.anonymous;
      continue;
    }
    try {
      final result = await user.getIdTokenResult();
      final claims = result.claims;
      final isPremium = claims?['is_premium'] as bool? ?? false;
      if (!isPremium) {
        yield UserState.registeredFree;
        continue;
      }
      final premiumUntil = _parsePremiumUntil(claims?['premium_until']);
      if (premiumUntil != null && premiumUntil.isBefore(DateTime.now())) {
        yield UserState.expiredPremium;
      } else {
        yield UserState.registeredPremium;
      }
    } catch (e, st) {
      debugPrint('userStateProvider: token fetch failed: $e\n$st');
      yield UserState.anonymous;
    }
  }
});

DateTime? _parsePremiumUntil(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
  if (raw is double) {
    return DateTime.fromMillisecondsSinceEpoch((raw * 1000).toInt());
  }
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
