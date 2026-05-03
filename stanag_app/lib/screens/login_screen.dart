import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stanag_app/l10n/app_localizations.dart';
import 'package:stanag_app/providers/auth_provider.dart';
import 'package:stanag_app/routes/app_routes.dart';
import 'package:stanag_app/widgets/email_form_field.dart';
import 'package:stanag_app/widgets/form_error_text.dart';
import 'package:stanag_app/widgets/loading_filled_button.dart';
import 'package:stanag_app/widgets/password_form_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      // On success userStateProvider updates → GoRouter redirect handles navigation.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final isInvalidCredentials = e.code == 'wrong-password' ||
          e.code == 'user-not-found' ||
          e.code == 'invalid-credential';
      setState(() {
        _errorMessage = isInvalidCredentials
            ? AppLocalizations.of(context)!.signInErrorInvalidCredentials
            : AppLocalizations.of(context)!.errorGeneric;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.signInTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EmailFormField(controller: _emailController),
                const SizedBox(height: 16),
                PasswordFormField(
                  controller: _passwordController,
                  onFieldSubmitted: _submit,
                ),
                FormErrorText(_errorMessage),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.forgotPassword),
                    child: Text(l.signInForgotPassword),
                  ),
                ),
                const SizedBox(height: 8),
                LoadingFilledButton(
                  label: l.signInButton,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l.signInNoAccount),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.register),
                      child: Text(l.signInCreateLink),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
