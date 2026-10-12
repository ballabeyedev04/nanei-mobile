import 'package:nanei/core/utils/pagination.dart';
import 'notification_model.dart';

/// Page de notifications + nombre total de non lues (toutes pages), renvoyé
/// par le back dans `non_lues`.
class PageNotifications extends PageResultat<NotificationModel> {
  final int nonLues;

  const PageNotifications({
    required super.elements,
    required super.pagination,
    required this.nonLues,
  });
}
