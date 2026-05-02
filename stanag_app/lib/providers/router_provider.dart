import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/screens/forgot_password_screen.dart';
import 'package:stanag_app/screens/home_screen.dart';
import 'package:stanag_app/screens/login_screen.dart';
import 'package:stanag_app/screens/main_shell.dart';
import 'package:stanag_app/screens/progress_screen.dart';
import 'package:stanag_app/screens/register_screen.dart';
import 'package:stanag_app/screens/settings_screen.dart';
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
    if (location == '/splash') return '/home';

    final isRegistered = userState.asData?.value != UserState.anonymous;
    if (isRegistered && _authRoutes.contains(location)) return '/home';

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
      ShellRoute(
        builder: (context, state, child) => MainShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const HomeScreen(),
          ),
          GoRoute(
            path: '/progress',
            builder: (_, _) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
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
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
