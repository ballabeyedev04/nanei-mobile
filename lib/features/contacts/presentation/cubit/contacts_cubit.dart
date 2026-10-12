import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/core/utils/api_error.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../../domain/entities/contact_favori.dart';
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

  /// Page affichée (rechargée quand [loadContacts] est appelé sans page).
  int _pageCourante = 1;
  int get pageCourante => _pageCourante;

  /// Charge la page [page] (null → page courante). Si elle est vide (ex.
  /// dernier contact d'une page supprimé), revient à la page précédente.
  Future<void> loadContacts({int? page}) async {
    emit(const ContactsLoading());
    try {
      final res = await chargerPageNonVide<ContactFavori>(
        page ?? _pageCourante,
        (p) => getContacts(page: p, limit: kTaillePage),
      );
      _pageCourante = res.pagination.page;
      emit(ContactsLoaded(res.elements, pagination: res.pagination));
    } catch (e, st) {
      AppLogger.error('Erreur dans ContactsCubit.loadContacts', e, st);
      AppLogger.warning('État erreur: ContactsCubit', e.toString());
      // Message lisible (celui du back, ou « Impossible de joindre le
      // serveur… ») : `e.toString()` affichait à l'écran le texte brut
      // « DioException [bad response]: … ».
      emit(ContactsError(messageErreurApi(e,
          fallback: 'Impossible de charger les contacts.')));
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
