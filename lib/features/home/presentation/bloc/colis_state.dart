import 'package:nanei/core/utils/pagination.dart';
import '../../domain/entities/colis.dart';
import '../../domain/entities/client_recherche.dart';
import '../../domain/entities/notification_model.dart';

class ColisState {
  /// Page courante des colis envoyés / reçus (pagination serveur).
  final List<Colis> colisEnvoyes;
  final List<Colis> colisRecus;
  final InfoPagination paginationEnvoyes;
  final InfoPagination paginationRecus;

  /// Filtre de statut appliqué côté serveur ('tous' = aucun).
  final String statutEnvoyes;
  final String statutRecus;
  final String statutTous;

  /// Compteurs `par_statut` (toutes pages, indépendants du filtre) :
  /// { en_attente, recupere, livre, total }. « Tous » = envoyés + reçus.
  final Map<String, int> parStatutEnvoyes;
  final Map<String, int> parStatutRecus;
  final Map<String, int> parStatutTous;

  /// Onglet « Tous » du suivi : envoyés + reçus de la page courante.
  final List<Colis> colisTous;
  final InfoPagination paginationTous;

  final int nbEnvoyes;
  final int nbRecus;
  final bool loadingEnvoyes;
  final bool loadingRecus;
  final bool loadingTous;
  final bool loadingStats;
  final bool sendingColis;
  final bool searchingClient;
  final List<ClientRecherche> resultatsRecherche;

  /// Page courante des notifications.
  final List<NotificationModel> notifications;
  final InfoPagination paginationNotifications;
  final bool loadingNotifications;

  /// Nombre total de notifications non lues, toutes pages (`non_lues`).
  final int nonLues;
  final String? error;
  // Après un envoi réussi : référence du colis
  final String? derniereColis;
  final bool colisEnvoye;

  const ColisState({
    this.colisEnvoyes = const [],
    this.colisRecus = const [],
    this.paginationEnvoyes = InfoPagination.initiale,
    this.paginationRecus = InfoPagination.initiale,
    this.statutEnvoyes = 'tous',
    this.statutRecus = 'tous',
    this.statutTous = 'tous',
    this.parStatutEnvoyes = const {},
    this.parStatutRecus = const {},
    this.parStatutTous = const {},
    this.colisTous = const [],
    this.paginationTous = InfoPagination.initiale,
    this.nbEnvoyes = 0,
    this.nbRecus = 0,
    this.loadingEnvoyes = false,
    this.loadingRecus = false,
    this.loadingTous = false,
    this.loadingStats = false,
    this.sendingColis = false,
    this.searchingClient = false,
    this.resultatsRecherche = const [],
    this.notifications = const [],
    this.paginationNotifications = InfoPagination.initiale,
    this.loadingNotifications = false,
    this.nonLues = 0,
    this.error,
    this.derniereColis,
    this.colisEnvoye = false,
  });

  ColisState copyWith({
    List<Colis>? colisEnvoyes,
    List<Colis>? colisRecus,
    InfoPagination? paginationEnvoyes,
    InfoPagination? paginationRecus,
    String? statutEnvoyes,
    String? statutRecus,
    String? statutTous,
    Map<String, int>? parStatutEnvoyes,
    Map<String, int>? parStatutRecus,
    Map<String, int>? parStatutTous,
    List<Colis>? colisTous,
    InfoPagination? paginationTous,
    int? nbEnvoyes,
    int? nbRecus,
    bool? loadingEnvoyes,
    bool? loadingRecus,
    bool? loadingTous,
    bool? loadingStats,
    bool? sendingColis,
    bool? searchingClient,
    List<ClientRecherche>? resultatsRecherche,
    List<NotificationModel>? notifications,
    InfoPagination? paginationNotifications,
    bool? loadingNotifications,
    int? nonLues,
    String? error,
    String? derniereColis,
    bool? colisEnvoye,
  }) {
    return ColisState(
      colisEnvoyes: colisEnvoyes ?? this.colisEnvoyes,
      colisRecus: colisRecus ?? this.colisRecus,
      paginationEnvoyes: paginationEnvoyes ?? this.paginationEnvoyes,
      paginationRecus: paginationRecus ?? this.paginationRecus,
      statutEnvoyes: statutEnvoyes ?? this.statutEnvoyes,
      statutRecus: statutRecus ?? this.statutRecus,
      statutTous: statutTous ?? this.statutTous,
      parStatutEnvoyes: parStatutEnvoyes ?? this.parStatutEnvoyes,
      parStatutRecus: parStatutRecus ?? this.parStatutRecus,
      parStatutTous: parStatutTous ?? this.parStatutTous,
      colisTous: colisTous ?? this.colisTous,
      paginationTous: paginationTous ?? this.paginationTous,
      nbEnvoyes: nbEnvoyes ?? this.nbEnvoyes,
      nbRecus: nbRecus ?? this.nbRecus,
      loadingEnvoyes: loadingEnvoyes ?? this.loadingEnvoyes,
      loadingRecus: loadingRecus ?? this.loadingRecus,
      loadingTous: loadingTous ?? this.loadingTous,
      loadingStats: loadingStats ?? this.loadingStats,
      sendingColis: sendingColis ?? this.sendingColis,
      searchingClient: searchingClient ?? this.searchingClient,
      resultatsRecherche: resultatsRecherche ?? this.resultatsRecherche,
      notifications: notifications ?? this.notifications,
      paginationNotifications:
          paginationNotifications ?? this.paginationNotifications,
      loadingNotifications: loadingNotifications ?? this.loadingNotifications,
      nonLues: nonLues ?? this.nonLues,
      error: error,
      derniereColis: derniereColis ?? this.derniereColis,
      colisEnvoye: colisEnvoye ?? this.colisEnvoye,
    );
  }
}
