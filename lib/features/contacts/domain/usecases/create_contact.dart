import '../entities/contact_favori.dart';
import '../repositories/contact_repository.dart';

class CreateContact {
  final ContactRepository repository;
  const CreateContact(this.repository);

  Future<ContactFavori> call(Map<String, dynamic> data) =>
      repository.createContact(data);
}
