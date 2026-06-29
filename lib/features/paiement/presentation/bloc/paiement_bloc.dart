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
    final result = await getMesPaiements();
    result.fold(
      (failure) {
        AppLogger.warning('État erreur: PaiementBloc', failure.errorMessage);
        emit(PaiementError(failure.errorMessage));
      },
      (paiements) => emit(PaiementLoaded(paiements)),
    );
  }

  Future<void> _onInitier(InitierPaiementEvent event, Emitter<PaiementState> emit) async {
    emit(PaiementInitiating());
    final result = await initierPaiement(
      colisId: event.colisId,
      moyenPaiement: event.moyenPaiement,
    );
    result.fold(
      (failure) {
        AppLogger.warning('État erreur: PaiementBloc initiation', failure.errorMessage);
        emit(PaiementInitiationError(failure.errorMessage));
      },
      (url) {
        AppLogger.paiementEvent('Paiement initié', type: event.moyenPaiement);
        emit(PaiementUrlReady(url));
      },
    );
  }
}
