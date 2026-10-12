import '../entities/client_recherche.dart';
import '../repositories/colis_repository.dart';

final _emailComplet = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
final _caracteresTelephone = RegExp(r'^\+?[\d\s().\-]+$');

/// Le back ne cherche un destinataire que par e-mail COMPLET ou numéro de
/// téléphone (avec ou sans indicatif, au moins 5 caractères). Toute autre
/// saisie (nom, début d'e-mail…) ne renverrait rien : inutile d'appeler l'API.
bool estRechercheDestinataireValide(String query) {
  final q = query.trim();
  if (q.isEmpty) return false;
  if (q.contains('@')) return _emailComplet.hasMatch(q);
  if (!_caracteresTelephone.hasMatch(q)) return false;
  final chiffres = q.replaceAll(RegExp(r'\D'), '');
  return chiffres.length >= 5;
}

class RechercherClient {
  final ColisRepository repository;
  const RechercherClient(this.repository);

  /// Au plus un résultat, e-mail et téléphone masqués par le back ; l'envoi
  /// n'utilise que son `id`.
  Future<List<ClientRecherche>> call(String query) async {
    if (!estRechercheDestinataireValide(query)) return <ClientRecherche>[];
    return repository.rechercherClient(query.trim());
  }
}
