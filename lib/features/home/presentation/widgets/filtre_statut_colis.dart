/// Filtres de statut des listes de colis (libellé affiché → code envoyé au
/// back dans `statut`). Le filtrage est fait côté serveur, avant pagination.
const Map<String, String> filtresStatutColis = {
  'Tous': 'tous',
  'En attente': 'en_attente',
  'Récupéré': 'recupere',
  'Livré': 'livre',
};

/// Code `statut` pour un libellé de filtre ('tous' si inconnu).
String codeFiltreStatut(String libelle) =>
    filtresStatutColis[libelle] ?? 'tous';

/// Libellé de filtre pour un code `statut` ('Tous' si inconnu).
String libelleFiltreStatut(String code) => filtresStatutColis.entries
    .firstWhere((e) => e.value == code,
        orElse: () => filtresStatutColis.entries.first)
    .key;
