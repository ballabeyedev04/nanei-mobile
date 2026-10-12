import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:nanei/core/utils/pagination.dart';
import 'package:nanei/features/home/domain/entities/client_recherche.dart';
import 'package:nanei/features/home/domain/entities/colis.dart';
import 'package:nanei/features/home/domain/entities/notification_model.dart';
import 'package:nanei/features/home/domain/entities/page_notifications.dart';
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

class _Envoyes extends Mock implements GetColisEnvoyes {}

class _Recus extends Mock implements GetColisRecus {}

class _Stats extends Mock implements GetStatistiquesColis {}

class _Envoyer extends Mock implements EnvoyerColis {}

class _Rechercher extends Mock implements RechercherClient {}

class _Notifs extends Mock implements GetNotifications {}

class _Lue extends Mock implements MarquerNotificationLue {}

class _Toutes extends Mock implements MarquerToutesNotificationsLues {}

/// Le bloc Colis : listes, statistiques, envoi, recherche, notifications.
///
/// ## Ce que ce fichier rend impossible
///
///  - un envoi réussi qui ne recharge pas la liste (le nouveau colis
///    n'apparaît qu'au redémarrage) ;
///  - un échec d'envoi présenté comme un succès ;
///  - une recherche en échec qui laisse l'indicateur tourner ;
///  - un badge de notifications faux : `non_lues` du serveur (toutes pages)
///    et non le décompte de la page ; décrémenté UNE fois quand on lit une
///    notification non lue, jamais sous zéro, jamais pour une déjà lue ;
///  - « Tout marquer comme lu » qui ne recharge pas le compteur.
void main() {
  setUpAll(() {
    AppLogger.init();
    registerFallbackValue(const EnvoyerColisParams(
        recepteurId: 'x', poids: 1, prix: 1, destination: 'x', typeColis: 'x'));
  });

  late _Envoyes envoyes;
  late _Recus recus;
  late _Stats stats;
  late _Envoyer envoyer;
  late _Rechercher rechercher;
  late _Notifs notifs;
  late _Lue lue;
  late _Toutes toutes;

  setUp(() {
    envoyes = _Envoyes();
    recus = _Recus();
    stats = _Stats();
    envoyer = _Envoyer();
    rechercher = _Rechercher();
    notifs = _Notifs();
    lue = _Lue();
    toutes = _Toutes();
  });

  ColisBloc construire() => ColisBloc(
        getColisEnvoyes: envoyes,
        getColisRecus: recus,
        getStatistiques: stats,
        envoyerColis: envoyer,
        rechercherClient: rechercher,
        getNotifications: notifs,
        marquerNotificationLue: lue,
        marquerToutesNotificationsLues: toutes,
      );

  Colis colis(String id, DateTime date) => Colis(
        id: id,
        reference: 'COL-$id',
        poids: 1,
        prix: 1,
        destination: 'Mali',
        statut: 'en_attente',
        type: 'x',
        createdAt: date,
      );

  NotificationModel notif(String id, {bool lu = false}) => NotificationModel(
        id: id,
        referenceColis: 'COL-$id',
        typeColis: 'x',
        descriptionColis: '',
        expediteurNom: 'B',
        expediteurPrenom: 'B',
        expediteurEmail: 'b@b.fr',
        date: DateTime(2026, 10, 1),
        lue: lu,
      );

  const params = EnvoyerColisParams(
      recepteurId: 'u-2', poids: 2, prix: 20, destination: 'Mali', typeColis: 'Document');

  blocTest<ColisBloc, ColisState>(
    'statistiques : compteurs envoyés / reçus',
    build: () {
      when(() => stats()).thenAnswer((_) async => {'envoyes': 3, 'recus': 2, 'total': 5});
      return construire();
    },
    act: (b) => b.add(LoadStatistiques()),
    verify: (b) {
      expect(b.state.nbEnvoyes, 3);
      expect(b.state.nbRecus, 2);
      expect(b.state.loadingStats, isFalse);
    },
  );

  blocTest<ColisBloc, ColisState>(
    'envoi réussi : référence mémorisée, liste rechargée en page 1',
    build: () {
      when(() => envoyer(any())).thenAnswer((_) async => 'COL-2026-NEW');
      when(() => envoyes(page: any(named: 'page'), limit: any(named: 'limit'), statut: any(named: 'statut')))
          .thenAnswer((_) async => PageResultat.unePage([colis('n', DateTime(2026, 10, 5))]));
      when(() => recus(page: any(named: 'page'), limit: any(named: 'limit'), statut: any(named: 'statut')))
          .thenAnswer((_) async => PageResultat<Colis>.vide());
      return construire();
    },
    act: (b) => b.add(EnvoyerColisRequested(params)),
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.colisEnvoye, isTrue);
      expect(b.state.derniereColis, 'COL-2026-NEW');
      expect(b.state.sendingColis, isFalse);
      verify(() => envoyes(page: 1, limit: kTaillePage, statut: 'tous')).called(1);
      expect(b.state.colisEnvoyes.single.id, 'n');
    },
  );

  blocTest<ColisBloc, ColisState>(
    'envoi refusé : erreur exposée, pas de « colisEnvoye »',
    build: () {
      when(() => envoyer(any())).thenThrow(Exception('Recepteur non trouvé'));
      return construire();
    },
    act: (b) => b.add(EnvoyerColisRequested(params)),
    verify: (b) {
      expect(b.state.colisEnvoye, isFalse);
      expect(b.state.sendingColis, isFalse);
      expect(b.state.error, contains('Recepteur non trouvé'));
    },
  );

  blocTest<ColisBloc, ColisState>(
    'onglet « Tous » : envoyés + reçus fusionnés du plus récent au plus ancien',
    build: () {
      when(() => envoyes(page: 1, limit: kTaillePage ~/ 2, statut: 'tous')).thenAnswer(
          (_) async => PageResultat(
                elements: [colis('e1', DateTime(2026, 10, 1))],
                pagination: const InfoPagination(page: 1, limit: 10, total: 11, pages: 2),
              ));
      when(() => recus(page: 1, limit: kTaillePage ~/ 2, statut: 'tous')).thenAnswer(
          (_) async => PageResultat(
                elements: [colis('r1', DateTime(2026, 10, 3))],
                pagination: const InfoPagination(page: 1, limit: 10, total: 4, pages: 1),
              ));
      return construire();
    },
    act: (b) => b.add(LoadColisTous(page: 1)),
    verify: (b) {
      expect(b.state.colisTous.map((c) => c.id), ['r1', 'e1']);
      expect(b.state.paginationTous.pages, 2);
      expect(b.state.paginationTous.total, 15);
    },
  );

  blocTest<ColisBloc, ColisState>(
    'recherche en échec : indicateur arrêté, résultats vidés',
    build: () {
      when(() => rechercher('awa@exemple.ml')).thenAnswer((_) async => const [
            ClientRecherche(id: 'u', nom: 'D', prenom: 'A', email: 'aw***@exemple.ml'),
          ]);
      when(() => rechercher('panne@exemple.ml')).thenThrow(Exception('réseau'));
      return construire();
    },
    act: (b) => b
      ..add(RechercherClientRequested('awa@exemple.ml'))
      ..add(RechercherClientRequested('panne@exemple.ml')),
    verify: (b) {
      expect(b.state.searchingClient, isFalse);
      expect(b.state.resultatsRecherche, isEmpty);
    },
  );

  group('notifications', () {
    PageNotifications page(List<NotificationModel> n, {int nonLues = 7}) =>
        PageNotifications(
          elements: n,
          pagination: const InfoPagination(page: 1, limit: 20, total: 30, pages: 2),
          nonLues: nonLues,
        );

    blocTest<ColisBloc, ColisState>(
      'badge = non_lues du serveur ; lire une non lue décrémente une fois',
      build: () {
        when(() => notifs(page: 1, limit: kTaillePage))
            .thenAnswer((_) async => page([notif('n1'), notif('n2', lu: true)]));
        when(() => lue(any())).thenAnswer((_) async {});
        return construire();
      },
      act: (b) async {
        b.add(LoadNotifications(page: 1));
        await Future<void>.delayed(Duration.zero);
        b.add(MarquerNotificationLueRequested('n1'));
        await Future<void>.delayed(Duration.zero);
        // Déjà lue : aucun décrément.
        b.add(MarquerNotificationLueRequested('n2'));
      },
      verify: (b) {
        expect(b.state.nonLues, 6);
        expect(b.state.notifications.every((n) => n.lue), isTrue);
        expect(b.state.paginationNotifications.pages, 2);
      },
    );

    blocTest<ColisBloc, ColisState>(
      'échec du marquage (404) : rien ne change',
      build: () {
        when(() => notifs(page: 1, limit: kTaillePage))
            .thenAnswer((_) async => page([notif('n1')], nonLues: 1));
        when(() => lue(any())).thenThrow(Exception('Notification introuvable'));
        return construire();
      },
      act: (b) async {
        b.add(LoadNotifications(page: 1));
        await Future<void>.delayed(Duration.zero);
        b.add(MarquerNotificationLueRequested('n1'));
      },
      verify: (b) {
        expect(b.state.nonLues, 1);
        expect(b.state.notifications.single.lue, isFalse);
      },
    );

    blocTest<ColisBloc, ColisState>(
      '« Tout marquer comme lu » recharge la page et le compteur du serveur',
      build: () {
        var appel = 0;
        when(() => notifs(page: any(named: 'page'), limit: kTaillePage)).thenAnswer(
            (_) async => appel++ == 0 ? page([notif('n1')], nonLues: 4) : page([notif('n1', lu: true)], nonLues: 0));
        when(() => toutes()).thenAnswer((_) async {});
        return construire();
      },
      act: (b) async {
        b.add(LoadNotifications(page: 1));
        await Future<void>.delayed(Duration.zero);
        b.add(MarquerToutesNotificationsLuesRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        verify(() => toutes()).called(1);
        expect(b.state.nonLues, 0);
      },
    );
  });
}
