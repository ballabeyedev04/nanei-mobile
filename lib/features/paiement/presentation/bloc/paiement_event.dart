abstract class PaiementEvent {}

/// [page] null → page courante. [statut] null → filtre courant ; 'tous' =
/// aucun filtre (sinon en_attente | en_cours | paye | echoue | rembourse).
class LoadMesPaiements extends PaiementEvent {
  final int? page;
  final String? statut;
  LoadMesPaiements({this.page, this.statut});
}

class InitierPaiementEvent extends PaiementEvent {
  final String colisId;
  final String moyenPaiement;
  InitierPaiementEvent({required this.colisId, required this.moyenPaiement});
}

/// Recharge la page courante.
class RefreshPaiements extends PaiementEvent {}
