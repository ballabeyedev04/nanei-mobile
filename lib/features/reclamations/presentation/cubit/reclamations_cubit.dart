import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/core/utils/app_logger.dart';
import '../../domain/repositories/reclamation_repository.dart';
import 'reclamations_state.dart';

class ReclamationsCubit extends Cubit<ReclamationsState> {
  final ReclamationRepository repository;

  ReclamationsCubit({required this.repository})
      : super(const ReclamationsInitial());

  Future<void> loadReclamations() async {
    emit(const ReclamationsLoading());
    try {
      final list = await repository.getReclamations();
      emit(ReclamationsLoaded(list));
    } catch (e, st) {
      AppLogger.error('Erreur dans ReclamationsCubit.loadReclamations', e, st);
      AppLogger.warning('État erreur: ReclamationsCubit', e.toString());
      emit(ReclamationsError(e.toString()));
    }
  }

  Future<bool> creerReclamation({
    required String colisId,
    required String type,
    required String description,
    required List<String> photos,
  }) async {
    emit(const ReclamationEnvoi());
    try {
      await repository.creerReclamation(
        colisId: colisId,
        type: type,
        description: description,
        photos: photos,
      );
      emit(const ReclamationEnvoyee());
      return true;
    } catch (e, st) {
      AppLogger.error('Erreur dans ReclamationsCubit.creerReclamation', e, st);
      AppLogger.warning('État erreur: ReclamationsCubit création', e.toString());
      emit(ReclamationsError(e.toString()));
      return false;
    }
  }
}
