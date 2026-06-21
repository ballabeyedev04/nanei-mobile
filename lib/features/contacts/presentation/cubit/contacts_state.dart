import 'package:equatable/equatable.dart';
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
  const ContactsLoaded(this.contacts);
  @override
  List<Object?> get props => [contacts];
}

class ContactsError extends ContactsState {
  final String message;
  const ContactsError(this.message);
  @override
  List<Object?> get props => [message];
}
