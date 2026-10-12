import '../../domain/usecases/envoyer_colis.dart';

abstract class ColisEvent {}

// Pour les trois chargements de colis : [page] null → page courante ;
// [statut] null → filtre courant, 'tous' = aucun filtre, sinon en_attente |
// recupere | livre (filtré côté serveur, avant la pagination).

class LoadColisEnvoyes extends ColisEvent {
  final int? page;
  final String? statut;
  LoadColisEnvoyes({this.page, this.statut});
}

class LoadColisRecus extends ColisEvent {
  final int? page;
  final String? statut;
  LoadColisRecus({this.page, this.statut});
}

/// Onglet « Tous » du suivi : envoyés + reçus de la même page, fusionnés.
class LoadColisTous extends ColisEvent {
  final int? page;
  final String? statut;
  LoadColisTous({this.page, this.statut});
}

class LoadStatistiques extends ColisEvent {}

class EnvoyerColisRequested extends ColisEvent {
  final EnvoyerColisParams params;
  EnvoyerColisRequested(this.params);
}

class RechercherClientRequested extends ColisEvent {
  final String query;
  RechercherClientRequested(this.query);
}

/// [page] null → recharge la page courante.
class LoadNotifications extends ColisEvent {
  final int? page;
  LoadNotifications({this.page});
}

class MarquerNotificationLueRequested extends ColisEvent {
  final String id;
  MarquerNotificationLueRequested(this.id);
}

class MarquerToutesNotificationsLuesRequested extends ColisEvent {}

class ResetColisStatus extends ColisEvent {}
