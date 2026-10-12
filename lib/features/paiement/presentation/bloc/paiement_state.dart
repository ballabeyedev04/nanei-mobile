import 'package:nanei/core/utils/pagination.dart';
import '../../domain/entities/paiement.dart';

abstract class PaiementState {}

class PaiementInitial   extends PaiementState {}
class PaiementLoading   extends PaiementState {}
class PaiementInitiating extends PaiementState {} // spinner lors de l'initiation

class PaiementLoaded extends PaiementState {
  final List<Paiement> paiements;
  final InfoPagination pagination;

  /// Compteurs par statut sur toutes les pages (`par_statut` du back).
  final Map<String, int> parStatut;

  /// Filtre de statut appliqué ('tous' = aucun).
  final String statut;

  PaiementLoaded(
    this.paiements, {
    InfoPagination? pagination,
    this.parStatut = const {},
    this.statut = 'tous',
  }) : pagination = pagination ?? InfoPagination.unePage(paiements.length);

  /// Compteur `par_statut[cle]` ; à défaut (ancien back), calcul sur la page.
  int compte(String cle) =>
      parStatut[cle] ?? paiements.where((p) => p.statut == cle).length;
}

class PaiementUrlReady extends PaiementState {
  final String checkoutUrl;
  PaiementUrlReady(this.checkoutUrl);
}

class PaiementError extends PaiementState {
  final String message;
  PaiementError(this.message);
}

class PaiementInitiationError extends PaiementState {
  final String message;
  PaiementInitiationError(this.message);
}
