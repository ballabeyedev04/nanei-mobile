import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/core/utils/app_logger.dart';
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

  Future<void> chargerMesAvis() async {
    emit(const AvisChargement());
    final result = await getMesAvis();
    result.fold(
      (failure) {
        AppLogger.warning('État erreur: AvisCubit.chargerMesAvis', failure.errorMessage);
        emit(AvisError(failure.errorMessage));
      },
      (liste) {
        AppLogger.info('Mes avis chargés', {'count': liste.length});
        emit(AvisCharges(liste));
      },
    );
  }

  void reset() => emit(const AvisInitial());
}
