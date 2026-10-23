import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/core/l10n_context.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/user/auth_error.dart';
import 'package:sport_timer/features/login/login_state.dart';
import 'package:sport_timer/features/login/login_view_model.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/theme/app_spacing.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginViewModel _viewModel = LoginViewModel(getIt());
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthCall action) async {
    final success = await action(
      email: emailController.text,
      password: passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      context.goNamed(RoutePath.home.value);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _authErrorText(_viewModel.state.value.error ?? AuthError.unknown),
          ),
        ),
      );
    }
  }

  String _authErrorText(AuthError error) {
    final l10n = context.l10n;
    return switch (error) {
      AuthError.invalidEmail => l10n.authErrorInvalidEmail,
      AuthError.invalidCredential => l10n.authErrorInvalidCredential,
      AuthError.userDisabled => l10n.authErrorUserDisabled,
      AuthError.emailInUse => l10n.authErrorEmailInUse,
      AuthError.weakPassword => l10n.authErrorWeakPassword,
      AuthError.network => l10n.authErrorNetwork,
      AuthError.tooManyRequests => l10n.authErrorTooManyRequests,
      AuthError.unknown => l10n.authErrorUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginTitle),
      ),
      body: Center(
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
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.loginEmailLabel),
              ),
              const Gap(AppSpacing.s20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.loginPasswordLabel),
              ),
              const Gap(AppSpacing.s32),
              ValueListenableBuilder<LoginState>(
                valueListenable: _viewModel.state,
                builder: (context, state, _) {
                  if (state.isLoading) {
                    return const CircularProgressIndicator();
                  }
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _submit(_viewModel.signIn),
                          child: Text(l10n.loginSignInButton),
                        ),
                      ),
                      const Gap(AppSpacing.s16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _submit(_viewModel.signUp),
                          child: Text(l10n.loginSignUpButton),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
