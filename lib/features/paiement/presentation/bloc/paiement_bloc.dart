import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../../domain/entities/paiement.dart';
import '../../domain/usecases/get_mes_paiements.dart';
import '../../domain/usecases/initier_paiement.dart';
import 'paiement_event.dart';
import 'paiement_state.dart';

class PaiementBloc extends Bloc<PaiementEvent, PaiementState> {
  final GetMesPaiements getMesPaiements;
  final InitierPaiement initierPaiement;

  /// Page affichée (rechargée par RefreshPaiements).
  int _pageCourante = 1;

  /// Filtre de statut courant, passé au serveur ('tous' = aucun).
  String _statut = 'tous';

  PaiementBloc({
    required this.getMesPaiements,
    required this.initierPaiement,
  }) : super(PaiementInitial()) {
    on<LoadMesPaiements>(_onLoad);
    on<RefreshPaiements>(_onLoad);
    on<InitierPaiementEvent>(_onInitier);
  }

  Future<void> _onLoad(PaiementEvent event, Emitter<PaiementState> emit) async {
    final page = event is LoadMesPaiements && event.page != null
        ? event.page!
        : _pageCourante;
    if (event is LoadMesPaiements && event.statut != null) {
      _statut = event.statut!;
    }
    emit(PaiementLoading());
    try {
      final res = await chargerPageNonVide<Paiement>(page, (p) async {
        final result = await getMesPaiements(
            page: p, limit: kTaillePage, statut: _statut);
        return result.fold((f) => throw _EchecChargement(f.errorMessage),
            (page) => page);
      });
      _pageCourante = res.pagination.page;
      emit(PaiementLoaded(
        res.elements,
        pagination: res.pagination,
        parStatut: res.parStatut,
        statut: _statut,
      ));
    } on _EchecChargement catch (e) {
      AppLogger.warning('État erreur: PaiementBloc', e.message);
      emit(PaiementError(e.message));
    }
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

class _EchecChargement implements Exception {
  final String message;
  const _EchecChargement(this.message);
}
