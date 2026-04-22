import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/services/auth_service.dart';
import 'package:stanag_app/services/user_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return firebaseAuth.authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthService(firebaseAuth);
});

final userServiceProvider = Provider<UserService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return UserService(firestore);
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
    } catch (_) {
      yield UserState.registeredFree;
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
