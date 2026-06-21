import '../entities/contact_favori.dart';

abstract class ContactRepository {
  Future<List<ContactFavori>> getContacts();
  Future<ContactFavori> createContact(Map<String, dynamic> data);
  Future<ContactFavori> updateContact(String id, Map<String, dynamic> data);
  Future<void> deleteContact(String id);
}
