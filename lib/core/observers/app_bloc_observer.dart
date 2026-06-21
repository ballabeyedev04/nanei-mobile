import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/core/utils/app_logger.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    AppLogger.debug('Bloc créé: ${bloc.runtimeType}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    AppLogger.error('Bloc erreur: ${bloc.runtimeType}', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    AppLogger.debug(
      'Bloc transition: ${bloc.runtimeType}',
      '${transition.currentState.runtimeType} → ${transition.nextState.runtimeType}',
    );
    super.onTransition(bloc, transition);
  }

  @override
  void onClose(BlocBase bloc) {
    AppLogger.debug('Bloc fermé: ${bloc.runtimeType}');
    super.onClose(bloc);
  }
}
