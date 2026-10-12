import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/core/utils/api_error.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../../domain/entities/reclamation_entity.dart';
import '../../domain/repositories/reclamation_repository.dart';
import 'reclamations_state.dart';

class ReclamationsCubit extends Cubit<ReclamationsState> {
  final ReclamationRepository repository;

  ReclamationsCubit({required this.repository})
      : super(const ReclamationsInitial());

  /// Page affichée (rechargée quand [loadReclamations] est appelé sans page).
  int _pageCourante = 1;
  int get pageCourante => _pageCourante;

  Future<void> loadReclamations({int? page}) async {
    emit(const ReclamationsLoading());
    try {
      final res = await chargerPageNonVide<ReclamationEntity>(
        page ?? _pageCourante,
        (p) => repository.getReclamations(page: p, limit: kTaillePage),
      );
      _pageCourante = res.pagination.page;
      emit(ReclamationsLoaded(res.elements, pagination: res.pagination));
    } catch (e, st) {
      AppLogger.error('Erreur dans ReclamationsCubit.loadReclamations', e, st);
      AppLogger.warning('État erreur: ReclamationsCubit', e.toString());
      emit(ReclamationsError(messageErreurApi(e,
          fallback: 'Impossible de charger les réclamations.')));
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
      emit(ReclamationsError(messageErreurApi(e,
          fallback: "Impossible d'envoyer la réclamation.")));
      return false;
    }
  }
}
