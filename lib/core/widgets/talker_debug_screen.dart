import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:nanei/core/utils/app_logger.dart';

/// Accessible depuis les paramètres DEV (seulement en debug)
class TalkerDebugScreen extends StatelessWidget {
  const TalkerDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const Scaffold(body: Center(child: Text('Non disponible en production')));
    }
    return TalkerScreen(talker: AppLogger.instance);
  }
}
