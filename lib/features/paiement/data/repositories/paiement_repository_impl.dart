import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/core/utils/api_error.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../../domain/entities/paiement.dart';
import '../../domain/repositories/paiement_repository.dart';
import '../datasources/paiement_remote_datasource.dart';

class PaiementRepositoryImpl implements PaiementRepository {
  final PaiementRemoteDataSource remoteDataSource;
  const PaiementRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PageResultat<Paiement>>> mesPaiements(
      {int? page, int? limit, String? statut}) async {
    try {
      final result = await remoteDataSource.mesPaiements(
          page: page, limit: limit, statut: statut);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _mapDioError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> initierPaiement({
    required String colisId,
    required String moyenPaiement,
  }) async {
    try {
      final url = await remoteDataSource.initierPaiement(
        colisId: colisId,
        moyenPaiement: moyenPaiement,
      );
      return Right(url);
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
        // hors du `catch` — la liste restait bloquée en chargement.
        return messageErreurApi(e, fallback: 'Erreur de paiement.');
      default:
        return e.error?.toString() ?? 'Erreur inconnue.';
    }
  }
}
