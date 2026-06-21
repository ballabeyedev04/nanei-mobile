import '../repositories/paiement_repository.dart';

class InitierPaiement {
  final PaiementRepository repository;
  const InitierPaiement(this.repository);

  Future<String> call({
    required String colisId,
    required String moyenPaiement,
  }) =>
      repository.initierPaiement(
        colisId: colisId,
        moyenPaiement: moyenPaiement,
      );
}
