import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/screens/language_test_screen.dart';
import 'package:stanag_app/screens/splash_screen.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(userStateProvider, (_, _) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final userState = _ref.read(userStateProvider);
    final onSplash = state.matchedLocation == '/splash';

    if (userState.isLoading || userState.hasError) {
      return onSplash ? null : '/splash';
    }
    if (onSplash) return '/';
    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const LanguageTestScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
