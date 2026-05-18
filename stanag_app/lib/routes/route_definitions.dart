import 'package:go_router/go_router.dart';
import 'package:stanag_app/routes/app_routes.dart';
import 'package:stanag_app/screens/forgot_password_screen.dart';
import 'package:stanag_app/screens/home_screen.dart';
import 'package:stanag_app/screens/login_screen.dart';
import 'package:stanag_app/screens/main_shell.dart';
import 'package:stanag_app/screens/progress_screen.dart';
import 'package:stanag_app/screens/register_screen.dart';
import 'package:stanag_app/screens/settings_screen.dart';
import 'package:stanag_app/screens/splash_screen.dart';
import 'package:stanag_app/screens/upgrade_screen.dart';

List<RouteBase> buildAppRoutes() => [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.progress,
            builder: (_, _) => const ProgressScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.upgrade,
        builder: (_, _) => const UpgradeScreen(),
      ),
    ];
