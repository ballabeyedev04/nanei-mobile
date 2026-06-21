import '../../domain/entities/paiement.dart';

abstract class PaiementState {}

class PaiementInitial   extends PaiementState {}
class PaiementLoading   extends PaiementState {}
class PaiementInitiating extends PaiementState {} // spinner lors de l'initiation

class PaiementLoaded extends PaiementState {
  final List<Paiement> paiements;
  PaiementLoaded(this.paiements);
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
