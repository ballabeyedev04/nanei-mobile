import '../entities/suivi_public.dart';
import '../repositories/colis_repository.dart';

/// Suivi public d'un colis par référence (`GET /suivi/:reference?format=json`).
/// Sans authentification — utilisable même déconnecté.
class SuiviPublicParReference {
  final ColisRepository repository;
  const SuiviPublicParReference(this.repository);

  Future<SuiviPublic> call(String reference) =>
      repository.suiviPublicParReference(reference);
}
