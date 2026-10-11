import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../constants/storage_keys.dart';

class TokenService {
  final FlutterSecureStorage secureStorage;
  final StreamController<bool> _authController =
      StreamController<bool>.broadcast();

  TokenService({required this.secureStorage});

  Stream<bool> get authChanges => _authController.stream;

  /// Vérifie qu'un token existe ET qu'il n'est pas expiré.
  Future<bool> get isAuthenticated async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    return !_isTokenExpired(token);
  }

  Future<String?> getToken() async {
    return await secureStorage.read(key: StorageKeys.jwtToken);
  }

  /// Retourne le token uniquement s'il est valide (non expiré).
  Future<String?> getValidToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;
    if (_isTokenExpired(token)) {
      await clearToken();
      return null;
    }
    return token;
  }

  Future<void> setToken(String? token) async {
    if (token == null || token.isEmpty) {
      await secureStorage.delete(key: StorageKeys.jwtToken);
    } else {
      await secureStorage.write(key: StorageKeys.jwtToken, value: token);
    }
    final auth = await isAuthenticated;
    _authController.add(auth);
  }

  Future<void> clearToken() async {
    await secureStorage.delete(key: StorageKeys.jwtToken);
    await secureStorage.delete(key: StorageKeys.refreshToken);
    _authController.add(false);
  }

  Future<String?> getRefreshToken() async =>
      secureStorage.read(key: StorageKeys.refreshToken);

  Future<void> setRefreshToken(String? token) async {
    if (token == null || token.isEmpty) {
      await secureStorage.delete(key: StorageKeys.refreshToken);
    } else {
      await secureStorage.write(key: StorageKeys.refreshToken, value: token);
    }
  }

  /// Vérifie l'expiration du JWT côté client.
  bool _isTokenExpired(String token) {
    try {
      final payload = Jwt.parseJwt(token);
      final exp = payload['exp'];
      if (exp == null) return false;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      // Marge de 30 secondes pour compenser la latence réseau
      return DateTime.now()
          .isAfter(expiryDate.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }

  /// Rafraîchissement en cours, partagé par tous les appelants.
  Future<bool>? _refreshEnCours;

  final StreamController<void> _sessionExpireeController =
      StreamController<void>.broadcast();

  /// Émet quand le serveur refuse le refresh token (révoqué / expiré) :
  /// la session est morte, l'app doit renvoyer vers l'écran de connexion.
  Stream<void> get sessionExpiree => _sessionExpireeController.stream;

  /// Indique s'il reste un refresh token utilisable localement.
  Future<bool> get aUnRefreshToken async {
    final rt = await getRefreshToken();
    return rt != null && rt.isNotEmpty;
  }

  /// Tente de rafraîchir le JWT via le refresh token.
  ///
  /// MUTUALISÉ : si plusieurs requêtes reçoivent un 401 en même temps, une
  /// seule requête `POST /auth/refresh` part ; les autres attendent son
  /// résultat. Indispensable avec la rotation des refresh tokens : renvoyer
  /// l'ancien refresh token une deuxième fois serait refusé (« révoqué ») et
  /// déconnecterait l'utilisateur.
  ///
  /// [refreshCall] reçoit le refresh token et renvoie la réponse du back
  /// (`{ token, refreshToken }`) ; il lève une [DioException] en cas d'échec.
  /// Les jetons ne sont effacés que si le SERVEUR refuse le refresh token
  /// (400 / 401) — pas sur une simple coupure réseau.
  Future<bool> tryRefresh(
      Future<Map<String, dynamic>?> Function(String) refreshCall) {
    return _refreshEnCours ??=
        _executerRefresh(refreshCall).whenComplete(() => _refreshEnCours = null);
  }

  Future<bool> _executerRefresh(
      Future<Map<String, dynamic>?> Function(String) refreshCall) async {
    final rt = await getRefreshToken();
    if (rt == null || rt.isEmpty) return false;
    try {
      final data = await refreshCall(rt);
      final newJwt = data?['token'] as String?;
      final newRt = data?['refreshToken'] as String?;
      if (newJwt == null || newJwt.isEmpty) return false;
      // Le refresh token est rotatif : toujours conserver le NOUVEAU.
      if (newRt != null && newRt.isNotEmpty) await setRefreshToken(newRt);
      await setToken(newJwt);
      return true;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 400) {
        await clearToken();
        _sessionExpireeController.add(null);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _authController.close();
    _sessionExpireeController.close();
  }
}
