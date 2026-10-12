import '../repositories/colis_repository.dart';

class MarquerToutesNotificationsLues {
  final ColisRepository repository;
  const MarquerToutesNotificationsLues(this.repository);
  Future<void> call() => repository.marquerToutesNotificationsLues();
}
