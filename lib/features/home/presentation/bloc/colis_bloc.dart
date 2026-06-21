import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/core/utils/app_logger.dart';
import '../../domain/entities/notification_model.dart';
import '../../domain/usecases/get_colis_envoyes.dart';
import '../../domain/usecases/get_colis_recus.dart';
import '../../domain/usecases/get_statistiques_colis.dart';
import '../../domain/usecases/envoyer_colis.dart';
import '../../domain/usecases/rechercher_client.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/marquer_notification_lue.dart';
import 'colis_event.dart';
import 'colis_state.dart';

class ColisBloc extends Bloc<ColisEvent, ColisState> {
  final GetColisEnvoyes getColisEnvoyes;
  final GetColisRecus getColisRecus;
  final GetStatistiquesColis getStatistiques;
  final EnvoyerColis envoyerColis;
  final RechercherClient rechercherClient;
  final GetNotifications getNotifications;
  final MarquerNotificationLue marquerNotificationLue;

  ColisBloc({
    required this.getColisEnvoyes,
    required this.getColisRecus,
    required this.getStatistiques,
    required this.envoyerColis,
    required this.rechercherClient,
    required this.getNotifications,
    required this.marquerNotificationLue,
  }) : super(const ColisState()) {
    on<LoadColisEnvoyes>(_onLoadColisEnvoyes);
    on<LoadColisRecus>(_onLoadColisRecus);
    on<LoadStatistiques>(_onLoadStatistiques);
    on<EnvoyerColisRequested>(_onEnvoyerColis);
    on<RechercherClientRequested>(_onRechercherClient);
    on<LoadNotifications>(_onLoadNotifications);
    on<MarquerNotificationLueRequested>(_onMarquerLue);
    on<ResetColisStatus>(_onReset);
  }

  Future<void> _onLoadColisEnvoyes(
      LoadColisEnvoyes event, Emitter<ColisState> emit) async {
    emit(state.copyWith(loadingEnvoyes: true, error: null));
    try {
      final colis = await getColisEnvoyes();
      emit(state.copyWith(
          colisEnvoyes: colis, loadingEnvoyes: false));
    } catch (e, st) {
      AppLogger.error('Erreur dans ColisBloc._onLoadColisEnvoyes', e, st);
      emit(state.copyWith(
          loadingEnvoyes: false, error: e.toString()));
    }
  }

  Future<void> _onLoadColisRecus(
      LoadColisRecus event, Emitter<ColisState> emit) async {
    emit(state.copyWith(loadingRecus: true, error: null));
    try {
      final colis = await getColisRecus();
      emit(state.copyWith(colisRecus: colis, loadingRecus: false));
    } catch (e, st) {
      AppLogger.error('Erreur dans ColisBloc._onLoadColisRecus', e, st);
      emit(state.copyWith(
          loadingRecus: false, error: e.toString()));
    }
  }

  Future<void> _onLoadStatistiques(
      LoadStatistiques event, Emitter<ColisState> emit) async {
    emit(state.copyWith(loadingStats: true, error: null));
    try {
      final stats = await getStatistiques();
      emit(state.copyWith(
        nbEnvoyes: stats['envoyes'] ?? 0,
        nbRecus: stats['recus'] ?? 0,
        loadingStats: false,
      ));
    } catch (e, st) {
      AppLogger.error('Erreur dans ColisBloc._onLoadStatistiques', e, st);
      emit(state.copyWith(loadingStats: false, error: e.toString()));
    }
  }

  Future<void> _onEnvoyerColis(
      EnvoyerColisRequested event, Emitter<ColisState> emit) async {
    emit(state.copyWith(sendingColis: true, colisEnvoye: false, error: null));
    try {
      final reference = await envoyerColis(event.params);
      AppLogger.colisEvent('Colis créé', reference: reference);
      emit(state.copyWith(
        sendingColis: false,
        colisEnvoye: true,
        derniereColis: reference,
      ));
      // Recharger automatiquement la liste après envoi
      add(LoadColisEnvoyes());
    } catch (e, st) {
      AppLogger.error('Erreur dans ColisBloc._onEnvoyerColis', e, st);
      AppLogger.warning('État erreur: ColisBloc envoi colis', e.toString());
      emit(state.copyWith(
          sendingColis: false, error: e.toString()));
    }
  }

  Future<void> _onRechercherClient(
      RechercherClientRequested event, Emitter<ColisState> emit) async {
    emit(state.copyWith(searchingClient: true));
    try {
      final results = await rechercherClient(event.query);
      emit(state.copyWith(
          resultatsRecherche: results, searchingClient: false));
    } catch (e, st) {
      AppLogger.error('Erreur dans ColisBloc._onRechercherClient', e, st);
      emit(state.copyWith(
          searchingClient: false, resultatsRecherche: []));
    }
  }

  Future<void> _onLoadNotifications(
      LoadNotifications event, Emitter<ColisState> emit) async {
    try {
      final notifs = await getNotifications();
      emit(state.copyWith(notifications: notifs));
    } catch (_) {}
  }

  Future<void> _onMarquerLue(
      MarquerNotificationLueRequested event, Emitter<ColisState> emit) async {
    try {
      await marquerNotificationLue(event.id);
      final updated = state.notifications.map<NotificationModel>((n) {
        if (n.id != event.id) return n;
        return NotificationModel(
          id: n.id,
          referenceColis: n.referenceColis,
          typeColis: n.typeColis,
          descriptionColis: n.descriptionColis,
          expediteurNom: n.expediteurNom,
          expediteurPrenom: n.expediteurPrenom,
          expediteurEmail: n.expediteurEmail,
          date: n.date,
          lue: true,
        );
      }).toList();
      emit(state.copyWith(notifications: updated));
    } catch (_) {}
  }

  void _onReset(ResetColisStatus event, Emitter<ColisState> emit) {
    emit(state.copyWith(
      colisEnvoye: false,
      error: null,
      resultatsRecherche: [],
    ));
  }
}
