import 'package:flutter/material.dart';
import 'package:stanag_app/l10n/app_localizations.dart';

class EmailFormField extends StatelessWidget {
  const EmailFormField({
    required this.controller,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final TextInputAction textInputAction;
  final VoidCallback? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      autocorrect: false,
      decoration: InputDecoration(labelText: l.emailLabel),
      validator: (v) {
        if (v == null || v.trim().isEmpty || !v.contains('@')) {
          return l.emailValidationInvalid;
        }
        return null;
      },
      onFieldSubmitted: onFieldSubmitted != null ? (_) => onFieldSubmitted!() : null,
    );
  }
}
