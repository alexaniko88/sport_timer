import 'package:flutter/material.dart';
import 'package:sport_timer/core/l10n_context.dart';
import 'package:sport_timer/presentation/widgets/app_button.dart';
import 'package:sport_timer/theme/app_spacing.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AppButton.secondary(
      isExpanded: true,
      icon: Image.asset(
        'assets/icons/google_g_logo.png',
        width: AppSpacing.s24,
        height: AppSpacing.s24,
        excludeFromSemantics: true,
      ),
      label: context.l10n.loginGoogleButton,
      onPressed: onPressed,
    );
  }
}
