import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stanag_app/routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Home — coming soon'),
            // TODO: remove dev shortcuts before Phase 2
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.register),
              child: const Text('[DEV] Register'),
            ),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('[DEV] Login'),
            ),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.forgotPassword),
              child: const Text('[DEV] Forgot password'),
            ),
          ],
        ),
      ),
    );
  }
}
