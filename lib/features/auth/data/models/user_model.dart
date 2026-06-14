import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.mot_de_passe,
    required super.adresse,
    required super.telephone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      mot_de_passe: json['mot_de_passe'] ?? '',
      adresse: json['adresse'] ?? '',
      telephone: json['telephone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'mot_de_passe': mot_de_passe,
      'adresse': adresse,
      'telephone': telephone,
    };
  }

  /// COPYWITH
  UserModel copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? mot_de_passe,
    String? adresse,
    String? telephone,
  }) {
    return UserModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      mot_de_passe: mot_de_passe ?? this.mot_de_passe,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
    );
  }
}

class AuthResponseModel {
  final String token;
  final UserModel user;

  AuthResponseModel({
    required this.token,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userData = json['utilisateur'] ?? {};

    return AuthResponseModel(
      token: json['token'] ?? '',
      user: UserModel.fromJson(userData as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'utilisateur': user.toJson(),
    };
  }

  AuthResponseModel copyWith({
    String? token,
    UserModel? user,
  }) {
    return AuthResponseModel(
      token: token ?? this.token,
      user: user ?? this.user,
    );
  }
}