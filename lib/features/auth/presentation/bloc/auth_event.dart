import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String identifiant;
  final String mot_de_passe;

  const LoginRequested({
    required this.identifiant,
    required this.mot_de_passe,
  });

  @override
  List<Object?> get props => [identifiant, mot_de_passe];
}

class RegisterRequested extends AuthEvent {
  final String nom;
  final String prenom;
  final String email;
  final String mot_de_passe;
  final String adresse;
  final String telephone;

  const RegisterRequested({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.mot_de_passe,
    required this.adresse,
    required this.telephone
  });

  @override
  List<Object?> get props => [
    nom,
    prenom,
    email,
    mot_de_passe,
    adresse,
    telephone
  ];
}

class LogoutRequested extends AuthEvent {}

class ResetAuthState extends AuthEvent {}
