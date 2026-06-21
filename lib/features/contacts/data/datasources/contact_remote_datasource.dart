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

  @override
  Future<List<ContactFavoriModel>> getContacts() async {
    final response = await dio.get(Env.contacts);
    final List data = response.data['data'] ?? [];
    return data
        .map((e) => ContactFavoriModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ContactFavoriModel> createContact(Map<String, dynamic> data) async {
    final response = await dio.post(Env.contacts, data: data);
    return ContactFavoriModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ContactFavoriModel> updateContact(
      String id, Map<String, dynamic> data) async {
    final response = await dio.put(Env.contactById(id), data: data);
    return ContactFavoriModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteContact(String id) async {
    await dio.delete(Env.contactById(id));
  }
}
