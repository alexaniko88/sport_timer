import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/developer/presentation/developer_tools_state.dart';
import 'package:sport_timer/features/developer/presentation/developer_tools_view_model.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';

class _FakeActivityRepository implements ActivityRepository {
  final Completer<Result<void>> completer = Completer<Result<void>>();
  int deleteCalls = 0;

  @override
  Future<Result<void>> deleteAllActivity() {
    deleteCalls++;
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeActivityRepository repository;
  late DeveloperToolsViewModel viewModel;

  setUp(() {
    repository = _FakeActivityRepository();
    viewModel = DeveloperToolsViewModel(repository);
  });

  group('DeveloperToolsViewModel.purge', () {
    test('purge succeeds', () async {
      final future = viewModel.purge();
      expect(viewModel.state.value, const DeveloperToolsState(isPurging: true));

      repository.completer.complete(const Success(null));

      expect(await future, isTrue);
      expect(viewModel.state.value, const DeveloperToolsState());
      viewModel.dispose();
    });

    test('purge failure sets the error message', () async {
      final future = viewModel.purge();
      repository.completer.complete(Failure(Exception('boom')));

      expect(await future, isFalse);
      expect(viewModel.state.value.isPurging, isFalse);
      expect(viewModel.state.value.errorMessage, Exception('boom').toString());
      viewModel.dispose();
    });

    test('second purge while pending is ignored', () async {
      final first = viewModel.purge();
      final stateBefore = viewModel.state.value;

      expect(await viewModel.purge(), isFalse);
      expect(viewModel.state.value, stateBefore);
      expect(repository.deleteCalls, 1);

      repository.completer.complete(const Success(null));
      expect(await first, isTrue);
      viewModel.dispose();
    });

    test('dispose while purging', () async {
      final future = viewModel.purge();
      viewModel.dispose();

      repository.completer.complete(const Success(null));

      expect(await future, isFalse);
    });
  });
}
