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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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
      await ref.read(authServiceProvider).registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      // On success userStateProvider updates → GoRouter redirect handles navigation.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'email-already-in-use' || e.code == 'credential-already-in-use') {
        _showEmailInUseDialog();
      } else {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.errorGeneric;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmailInUseDialog() {
    final l = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.registerEmailInUseTitle),
        content: Text(l.registerEmailInUseBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.login);
            },
            child: Text(l.registerEmailInUseConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.registerTitle)),
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
                const SizedBox(height: 24),
                LoadingFilledButton(
                  label: l.registerButton,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                Text(
                  l.registerPrivacyNote,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l.registerHaveAccount),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text(l.registerSignInLink),
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
