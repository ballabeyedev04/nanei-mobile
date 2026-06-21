import '../entities/paiement.dart';

abstract class PaiementRepository {
  Future<List<Paiement>> mesPaiements();
  Future<String> initierPaiement({
    required String colisId,
    required String moyenPaiement,
  });
}
