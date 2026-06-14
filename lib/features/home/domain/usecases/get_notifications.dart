import '../entities/notification_model.dart';
import '../repositories/colis_repository.dart';

class GetNotifications {
  final ColisRepository repository;
  const GetNotifications(this.repository);
  Future<List<NotificationModel>> call() => repository.getNotifications();
}
