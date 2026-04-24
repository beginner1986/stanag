import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/screens/language_test_screen.dart';
import 'package:stanag_app/screens/login_screen.dart';
import 'package:stanag_app/screens/register_screen.dart';
import 'package:stanag_app/screens/splash_screen.dart';

const _authRoutes = {'/register', '/login', '/forgot-password'};

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(userStateProvider, (_, _) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final userState = _ref.read(userStateProvider);
    final location = state.matchedLocation;

    if (userState.isLoading || userState.hasError) {
      return location == '/splash' ? null : '/splash';
    }
    if (location == '/splash') return '/';

    final isRegistered = userState.asData?.value != UserState.anonymous;
    if (isRegistered && _authRoutes.contains(location)) return '/';

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
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const Scaffold(
          body: Center(child: Text('Reset password — coming soon')),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
