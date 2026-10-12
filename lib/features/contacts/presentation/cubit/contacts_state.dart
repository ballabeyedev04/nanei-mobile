import 'package:equatable/equatable.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../../domain/entities/contact_favori.dart';

abstract class ContactsState extends Equatable {
  const ContactsState();
  @override
  List<Object?> get props => [];
}

class ContactsInitial extends ContactsState {
  const ContactsInitial();
}

class ContactsLoading extends ContactsState {
  const ContactsLoading();
}

class ContactsLoaded extends ContactsState {
  final List<ContactFavori> contacts;
  final InfoPagination pagination;
  ContactsLoaded(this.contacts, {InfoPagination? pagination})
      : pagination = pagination ?? InfoPagination.unePage(contacts.length);
  @override
  List<Object?> get props => [contacts, pagination];
}

class ContactsError extends ContactsState {
  final String message;
  const ContactsError(this.message);
  @override
  List<Object?> get props => [message];
}
