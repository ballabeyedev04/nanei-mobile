import 'package:nanei/core/utils/pagination.dart';
import '../entities/contact_favori.dart';
import '../repositories/contact_repository.dart';

class GetContacts {
  final ContactRepository repository;
  const GetContacts(this.repository);

  /// Sans [page] ni [limit] : liste complète.
  Future<PageResultat<ContactFavori>> call({int? page, int? limit}) =>
      repository.getContacts(page: page, limit: limit);
}
