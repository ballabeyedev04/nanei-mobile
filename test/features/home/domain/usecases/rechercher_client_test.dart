import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/features/home/domain/entities/client_recherche.dart';
import 'package:nanei/features/home/domain/repositories/colis_repository.dart';
import 'package:nanei/features/home/domain/usecases/rechercher_client.dart';

class MockColisRepository extends Mock implements ColisRepository {}

void main() {
  group('estRechercheDestinataireValide', () {
    test('e-mail complet', () {
      expect(estRechercheDestinataireValide('amadou@gmail.com'), isTrue);
      expect(estRechercheDestinataireValide('  a.b@c.sn '), isTrue);
    });

    test('e-mail incomplet refusé', () {
      expect(estRechercheDestinataireValide('amadou@'), isFalse);
      expect(estRechercheDestinataireValide('amadou@gmail'), isFalse);
    });

    test('téléphone avec ou sans indicatif', () {
      expect(estRechercheDestinataireValide('+223 70 12 34 56'), isTrue);
      expect(estRechercheDestinataireValide('701234'), isTrue);
      expect(estRechercheDestinataireValide('1234'), isFalse);
    });

    test('nom refusé (plus de recherche par nom)', () {
      expect(estRechercheDestinataireValide('Amadou'), isFalse);
      expect(estRechercheDestinataireValide(''), isFalse);
    });
  });

  group('RechercherClient', () {
    late MockColisRepository repo;
    setUp(() => repo = MockColisRepository());

    test("n'appelle pas l'API pour une saisie non valide", () async {
      final r = await RechercherClient(repo)('Amadou');
      expect(r, isEmpty);
      verifyNever(() => repo.rechercherClient(any()));
    });

    test('renvoie le résultat unique (masqué) du back', () async {
      when(() => repo.rechercherClient('amadou@gmail.com')).thenAnswer(
        (_) async => const [
          ClientRecherche(
            id: '42',
            nom: 'Diallo',
            prenom: 'Amadou',
            email: 'am***@gmail.com',
            telephone: '+223 ** ** 12 34',
          ),
        ],
      );
      final r = await RechercherClient(repo)(' amadou@gmail.com ');
      expect(r.single.id, '42');
    });
  });
}
