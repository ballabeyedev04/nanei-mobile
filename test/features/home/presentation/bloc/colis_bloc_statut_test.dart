import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:nanei/core/utils/pagination.dart';
import 'package:nanei/features/home/domain/entities/colis.dart';
import 'package:nanei/features/home/domain/usecases/envoyer_colis.dart';
import 'package:nanei/features/home/domain/usecases/get_colis_envoyes.dart';
import 'package:nanei/features/home/domain/usecases/get_colis_recus.dart';
import 'package:nanei/features/home/domain/usecases/get_notifications.dart';
import 'package:nanei/features/home/domain/usecases/get_statistiques_colis.dart';
import 'package:nanei/features/home/domain/usecases/marquer_notification_lue.dart';
import 'package:nanei/features/home/domain/usecases/marquer_toutes_notifications_lues.dart';
import 'package:nanei/features/home/domain/usecases/rechercher_client.dart';
import 'package:nanei/features/home/presentation/bloc/colis_bloc.dart';
import 'package:nanei/features/home/presentation/bloc/colis_event.dart';
import 'package:nanei/features/home/presentation/bloc/colis_state.dart';

class MockGetColisEnvoyes extends Mock implements GetColisEnvoyes {}

class MockGetColisRecus extends Mock implements GetColisRecus {}

class MockGetStatistiques extends Mock implements GetStatistiquesColis {}

class MockEnvoyerColis extends Mock implements EnvoyerColis {}

class MockRechercherClient extends Mock implements RechercherClient {}

class MockGetNotifications extends Mock implements GetNotifications {}

class MockMarquerLue extends Mock implements MarquerNotificationLue {}

class MockMarquerToutes extends Mock implements MarquerToutesNotificationsLues {}

PageResultat<Colis> _vide(Map<String, int> parStatut) => PageResultat(
      elements: const [],
      pagination: const InfoPagination(page: 1, limit: 20, total: 0, pages: 1),
      parStatut: parStatut,
    );

void main() {
  setUpAll(AppLogger.init);

  late MockGetColisEnvoyes envoyes;
  late MockGetColisRecus recus;

  setUp(() {
    envoyes = MockGetColisEnvoyes();
    recus = MockGetColisRecus();
  });

  ColisBloc build() => ColisBloc(
        getColisEnvoyes: envoyes,
        getColisRecus: recus,
        getStatistiques: MockGetStatistiques(),
        envoyerColis: MockEnvoyerColis(),
        rechercherClient: MockRechercherClient(),
        getNotifications: MockGetNotifications(),
        marquerNotificationLue: MockMarquerLue(),
        marquerToutesNotificationsLues: MockMarquerToutes(),
      );

  blocTest<ColisBloc, ColisState>(
    'changement de filtre : statut envoyé au serveur, page 1, par_statut lu',
    build: () {
      when(() => recus(page: 1, limit: kTaillePage, statut: 'livre'))
          .thenAnswer((_) async =>
              _vide({'en_attente': 2, 'recupere': 0, 'livre': 7, 'total': 9}));
      return build();
    },
    act: (b) => b.add(LoadColisRecus(page: 1, statut: 'livre')),
    verify: (b) {
      verify(() => recus(page: 1, limit: kTaillePage, statut: 'livre'))
          .called(1);
      expect(b.state.statutRecus, 'livre');
      expect(b.state.parStatutRecus['total'], 9);
    },
  );

  blocTest<ColisBloc, ColisState>(
    '« Tous » : même filtre pour envoyés et reçus, compteurs additionnés',
    build: () {
      when(() => envoyes(page: 1, limit: kTaillePage ~/ 2, statut: 'en_attente'))
          .thenAnswer((_) async =>
              _vide({'en_attente': 1, 'recupere': 1, 'livre': 3, 'total': 5}));
      when(() => recus(page: 1, limit: kTaillePage ~/ 2, statut: 'en_attente'))
          .thenAnswer((_) async =>
              _vide({'en_attente': 2, 'recupere': 0, 'livre': 1, 'total': 3}));
      return build();
    },
    act: (b) => b.add(LoadColisTous(page: 1, statut: 'en_attente')),
    verify: (b) {
      expect(b.state.statutTous, 'en_attente');
      expect(b.state.parStatutTous,
          {'en_attente': 3, 'recupere': 1, 'livre': 4, 'total': 8});
    },
  );
}
