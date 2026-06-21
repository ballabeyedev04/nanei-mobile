import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nanei/core/config/env.dart';

class ShareTrackingWidget extends StatelessWidget {
  final String reference;

  const ShareTrackingWidget({super.key, required this.reference});

  @override
  Widget build(BuildContext context) {
    final lien = Env.suiviPublic(reference);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.share_rounded),
          tooltip: 'Partager le suivi',
          onPressed: () => Share.share(
            'Suivez mon colis Nanei en temps réel :\n$lien',
            subject: 'Suivi colis $reference',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded),
          tooltip: 'Copier le lien',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: lien));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lien copié !'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}
