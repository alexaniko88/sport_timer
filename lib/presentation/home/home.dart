import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/features/account/account_view_model.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/timer/timer_params.dart';
import 'package:sport_timer/features/settings/settings_state.dart';
import 'package:sport_timer/features/settings/settings_view_model.dart';
import 'package:sport_timer/features/templates/built_in_templates.dart';
import 'package:sport_timer/features/templates/workout_template.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/presentation/widgets/account_avatar_button.dart';
import 'package:sport_timer/presentation/widgets/app_button.dart';
import 'package:sport_timer/presentation/widgets/template_tile.dart';
import 'package:sport_timer/presentation/widgets/timer_settings_picker_wheel.dart';
import 'package:sport_timer/theme/app_spacing.dart';
import 'package:sport_timer/theme/theme_context.dart';
import 'package:sport_timer/core/duration_extension.dart';
import 'package:sport_timer/core/l10n_context.dart';
import 'package:sport_timer/di/di.dart';

part 'timer_setup_page.dart';
part 'home_page.dart';
part 'statistics_page.dart';
part 'templates_page.dart';
