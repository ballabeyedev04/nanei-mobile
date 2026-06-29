import 'package:dartz/dartz.dart';
import 'package:nanei/core/errors/failure.dart';
import '../repositories/avis_repository.dart';

class DonnerAvis {
  final AvisRepository repository;
  const DonnerAvis(this.repository);

  Future<Either<Failure, void>> call({
    required String colisId,
    required int note,
    String? commentaire,
  }) =>
      repository.donnerAvis(
        colisId: colisId,
        note: note,
        commentaire: commentaire,
      );
}
