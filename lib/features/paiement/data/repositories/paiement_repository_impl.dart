import '../../domain/entities/paiement.dart';
import '../../domain/repositories/paiement_repository.dart';
import '../datasources/paiement_remote_datasource.dart';

class PaiementRepositoryImpl implements PaiementRepository {
  final PaiementRemoteDataSource remoteDataSource;
  const PaiementRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Paiement>> mesPaiements() => remoteDataSource.mesPaiements();

  @override
  Future<String> initierPaiement({
    required String colisId,
    required String moyenPaiement,
  }) =>
      remoteDataSource.initierPaiement(
        colisId: colisId,
        moyenPaiement: moyenPaiement,
      );
}
