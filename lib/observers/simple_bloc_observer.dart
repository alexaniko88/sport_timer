import 'package:basic_flutter_helper/basic_flutter_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    printLog('$runtimeType:: onClose -> ${bloc.runtimeType}');
  }

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    printLog('$runtimeType::onCreate -> ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    printLog(
      '$runtimeType:: '
      'onChange -> ${bloc.runtimeType}, '
      'FROM: ${change.currentState.runtimeType} '
      'TO: ${change.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    printLog('$runtimeType:: onError -> ${bloc.runtimeType}, $error');
    super.onError(bloc, error, stackTrace);
  }
}
