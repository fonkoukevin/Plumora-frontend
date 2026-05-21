import 'package:flutter/material.dart';

import '../../../core/widgets/plumora_placeholder_screen.dart';

class WriteScreen extends StatelessWidget {
  const WriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlumoraPlaceholderScreen(
      title: 'Write',
      subtitle: 'Author workspace placeholder for books and chapters.',
      icon: Icons.edit_note_outlined,
    );
  }
}
