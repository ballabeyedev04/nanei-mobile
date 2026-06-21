import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/core/utils/app_logger.dart';
import '../../domain/usecases/get_contacts.dart';
import '../../domain/usecases/create_contact.dart';
import '../../domain/usecases/delete_contact.dart';
import 'contacts_state.dart';

class ContactsCubit extends Cubit<ContactsState> {
  final GetContacts getContacts;
  final CreateContact createContact;
  final DeleteContact deleteContact;

  ContactsCubit({
    required this.getContacts,
    required this.createContact,
    required this.deleteContact,
  }) : super(const ContactsInitial());

  Future<void> loadContacts() async {
    emit(const ContactsLoading());
    try {
      final contacts = await getContacts();
      emit(ContactsLoaded(contacts));
    } catch (e, st) {
      AppLogger.error('Erreur dans ContactsCubit.loadContacts', e, st);
      AppLogger.warning('État erreur: ContactsCubit', e.toString());
      emit(ContactsError(e.toString()));
    }
  }

  Future<bool> ajouterContact(Map<String, dynamic> data) async {
    try {
      await createContact(data);
      await loadContacts();
      return true;
    } catch (e, st) {
      AppLogger.error('Erreur dans ContactsCubit.ajouterContact', e, st);
      return false;
    }
  }

  Future<bool> supprimerContact(String id) async {
    try {
      await deleteContact(id);
      await loadContacts();
      return true;
    } catch (e, st) {
      AppLogger.error('Erreur dans ContactsCubit.supprimerContact', e, st);
      return false;
    }
  }
}
