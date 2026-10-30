import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/core/l10n_context.dart';
import 'package:sport_timer/features/account/account_state.dart';
import 'package:sport_timer/features/account/account_view_model.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/theme/app_spacing.dart';

class AccountAvatarButton extends StatelessWidget {
  static const double _avatarRadius = 16;
  static const double _sheetAvatarRadius = 28;

  final AccountViewModel viewModel;

  const AccountAvatarButton({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ValueListenableBuilder<AccountState>(
      valueListenable: viewModel.state,
      builder: (context, state, _) {
        return IconButton(
          tooltip: l10n.accountAvatarTooltip(state.displayName),
          onPressed: () => _showAccountSheet(context),
          icon: ExcludeSemantics(
            child: _Avatar(
              state: state,
              radius: _avatarRadius,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAccountSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        final textTheme = Theme.of(sheetContext).textTheme;

        return SafeArea(
          child: ValueListenableBuilder<AccountState>(
            valueListenable: viewModel.state,
            builder: (context, state, _) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: _Avatar(
                              state: state,
                              radius: _sheetAvatarRadius,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s16),
                          Expanded(
                            child: MergeSemantics(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.displayName,
                                    style: textTheme.titleMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (state.email case final email?)
                                    Text(
                                      email,
                                      style: textTheme.bodyMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: Text(l10n.accountSignOut),
                      enabled: !state.isSigningOut,
                      onTap: () => _confirmSignOut(sheetContext),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut(BuildContext sheetContext) async {
    final l10n = sheetContext.l10n;
    final confirmed = await showDialog<bool>(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountSignOutConfirmTitle),
        content: Text(l10n.accountSignOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.accountSignOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !sheetContext.mounted) return;

    // Take what is needed from the context before the sheet is closed.
    final router = GoRouter.of(sheetContext);
    final messenger = ScaffoldMessenger.of(sheetContext);
    Navigator.of(sheetContext).pop();

    final success = await viewModel.signOut();
    if (success) {
      router.goNamed(RoutePath.login.value);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountSignOutError)));
    }
  }
}

class _Avatar extends StatelessWidget {
  final AccountState state;
  final double radius;

  const _Avatar({
    required this.state,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final photoUrl = state.photoUrl;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
      // The initial below shows when the photo fails to load.
      onForegroundImageError:
          photoUrl == null ? null : (error, stackTrace) => debugPrint('Account photo failed to load: $error'),
      child: FittedBox(child: Text(state.initial)),
    );
  }
}
