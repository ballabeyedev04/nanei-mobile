import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../../domain/entities/colis.dart';
import '../../domain/entities/notification_model.dart';
import '../../domain/entities/page_notifications.dart';
import '../../domain/usecases/get_colis_envoyes.dart';
import '../../domain/usecases/get_colis_recus.dart';
import '../../domain/usecases/get_statistiques_colis.dart';
import '../../domain/usecases/envoyer_colis.dart';
import '../../domain/usecases/rechercher_client.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/marquer_notification_lue.dart';
import '../../domain/usecases/marquer_toutes_notifications_lues.dart';
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
  final MarquerToutesNotificationsLues marquerToutesNotificationsLues;

  ColisBloc({
    required this.getColisEnvoyes,
    required this.getColisRecus,
    required this.getStatistiques,
    required this.envoyerColis,
    required this.rechercherClient,
    required this.getNotifications,
    required this.marquerNotificationLue,
    required this.marquerToutesNotificationsLues,
  }) : super(const ColisState()) {
    on<LoadColisEnvoyes>(_onLoadColisEnvoyes);
    on<LoadColisRecus>(_onLoadColisRecus);
    on<LoadColisTous>(_onLoadColisTous);
    on<LoadStatistiques>(_onLoadStatistiques);
    on<EnvoyerColisRequested>(_onEnvoyerColis);
    on<RechercherClientRequested>(_onRechercherClient);
    on<LoadNotifications>(_onLoadNotifications);
    on<MarquerNotificationLueRequested>(_onMarquerLue);
    on<MarquerToutesNotificationsLuesRequested>(_onMarquerToutesLues);
    on<ResetColisStatus>(_onReset);
  }

  Future<void> _onLoadColisEnvoyes(
      LoadColisEnvoyes event, Emitter<ColisState> emit) async {
    final statut = event.statut ?? state.statutEnvoyes;
    emit(state.copyWith(
        loadingEnvoyes: true, statutEnvoyes: statut, error: null));
    try {
      final res = await chargerPageNonVide<Colis>(
        event.page ?? state.paginationEnvoyes.page,
        (p) => getColisEnvoyes(page: p, limit: kTaillePage, statut: statut),
      );
      emit(state.copyWith(
          colisEnvoyes: res.elements,
          paginationEnvoyes: res.pagination,
          parStatutEnvoyes: res.parStatut,
          loadingEnvoyes: false));
    } catch (e, st) {
      AppLogger.error('Erreur dans ColisBloc._onLoadColisEnvoyes', e, st);
      emit(state.copyWith(
          loadingEnvoyes: false, error: e.toString()));
    }
  }

  Future<void> _onLoadColisRecus(
      LoadColisRecus event, Emitter<ColisState> emit) async {
    final statut = event.statut ?? state.statutRecus;
    emit(state.copyWith(loadingRecus: true, statutRecus: statut, error: null));
    try {
      final res = await chargerPageNonVide<Colis>(
        event.page ?? state.paginationRecus.page,
        (p) => getColisRecus(page: p, limit: kTaillePage, statut: statut),
      );
      emit(state.copyWith(
          colisRecus: res.elements,
          paginationRecus: res.pagination,
          parStatutRecus: res.parStatut,
          loadingRecus: false));
    } catch (e, st) {
      AppLogger.error('Erreur dans ColisBloc._onLoadColisRecus', e, st);
      emit(state.copyWith(
          loadingRecus: false, error: e.toString()));
    }
  }

  /// Onglet « Tous » : la page N contient la page N des envoyés et la page N
  /// des reçus (moitié de [kTaillePage] chacun), fusionnées par date.
  Future<void> _onLoadColisTous(
      LoadColisTous event, Emitter<ColisState> emit) async {
    final statut = event.statut ?? state.statutTous;
    emit(state.copyWith(loadingTous: true, statutTous: statut, error: null));
    try {
      final res = await chargerPageNonVide<Colis>(
        event.page ?? state.paginationTous.page,
        (p) => _chargerPageTous(p, statut),
      );
      emit(state.copyWith(
          colisTous: res.elements,
          paginationTous: res.pagination,
          parStatutTous: res.parStatut,
          loadingTous: false));
    } catch (e, st) {
      AppLogger.error('Erreur dans ColisBloc._onLoadColisTous', e, st);
      emit(state.copyWith(loadingTous: false, error: e.toString()));
    }
  }

  Future<PageResultat<Colis>> _chargerPageTous(int page, String statut) async {
    const demi = kTaillePage ~/ 2;
    final resultats = await Future.wait([
      getColisEnvoyes(page: page, limit: demi, statut: statut),
      getColisRecus(page: page, limit: demi, statut: statut),
    ]);
    final envoyes = resultats[0];
    final recus = resultats[1];
    final fusion = [...envoyes.elements, ...recus.elements]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final pages = envoyes.pagination.pages > recus.pagination.pages
        ? envoyes.pagination.pages
        : recus.pagination.pages;
    return PageResultat<Colis>(
      elements: fusion,
      pagination: InfoPagination(
        page: page,
        limit: kTaillePage,
        total: envoyes.pagination.total + recus.pagination.total,
        pages: pages,
      ),
      // Compteurs toutes pages : somme envoyés + reçus.
      parStatut: additionnerParStatut(envoyes.parStatut, recus.parStatut),
    );
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
      // Recharger automatiquement la liste après envoi : le nouveau colis
      // est en tête de la première page.
      add(LoadColisEnvoyes(page: 1));
      add(LoadColisTous(page: 1));
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
    emit(state.copyWith(loadingNotifications: true));
    try {
      final res = await chargerPageNonVide<NotificationModel>(
        event.page ?? state.paginationNotifications.page,
        (p) => getNotifications(page: p, limit: kTaillePage),
      );
      final nonLues = res is PageNotifications
          ? res.nonLues
          : res.elements.where((n) => !n.lue).length;
      emit(state.copyWith(
        notifications: res.elements,
        paginationNotifications: res.pagination,
        nonLues: nonLues,
        loadingNotifications: false,
      ));
    } catch (e, st) {
      AppLogger.error('Erreur dans ColisBloc._onLoadNotifications', e, st);
      emit(state.copyWith(loadingNotifications: false));
    }
  }

  Future<void> _onMarquerToutesLues(
      MarquerToutesNotificationsLuesRequested event,
      Emitter<ColisState> emit) async {
    try {
      await marquerToutesNotificationsLues();
    } catch (e, st) {
      AppLogger.error('Erreur dans ColisBloc._onMarquerToutesLues', e, st);
    }
    // Recharge la page courante (et le compteur `non_lues`).
    add(LoadNotifications());
  }

  Future<void> _onMarquerLue(
      MarquerNotificationLueRequested event, Emitter<ColisState> emit) async {
    try {
      await marquerNotificationLue(event.id);
      final etaitNonLue =
          state.notifications.any((n) => n.id == event.id && !n.lue);
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
      emit(state.copyWith(
        notifications: updated,
        nonLues: etaitNonLue && state.nonLues > 0
            ? state.nonLues - 1
            : state.nonLues,
      ));
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
