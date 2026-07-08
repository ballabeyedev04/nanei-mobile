import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

// Origine de l'action ayant produit l'état — nécessaire car AuthBloc est une
// instance UNIQUE partagée par LoginPage et RegisterPage (voir main.dart).
// LoginPage reste montée sous RegisterPage lors d'une navigation par simple
// push : sans ce tag, un échec d'inscription émettait un AuthFailure que les
// DEUX pages affichaient (le message correct sur Register, ET le message
// générique "Identifiant ou mot de passe incorrect" sur Login en dessous).
enum AuthAction { login, register, logout }

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;
  final AuthAction action;

  const AuthSuccess({required this.user, required this.action});

  @override
  List<Object?> get props => [user, action];
}

class AuthFailure extends AuthState {
  final String message;
  final AuthAction action;

  const AuthFailure({required this.message, required this.action});

  @override
  List<Object?> get props => [message, action];
}
