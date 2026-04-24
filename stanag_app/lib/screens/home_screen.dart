import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
              onPressed: () => context.go('/register'),
              child: const Text('[DEV] Register'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/login'),
              child: const Text('[DEV] Login'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/forgot-password'),
              child: const Text('[DEV] Forgot password'),
            ),
          ],
        ),
      ),
    );
  }
}
