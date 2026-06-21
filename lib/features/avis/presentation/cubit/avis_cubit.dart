import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/core/utils/app_logger.dart';
import '../../data/datasources/avis_remote_datasource.dart';
import 'avis_state.dart';

class AvisCubit extends Cubit<AvisState> {
  final AvisRemoteDataSource dataSource;

  AvisCubit({required this.dataSource}) : super(const AvisInitial());

  Future<bool> donnerAvis({
    required String colisId,
    required int note,
    String? commentaire,
  }) async {
    emit(const AvisEnvoi());
    try {
      await dataSource.donnerAvis(
          colisId: colisId, note: note, commentaire: commentaire);
      AppLogger.info('Avis donné', {'colisId': colisId, 'note': note});
      emit(const AvisEnvoye());
      return true;
    } catch (e, st) {
      AppLogger.error('Erreur dans AvisCubit.donnerAvis', e, st);
      AppLogger.warning('État erreur: AvisCubit', e.toString());
      emit(AvisError(e.toString()));
      return false;
    }
  }

  Future<void> chargerMesAvis() async {
    emit(const AvisChargement());
    try {
      final liste = await dataSource.mesAvis();
      AppLogger.info('Mes avis chargés', {'count': liste.length});
      emit(AvisCharges(liste));
    } catch (e, st) {
      AppLogger.error('Erreur dans AvisCubit.chargerMesAvis', e, st);
      emit(AvisError(e.toString()));
    }
  }

  void reset() => emit(const AvisInitial());
}
