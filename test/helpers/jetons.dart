import 'dart:convert';

/// Fabrique un JWT de test (non signé : seul le contenu compte pour le
/// mobile, qui ne lit que `exp`). [expireDans] négatif → jeton déjà expiré.
String jwtDeTest({Duration expireDans = const Duration(hours: 1), String id = 'u-1'}) {
  String b64(Map<String, Object?> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp = DateTime.now().add(expireDans).millisecondsSinceEpoch ~/ 1000;
  return '${b64({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${b64({'id': id, 'exp': exp})}.signature';
}
