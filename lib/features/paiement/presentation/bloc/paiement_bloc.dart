import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/core/utils/app_logger.dart';
import '../../domain/usecases/get_mes_paiements.dart';
import '../../domain/usecases/initier_paiement.dart';
import 'paiement_event.dart';
import 'paiement_state.dart';

class PaiementBloc extends Bloc<PaiementEvent, PaiementState> {
  final GetMesPaiements getMesPaiements;
  final InitierPaiement initierPaiement;

  PaiementBloc({
    required this.getMesPaiements,
    required this.initierPaiement,
  }) : super(PaiementInitial()) {
    on<LoadMesPaiements>(_onLoad);
    on<RefreshPaiements>(_onLoad);
    on<InitierPaiementEvent>(_onInitier);
  }

  Future<void> _onLoad(PaiementEvent event, Emitter<PaiementState> emit) async {
    emit(PaiementLoading());
    try {
      final paiements = await getMesPaiements();
      emit(PaiementLoaded(paiements));
    } catch (e, st) {
      AppLogger.error('Erreur dans PaiementBloc._onLoad', e, st);
      AppLogger.warning('État erreur: PaiementBloc', 'Impossible de charger les paiements');
      emit(PaiementError('Impossible de charger les paiements'));
    }
  }

  Future<void> _onInitier(InitierPaiementEvent event, Emitter<PaiementState> emit) async {
    emit(PaiementInitiating());
    try {
      final url = await initierPaiement(
        colisId: event.colisId,
        moyenPaiement: event.moyenPaiement,
      );
      AppLogger.paiementEvent('Paiement initié', type: event.moyenPaiement);
      emit(PaiementUrlReady(url));
    } catch (e, st) {
      AppLogger.error('Erreur dans PaiementBloc._onInitier', e, st);
      AppLogger.warning('État erreur: PaiementBloc initiation', e.toString());
      emit(PaiementInitiationError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
