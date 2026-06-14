import '../../domain/entities/colis.dart';
import '../../domain/entities/client_recherche.dart';
import '../../domain/entities/notification_model.dart';

class ColisState {
  final List<Colis> colisEnvoyes;
  final List<Colis> colisRecus;
  final int nbEnvoyes;
  final int nbRecus;
  final bool loadingEnvoyes;
  final bool loadingRecus;
  final bool loadingStats;
  final bool sendingColis;
  final bool searchingClient;
  final List<ClientRecherche> resultatsRecherche;
  final List<NotificationModel> notifications;
  final String? error;
  // Après un envoi réussi : référence du colis
  final String? derniereColis;
  final bool colisEnvoye;

  const ColisState({
    this.colisEnvoyes = const [],
    this.colisRecus = const [],
    this.nbEnvoyes = 0,
    this.nbRecus = 0,
    this.loadingEnvoyes = false,
    this.loadingRecus = false,
    this.loadingStats = false,
    this.sendingColis = false,
    this.searchingClient = false,
    this.resultatsRecherche = const [],
    this.notifications = const [],
    this.error,
    this.derniereColis,
    this.colisEnvoye = false,
  });

  ColisState copyWith({
    List<Colis>? colisEnvoyes,
    List<Colis>? colisRecus,
    int? nbEnvoyes,
    int? nbRecus,
    bool? loadingEnvoyes,
    bool? loadingRecus,
    bool? loadingStats,
    bool? sendingColis,
    bool? searchingClient,
    List<ClientRecherche>? resultatsRecherche,
    List<NotificationModel>? notifications,
    String? error,
    String? derniereColis,
    bool? colisEnvoye,
  }) {
    return ColisState(
      colisEnvoyes: colisEnvoyes ?? this.colisEnvoyes,
      colisRecus: colisRecus ?? this.colisRecus,
      nbEnvoyes: nbEnvoyes ?? this.nbEnvoyes,
      nbRecus: nbRecus ?? this.nbRecus,
      loadingEnvoyes: loadingEnvoyes ?? this.loadingEnvoyes,
      loadingRecus: loadingRecus ?? this.loadingRecus,
      loadingStats: loadingStats ?? this.loadingStats,
      sendingColis: sendingColis ?? this.sendingColis,
      searchingClient: searchingClient ?? this.searchingClient,
      resultatsRecherche: resultatsRecherche ?? this.resultatsRecherche,
      notifications: notifications ?? this.notifications,
      error: error,
      derniereColis: derniereColis ?? this.derniereColis,
      colisEnvoye: colisEnvoye ?? this.colisEnvoye,
    );
  }
}
