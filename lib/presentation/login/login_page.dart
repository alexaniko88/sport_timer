import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/core/l10n_context.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/user/auth_error.dart';
import 'package:sport_timer/features/login/login_state.dart';
import 'package:sport_timer/features/login/login_view_model.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/presentation/login/google_sign_in_button.dart';
import 'package:sport_timer/theme/app_spacing.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginViewModel _viewModel = LoginViewModel(getIt());

  @override
  void initState() {
    super.initState();
    // Check if user is already authenticated when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _viewModel.isUserLoggedIn()) {
        context.goNamed(RoutePath.home.value);
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final success = await _viewModel.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      context.goNamed(RoutePath.home.value);
      return;
    }
    final error = _viewModel.state.value.error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authErrorText(error))),
      );
    }
  }

  String _authErrorText(AuthError error) {
    final l10n = context.l10n;
    return switch (error) {
      AuthError.userDisabled => l10n.authErrorUserDisabled,
      AuthError.accountExistsWithDifferentCredential => l10n.authErrorAccountExists,
      AuthError.network => l10n.authErrorNetwork,
      AuthError.tooManyRequests => l10n.authErrorTooManyRequests,
      AuthError.unknown => l10n.authErrorUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.loginWelcome,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Gap(AppSpacing.s40),
                ValueListenableBuilder<LoginState>(
                  valueListenable: _viewModel.state,
                  builder: (context, state, _) {
                    if (state.isLoading) {
                      return const CircularProgressIndicator();
                    }
                    return GoogleSignInButton(onPressed: _signInWithGoogle);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
