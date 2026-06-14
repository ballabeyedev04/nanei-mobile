import '../repositories/colis_repository.dart';

class MarquerNotificationLue {
  final ColisRepository repository;
  const MarquerNotificationLue(this.repository);
  Future<void> call(String id) => repository.marquerNotificationLue(id);
}
