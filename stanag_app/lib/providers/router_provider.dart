import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/routes/app_routes.dart';
import 'package:stanag_app/routes/route_definitions.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(userStateProvider, (_, _) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final userState = _ref.read(userStateProvider);
    final location = state.matchedLocation;

    if (userState.isLoading || userState.hasError) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }
    if (location == AppRoutes.splash) return AppRoutes.home;

    final isRegistered = userState.asData?.value != UserState.anonymous;
    if (isRegistered && AppRoutes.authRoutes.contains(location)) {
      return AppRoutes.home;
    }

    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: buildAppRoutes(),
  );
  ref.onDispose(router.dispose);
  return router;
});
