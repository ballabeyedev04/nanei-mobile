class SecurityValidators {
  // ── Deep link ──────────────────────────────────────────────────────────────
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  /// Valide un email reçu via argument de route / deep link.
  /// Retourne l'email nettoyé ou null si invalide.
  static String? validateRouteEmail(Object? arg) {
    if (arg is! String) return null;
    final clean = arg.trim();
    if (clean.isEmpty || clean.length > 254) return null;
    if (!_emailRegex.hasMatch(clean)) return null;
    return clean;
  }

  // ── URL de paiement ────────────────────────────────────────────────────────
  static const _allowedPaymentHosts = [
    'checkout.wave.com',
    'pay.wave.com',
    'checkout.orange-money.com',
    'api.orange-money.com',
    'api.app-nanei.com',
  ];

  /// Valide que l'URL de paiement est HTTPS et pointe vers un domaine autorisé.
  /// Retourne l'Uri validé ou null si suspect.
  static Uri? validatePaymentUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return null;
    if (uri.scheme != 'https') return null;
    final host = uri.host.toLowerCase();
    final allowed = _allowedPaymentHosts.any(
      (h) => host == h || host.endsWith('.$h'),
    );
    if (!allowed) return null;
    return uri;
  }

  // ── Politique de mot de passe ──────────────────────────────────────────────
  static const _commonPasswords = [
    'password123', 'azerty123', '123456789012',
    'motdepasse1', 'nanei@2024', 'nanei@2025',
  ];

  /// Valide la robustesse d'un mot de passe (NIST SP 800-63B).
  /// Retourne null si valide, sinon le message d'erreur.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ce champ est requis';
    if (value.length < 12) return 'Minimum 12 caractères';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Au moins une majuscule requise';
    if (!value.contains(RegExp(r'[a-z]'))) return 'Au moins une minuscule requise';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Au moins un chiffre requis';
    if (!value.contains(RegExp(r'[!@#\$%^&*()\-_=+\[\]{};:,.<>?/\\|~`]'))) {
      return 'Au moins un caractère spécial requis (!@#\$%...)';
    }
    if (_commonPasswords.contains(value.toLowerCase())) {
      return 'Mot de passe trop commun, choisissez-en un autre';
    }
    return null;
  }

  /// Calcule la force du mot de passe (0 à 4).
  static int passwordStrength(String value) {
    int score = 0;
    if (value.length >= 12) score++;
    if (value.contains(RegExp(r'[A-Z]')) && value.contains(RegExp(r'[a-z]'))) score++;
    if (value.contains(RegExp(r'[0-9]'))) score++;
    if (value.contains(RegExp(r'[!@#\$%^&*()\-_=+\[\]{};:,.<>?/\\|~`]'))) score++;
    return score;
  }
}
