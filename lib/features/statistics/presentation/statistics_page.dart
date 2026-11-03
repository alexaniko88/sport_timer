import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/account/presentation/account_avatar_button.dart';
import 'package:sport_timer/features/account/presentation/account_view_model.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_view_model.dart';
import 'package:sport_timer/features/statistics/presentation/widgets/daily_activity_tile.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/widgets/app_button.dart';

class StatisticPage extends StatefulWidget {
  final AccountViewModel accountViewModel;
  final VoidCallback onMenuPressed;

  const StatisticPage({super.key, required this.accountViewModel, required this.onMenuPressed});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  final StatisticsViewModel _viewModel = StatisticsViewModel(getIt());

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.homeMenuTooltip,
          onPressed: widget.onMenuPressed,
          icon: const Icon(Icons.menu),
        ),
        title: Text(l10n.statisticsTitle),
        actions: [
          AccountAvatarButton(viewModel: widget.accountViewModel),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
      body: ValueListenableBuilder<StatisticsState>(
        valueListenable: _viewModel.state,
        builder: (context, state, _) => switch (state.status) {
          StatisticsStatus.initial || StatisticsStatus.loading => const Center(child: CircularProgressIndicator()),
          StatisticsStatus.empty => Center(child: Text(l10n.statisticsEmpty)),
          StatisticsStatus.error => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.statisticsError),
                  const Gap(AppSpacing.s8),
                  AppButton.primary(label: l10n.statisticsRetryButton, onPressed: _viewModel.refresh),
                ],
              ),
            ),
          StatisticsStatus.content => ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s16,
                AppSpacing.s16,
                AppSpacing.s16 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: state.dailyActivity.length,
              itemBuilder: (context, index) => DailyActivityTile(
                activity: state.dailyActivity[index],
                onTap: () => context.push(RoutePath.dayDetails.value, extra: state.dailyActivity[index].localDate),
              ),
              separatorBuilder: (context, index) => const Gap(AppSpacing.s8),
            ),
        },
      ),
    );
  }
}
