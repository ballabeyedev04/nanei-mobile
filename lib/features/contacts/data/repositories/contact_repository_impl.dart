import '../../domain/entities/contact_favori.dart';
import '../../domain/repositories/contact_repository.dart';
import '../datasources/contact_remote_datasource.dart';

class ContactRepositoryImpl implements ContactRepository {
  final ContactRemoteDataSource remoteDataSource;
  const ContactRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ContactFavori>> getContacts() =>
      remoteDataSource.getContacts();

  @override
  Future<ContactFavori> createContact(Map<String, dynamic> data) =>
      remoteDataSource.createContact(data);

  @override
  Future<ContactFavori> updateContact(String id, Map<String, dynamic> data) =>
      remoteDataSource.updateContact(id, data);

  @override
  Future<void> deleteContact(String id) => remoteDataSource.deleteContact(id);
}
