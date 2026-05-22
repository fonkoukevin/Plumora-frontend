import 'package:flutter/material.dart';

import '../../../core/widgets/plumora_placeholder_screen.dart';

class ManuscriptsScreen extends StatelessWidget {
  const ManuscriptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlumoraPlaceholderScreen(
      title: 'Mes manuscrits',
      subtitle: 'Gestion des livres et chapitres en cours.',
      icon: Icons.folder_copy_outlined,
    );
  }
}
