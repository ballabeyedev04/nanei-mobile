abstract class PaiementEvent {}

class LoadMesPaiements extends PaiementEvent {}

class InitierPaiementEvent extends PaiementEvent {
  final String colisId;
  final String moyenPaiement;
  InitierPaiementEvent({required this.colisId, required this.moyenPaiement});
}

class RefreshPaiements extends PaiementEvent {}
