import 'package:equatable/equatable.dart';
import '../../domain/entities/avis_entity.dart';

abstract class AvisState extends Equatable {
  const AvisState();
  @override
  List<Object?> get props => [];
}

class AvisInitial extends AvisState {
  const AvisInitial();
}

class AvisEnvoi extends AvisState {
  const AvisEnvoi();
}

class AvisEnvoye extends AvisState {
  const AvisEnvoye();
}

class AvisChargement extends AvisState {
  const AvisChargement();
}

class AvisCharges extends AvisState {
  final List<AvisEntity> avis;
  const AvisCharges(this.avis);
  @override
  List<Object?> get props => [avis];
}

class AvisError extends AvisState {
  final String message;
  const AvisError(this.message);
  @override
  List<Object?> get props => [message];
}
