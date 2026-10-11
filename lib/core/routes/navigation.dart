import 'package:flutter/widgets.dart';

/// Clé du Navigator racine : permet de naviguer / afficher un toast depuis
/// un service (session expirée, lien profond de retour de paiement…), hors
/// de tout widget.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Contexte utilisable pour un toast / une navigation globale (null tant que
/// l'app n'est pas montée).
BuildContext? get contexteGlobal =>
    appNavigatorKey.currentState?.overlay?.context ??
    appNavigatorKey.currentContext;
