library home;

import 'package:basic_flutter_helper/basic_flutter_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/features/timer/timer.dart';
import 'package:sport_timer/features/user/user_repository.dart';
import 'package:sport_timer/features/settings/settings.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/presentation/widgets/timer_settings_picker.dart';
import 'package:sport_timer/theme/styles/styles.dart';
import 'package:sport_timer/di/di.dart';

part 'timer_setup_page.dart';
part 'home_page.dart';
part 'statistics_page.dart';
