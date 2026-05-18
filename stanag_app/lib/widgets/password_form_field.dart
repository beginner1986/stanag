import 'package:flutter/material.dart';
import 'package:stanag_app/l10n/app_localizations.dart';

class PasswordFormField extends StatelessWidget {
  const PasswordFormField({
    required this.controller,
    required this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      obscureText: true,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(labelText: l.passwordLabel),
      validator: (v) {
        if (v == null || v.length < 6) {
          return l.passwordValidationTooShort;
        }
        return null;
      },
      onFieldSubmitted: (_) => onFieldSubmitted(),
    );
  }
}
