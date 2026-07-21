import 'package:dio/dio.dart';
import '../config/env.dart';
import '../utils/app_logger.dart';

/// Taux de conversion EUR -> FCFA utilisé pour l'affichage double devise
/// dans toute l'app. Chargé une fois au démarrage (voir main.dart) et mis
/// en cache en mémoire — tous les prix viennent du back en EUR, le FCFA est
/// calculé côté mobile uniquement pour l'affichage.
class TauxChangeService {
  TauxChangeService(this._dio);
  final Dio _dio;

  // Taux fixe officiel (XOF/XAF arrimé à l'euro par le Trésor français) —
  // utilisé tant que l'appel réseau n'a pas encore réussi.
  double _taux = 655.957;
  double get taux => _taux;

  Future<void> charger() async {
    try {
      final res = await _dio.get(Env.tauxChange);
      final valeur = (res.data['data']?['valeur'] as num?)?.toDouble();
      if (valeur != null && valeur > 0) {
        _taux = valeur;
      }
    } catch (e) {
      AppLogger.warning('TauxChangeService: échec chargement du taux, fallback utilisé', e.toString());
    }
  }
}
