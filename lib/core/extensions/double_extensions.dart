import '../../injection_container.dart' as di;
import '../services/taux_change_service.dart';

extension DoubleFormatting on double {
  String toXof() => '${toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ')} FCFA';

  String toPourcent({int decimals = 1}) => '${toStringAsFixed(decimals)} %';

  bool get isPositive => this > 0;
  bool get isNegative => this < 0;

  String _fcfaFormatted() {
    final taux = di.sl<TauxChangeService>().taux;
    final fcfa = (this * taux).round();
    return fcfa.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');
  }

  /// Affiche un montant EUR (valeur brute venant du back) avec son
  /// équivalent FCFA : "12,50 € (≈ 8 199 FCFA)".
  String toEurFcfa({int decimals = 2}) =>
      '${toStringAsFixed(decimals)} € (≈ ${_fcfaFormatted()} FCFA)';

  /// Variante "prix par kg" : "5 €/kg (≈ 3 280 FCFA/kg)".
  ///
  /// Sans [decimals] : entier affiché sans décimale (« 5 €/kg »), sinon
  /// deux décimales (« 9.50 €/kg »). Avant, l'arrondi à l'unité affichait
  /// « 10 €/kg » pour une grille à 9,50 €/kg (prix au kg faux à l'écran,
  /// alors que le total, lui, était calculé sur 9,50).
  String toEurFcfaPerKg({int? decimals}) {
    final d = decimals ?? (this == roundToDouble() ? 0 : 2);
    return '${toStringAsFixed(d)} €/kg (≈ ${_fcfaFormatted()} FCFA/kg)';
  }
}

extension NullableDoubleFormatting on double? {
  String toXofOrDash() => this == null ? '—' : this!.toXof();
}
