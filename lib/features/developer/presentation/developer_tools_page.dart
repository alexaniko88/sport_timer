import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/developer/presentation/developer_tools_state.dart';
import 'package:sport_timer/features/developer/presentation/developer_tools_view_model.dart';
import 'package:sport_timer/shared/presentation/extensions/text_theme_extension.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/widgets/app_surface.dart';

class DeveloperToolsPage extends StatefulWidget {
  const DeveloperToolsPage({super.key});

  @override
  State<DeveloperToolsPage> createState() => _DeveloperToolsPageState();
}

class _DeveloperToolsPageState extends State<DeveloperToolsPage> {
  final DeveloperToolsViewModel _viewModel = DeveloperToolsViewModel(getIt());

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _onDeleteTapped() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _ConfirmDeleteDialog(),
    );
    if (confirmed != true) return;
    final success = await _viewModel.purge();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('All local activity deleted.')));
      return;
    }
    final error = _viewModel.state.value.errorMessage;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete activity: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Developer tools')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          ValueListenableBuilder<DeveloperToolsState>(
            valueListenable: _viewModel.state,
            builder: (context, state, _) {
              return Semantics(
                button: true,
                enabled: !state.isPurging,
                child: AppSurface(
                  onTap: state.isPurging ? null : _onDeleteTapped,
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, color: colorScheme.primary),
                      const Gap(AppSpacing.s12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delete all activity', style: textTheme.tileTitle),
                            Text(
                              'Removes workouts and statistics for every account on this device. '
                              'Settings and sign-in are kept.',
                              style: textTheme.tileSecondary.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const Gap(AppSpacing.s12),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: state.isPurging
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, semanticsLabel: 'Deleting'),
                                )
                              : Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete all activity?'),
      content: const Text(
        "This deletes every workout and statistic for all accounts on this device. It can't be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
