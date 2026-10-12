import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/core/utils/api_error.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../../domain/entities/avis_entity.dart';
import '../../domain/repositories/avis_repository.dart';
import '../datasources/avis_remote_datasource.dart';

class AvisRepositoryImpl implements AvisRepository {
  final AvisRemoteDataSource remoteDataSource;
  const AvisRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> donnerAvis({
    required String colisId,
    required int note,
    String? commentaire,
  }) async {
    try {
      await remoteDataSource.donnerAvis(
        colisId: colisId,
        note: note,
        commentaire: commentaire,
      );
      return const Right(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return Left(AvisDejaDonneFailure(
            errorMessage: 'Vous avez déjà donné votre avis sur ce colis.'));
      }
      return Left(ServerFailure(errorMessage: _mapDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PageResultat<AvisEntity>>> mesAvis(
      {int? page, int? limit}) async {
    try {
      final result = await remoteDataSource.mesAvis(page: page, limit: limit);
      return Right(PageResultat<AvisEntity>(
          elements: result.elements, pagination: result.pagination));
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _mapDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connexion trop lente. Vérifiez votre réseau.';
      case DioExceptionType.receiveTimeout:
        return 'Le serveur met trop de temps à répondre.';
      case DioExceptionType.connectionError:
        return 'Impossible de joindre le serveur.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code >= 500) return 'Erreur serveur. Réessayez plus tard.';
        // Corps d'erreur NON JSON (page HTML d'un proxy, d'un WAF) : `data`
        // est alors une String et `data['message']` levait une exception
        // hors du `catch` — l'écran restait bloqué en chargement.
        return messageErreurApi(e,
            fallback: 'Erreur lors de l\'envoi de l\'avis.');
      default:
        return e.error?.toString() ?? 'Erreur inconnue.';
    }
  }
}
