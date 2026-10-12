import '../entities/page_notifications.dart';
import '../repositories/colis_repository.dart';

class GetNotifications {
  final ColisRepository repository;
  const GetNotifications(this.repository);

  /// Sans [page] ni [limit] : les 50 plus récentes (comportement du back).
  Future<PageNotifications> call({int? page, int? limit}) =>
      repository.getNotifications(page: page, limit: limit);
}
