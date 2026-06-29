import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

class CertificatePinningInterceptor extends Interceptor {
  // SHA-256 du certificat public de nanei.onrender.com
  // Pour obtenir le fingerprint :
  //   openssl s_client -connect nanei.onrender.com:443 2>/dev/null \
  //   | openssl x509 -pubkey -noout \
  //   | openssl pkey -pubin -outform der \
  //   | openssl dgst -sha256 -binary | base64
  // Primaire : certificat feuille de nanei.onrender.com
  // Backup   : intermédiaire Google Trust Services WE1 (survit au renouvellement ~90j)
  static const _allowedFingerprints = [
    'NnfKqDbhvUeabxD97xg7r9JvWoGY7BJjg8XThNJxVbk=',
    'kIdp6NNEd8wsugYyyIYFsi1ylMCED3hZbSR8ZFsa/A4=',
  ];

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Désactivé en debug pour faciliter le dev avec proxy
    if (kDebugMode) {
      return handler.next(options);
    }

    try {
      await HttpCertificatePinning.check(
        serverURL: options.baseUrl,
        sha: SHA.SHA256,
        allowedSHAFingerprints: _allowedFingerprints,
        timeout: 30,
      );
      handler.next(options);
    } catch (_) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Échec de la vérification du certificat TLS.',
          type: DioExceptionType.badCertificate,
        ),
      );
    }
  }
}
