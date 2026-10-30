import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sport_timer/core/duration_extension.dart';
import 'package:sport_timer/core/l10n_context.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/settings/timer_style.dart';
import 'package:sport_timer/features/timer/timer_params.dart';
import 'package:sport_timer/features/timer/timer_state.dart';
import 'package:sport_timer/features/timer/timer_view_model.dart';
import 'package:sport_timer/theme/app_spacing.dart';
import 'package:sport_timer/theme/app_text_styles.dart';
import 'package:sport_timer/theme/theme_context.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'timer_page.dart';

part 'widgets/full_color_timer_view.dart';
part 'widgets/ring_timer_view.dart';
part 'widgets/rounds_strip_timer_view.dart';
part 'widgets/timer_phase.dart';
part 'widgets/timer_ring.dart';
