import '../../domain/usecases/envoyer_colis.dart';

abstract class ColisEvent {}

class LoadColisEnvoyes extends ColisEvent {}

class LoadColisRecus extends ColisEvent {}

class LoadStatistiques extends ColisEvent {}

class EnvoyerColisRequested extends ColisEvent {
  final EnvoyerColisParams params;
  EnvoyerColisRequested(this.params);
}

class RechercherClientRequested extends ColisEvent {
  final String query;
  RechercherClientRequested(this.query);
}

class LoadNotifications extends ColisEvent {}

class MarquerNotificationLueRequested extends ColisEvent {
  final String id;
  MarquerNotificationLueRequested(this.id);
}

class ResetColisStatus extends ColisEvent {}
