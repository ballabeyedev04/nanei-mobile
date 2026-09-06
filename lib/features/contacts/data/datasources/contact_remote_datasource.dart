import 'package:dio/dio.dart';
import 'package:nanei/core/config/env.dart';

import '../models/contact_favori_model.dart';

abstract class ContactRemoteDataSource {
  Future<List<ContactFavoriModel>> getContacts();
  Future<ContactFavoriModel> createContact(Map<String, dynamic> data);
  Future<ContactFavoriModel> updateContact(String id, Map<String, dynamic> data);
  Future<void> deleteContact(String id);
}

class ContactRemoteDataSourceImpl implements ContactRemoteDataSource {
  final Dio dio;
  const ContactRemoteDataSourceImpl({required this.dio});

  // Le backend renvoie { success, contacts:[...] } et { success, message,
  // contact:{...} }. On tolère aussi la clé 'data' pour rester robuste si
  // l'enveloppe est normalisée un jour.
  Map<String, dynamic> _obj(dynamic body) {
    final m = body as Map<String, dynamic>? ?? const {};
    return (m['contact'] ?? m['data']) as Map<String, dynamic>;
  }

  @override
  Future<List<ContactFavoriModel>> getContacts() async {
    final response = await dio.get(Env.contacts);
    final body = response.data as Map<String, dynamic>? ?? const {};
    final List data = (body['contacts'] ?? body['data'] ?? const []) as List;
    return data
        .map((e) => ContactFavoriModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ContactFavoriModel> createContact(Map<String, dynamic> data) async {
    final response = await dio.post(Env.contacts, data: data);
    return ContactFavoriModel.fromJson(_obj(response.data));
  }

  @override
  Future<ContactFavoriModel> updateContact(
      String id, Map<String, dynamic> data) async {
    final response = await dio.put(Env.contactById(id), data: data);
    return ContactFavoriModel.fromJson(_obj(response.data));
  }

  @override
  Future<void> deleteContact(String id) async {
    await dio.delete(Env.contactById(id));
  }
}
