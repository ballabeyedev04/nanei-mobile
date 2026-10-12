import 'package:equatable/equatable.dart';
import 'package:nanei/core/utils/pagination.dart';
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

/// L'avis existait déjà (409) : traité comme un succès côté écran.
class AvisDejaDonne extends AvisState {
  const AvisDejaDonne();
}

class AvisChargement extends AvisState {
  const AvisChargement();
}

class AvisCharges extends AvisState {
  final List<AvisEntity> avis;
  final InfoPagination pagination;
  AvisCharges(this.avis, {InfoPagination? pagination})
      : pagination = pagination ?? InfoPagination.unePage(avis.length);
  @override
  List<Object?> get props => [avis, pagination];
}

class AvisError extends AvisState {
  final String message;
  const AvisError(this.message);
  @override
  List<Object?> get props => [message];
}
