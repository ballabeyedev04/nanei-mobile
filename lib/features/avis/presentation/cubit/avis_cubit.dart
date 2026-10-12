import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../../domain/entities/avis_entity.dart';
import '../../domain/usecases/donner_avis.dart';
import '../../domain/usecases/get_mes_avis.dart';
import 'avis_state.dart';

class AvisCubit extends Cubit<AvisState> {
  final DonnerAvis donnerAvis;
  final GetMesAvis getMesAvis;

  AvisCubit({
    required this.donnerAvis,
    required this.getMesAvis,
  }) : super(const AvisInitial());

  /// Page affichée dans « Mes avis ».
  int _pageCourante = 1;
  int get pageCourante => _pageCourante;

  Future<bool> envoyerAvis({
    required String colisId,
    required int note,
    String? commentaire,
  }) async {
    emit(const AvisEnvoi());
    final result = await donnerAvis(
      colisId: colisId,
      note: note,
      commentaire: commentaire,
    );
    return result.fold(
      (failure) {
        if (failure is AvisDejaDonneFailure) {
          emit(const AvisDejaDonne());
          return true;
        }
        AppLogger.warning('État erreur: AvisCubit', failure.errorMessage);
        emit(AvisError(failure.errorMessage));
        return false;
      },
      (_) {
        AppLogger.info('Avis envoyé', {'colisId': colisId, 'note': note});
        emit(const AvisEnvoye());
        return true;
      },
    );
  }

  /// Charge la page [page] de « Mes avis » (null → page courante).
  Future<void> chargerMesAvis({int? page}) async {
    emit(const AvisChargement());
    try {
      final res = await chargerPageNonVide<AvisEntity>(
        page ?? _pageCourante,
        (p) async {
          final result = await getMesAvis(page: p, limit: kTaillePage);
          return result.fold(
              (failure) => throw _EchecChargement(failure.errorMessage),
              (page) => page);
        },
      );
      _pageCourante = res.pagination.page;
      AppLogger.info('Mes avis chargés',
          {'count': res.elements.length, 'page': res.pagination.page});
      emit(AvisCharges(res.elements, pagination: res.pagination));
    } on _EchecChargement catch (e) {
      AppLogger.warning('État erreur: AvisCubit.chargerMesAvis', e.message);
      emit(AvisError(e.message));
    }
  }

  void reset() => emit(const AvisInitial());
}

class _EchecChargement implements Exception {
  final String message;
  const _EchecChargement(this.message);
}
