import '../entities/contact_favori.dart';
import '../repositories/contact_repository.dart';

class GetContacts {
  final ContactRepository repository;
  const GetContacts(this.repository);

  Future<List<ContactFavori>> call() => repository.getContacts();
}
