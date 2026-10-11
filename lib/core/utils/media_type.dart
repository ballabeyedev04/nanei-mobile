import 'package:dio/dio.dart';

/// Type MIME d'une image à téléverser, déduit de l'extension du fichier.
///
/// Indispensable : sans `contentType`, Dio envoie `application/octet-stream`
/// et le back (multer) refuse le fichier (« Type de fichier non autorisé »).
/// image_picker avec `imageQuality` produit du JPEG ; PNG / WEBP sont gardés
/// tels quels.
DioMediaType mediaTypeImage(String chemin) {
  final ext = chemin.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return DioMediaType('image', 'png');
    case 'webp':
      return DioMediaType('image', 'webp');
    default:
      return DioMediaType('image', 'jpeg');
  }
}

/// Fichier image prêt pour un `FormData`, avec le bon type MIME.
Future<MultipartFile> multipartImage(String chemin) =>
    MultipartFile.fromFile(chemin, contentType: mediaTypeImage(chemin));
