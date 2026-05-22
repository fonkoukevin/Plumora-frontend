import 'package:flutter/material.dart';

import '../../../core/widgets/plumora_placeholder_screen.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlumoraPlaceholderScreen(
      title: 'Éditeur',
      subtitle: 'Espace de rédaction des chapitres.',
      icon: Icons.edit_note_outlined,
    );
  }
}
