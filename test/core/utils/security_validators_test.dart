import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/utils/security_validators.dart';

/// Validateurs de sécurité (e-mail, URL de paiement, mot de passe).
///
/// ## Ce que ce fichier rend impossible
///
///  - ouvrir dans le navigateur une URL de paiement HTTP, ou sur un domaine
///    qui imite un opérateur (`orange-money.com.evil.io`) ;
///  - REFUSER une vraie URL de paiement Orange Money : l'API Web Payment
///    renvoie un `payment_url` sur `mpayment.orange-money.com` (ou
///    `webpayment-qualif.` en recette), que l'ancienne liste blanche
///    rejetait — le paiement Orange Money était impossible ;
///  - accepter un e-mail que le back (Joi `email()`) refuserait ensuite ;
///  - accepter un mot de passe plus faible que la politique du back
///    (8 caractères, majuscule, minuscule, chiffre) : le mobile est PLUS
///    strict, jamais moins.
void main() {
  group('validatePaymentUrl', () {
    test('Wave (launch_url) et Orange Money (payment_url) réels acceptés', () {
      for (final url in [
        'https://pay.wave.com/c/cos-18qq4b2k82j1a',
        'https://checkout.wave.com/c/abc',
        'https://mpayment.orange-money.com/sn/mpayment/abstract/v1abcdef',
        'https://webpayment-qualif.orange-money.com/payment/pay_token/xyz',
      ]) {
        expect(SecurityValidators.validatePaymentUrl(url), isNotNull,
            reason: url);
      }
    });

    test('HTTP, domaine imité, hôte inconnu, vide : refusés', () {
      for (final url in [
        'http://pay.wave.com/c/x',
        'https://orange-money.com.evil.io/pay',
        'https://evilorange-money.com/pay',
        'https://wave.com.evil.io/c/x',
        'https://exemple.com',
        '',
        null,
        'pas une url',
      ]) {
        expect(SecurityValidators.validatePaymentUrl(url), isNull,
            reason: '$url');
      }
    });
  });

  group('validateEmail / validateRouteEmail', () {
    test('format du back', () {
      expect(SecurityValidators.validateEmail('awa@exemple.ml'), isNull);
      expect(SecurityValidators.validateEmail(' awa@exemple.ml '), isNull);
      expect(SecurityValidators.validateEmail('a@b'), isNotNull);
      expect(SecurityValidators.validateEmail(''), 'Email requis');
    });

    test('argument de route : nettoyé ou rejeté', () {
      expect(SecurityValidators.validateRouteEmail(' awa@exemple.ml '),
          'awa@exemple.ml');
      expect(SecurityValidators.validateRouteEmail(42), isNull);
      expect(SecurityValidators.validateRouteEmail('x' * 250 + '@a.fr'), isNull);
      expect(SecurityValidators.validateRouteEmail('pas-un-email'), isNull);
    });
  });

  group('validatePassword', () {
    test('un mot de passe conforme passe', () {
      expect(SecurityValidators.validatePassword('Colis-Bamako-2026'), isNull);
    });

    test('chaque règle a son message', () {
      expect(SecurityValidators.validatePassword(''), 'Ce champ est requis');
      expect(SecurityValidators.validatePassword('Court1!'), 'Minimum 12 caractères');
      expect(SecurityValidators.validatePassword('minuscules-123'),
          'Au moins une majuscule requise');
      expect(SecurityValidators.validatePassword('MAJUSCULES-123'),
          'Au moins une minuscule requise');
      expect(SecurityValidators.validatePassword('SansChiffre-ok'),
          'Au moins un chiffre requis');
      expect(SecurityValidators.validatePassword('SansSpecial123'),
          startsWith('Au moins un caractère spécial'));
    });

    test('tout mot de passe accepté par le mobile l’est aussi par le back', () {
      // Règle Joi `motDePasse` (validations/common.js).
      final back = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,128}$');
      for (final mdp in ['Colis-Bamako-2026', 'Aa1!aaaaaaaa', 'Zz9#Zz9#Zz9#']) {
        expect(SecurityValidators.validatePassword(mdp), isNull);
        expect(back.hasMatch(mdp), isTrue, reason: mdp);
      }
    });

    test('force du mot de passe : de 0 à 4', () {
      expect(SecurityValidators.passwordStrength(''), 0);
      expect(SecurityValidators.passwordStrength('Colis-Bamako-2026'), 4);
    });
  });
}
