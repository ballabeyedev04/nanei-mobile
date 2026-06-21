import '../repositories/contact_repository.dart';

class DeleteContact {
  final ContactRepository repository;
  const DeleteContact(this.repository);

  Future<void> call(String id) => repository.deleteContact(id);
}
