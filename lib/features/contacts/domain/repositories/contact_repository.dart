import 'package:nanei/core/utils/pagination.dart';
import '../entities/contact_favori.dart';

abstract class ContactRepository {
  /// Sans [page] ni [limit] : liste complète.
  Future<PageResultat<ContactFavori>> getContacts({int? page, int? limit});
  Future<ContactFavori> createContact(Map<String, dynamic> data);
  Future<ContactFavori> updateContact(String id, Map<String, dynamic> data);
  Future<void> deleteContact(String id);
}
