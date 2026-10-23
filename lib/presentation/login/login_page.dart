import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/di/di.dart';
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
        SnackBar(content: Text(_viewModel.state.value.errorMessage ?? 'Login failed with unknown error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Sport Timer',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Gap(AppSpacing.s40),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const Gap(AppSpacing.s20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
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
                          child: const Text('Login'),
                        ),
                      ),
                      const Gap(AppSpacing.s16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _submit(_viewModel.signUp),
                          child: const Text('Sign Up'),
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
