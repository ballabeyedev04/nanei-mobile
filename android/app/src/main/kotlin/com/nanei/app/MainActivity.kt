package com.nanei.app

import io.flutter.embedding.android.FlutterFragmentActivity

// `FlutterFragmentActivity` et non `FlutterActivity` : le plugin local_auth
// affiche la boîte biométrique du système via un DialogFragment, qui exige un
// hôte FragmentActivity. Avec FlutterActivity, l'appel échoue à l'exécution
// (« no_fragment_activity ») — et seulement sur Android, donc invisible en
// test iOS ou sur simulateur.
class MainActivity : FlutterFragmentActivity()
