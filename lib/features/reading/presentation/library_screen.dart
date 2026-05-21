import 'package:flutter/material.dart';

import '../../../core/widgets/plumora_placeholder_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlumoraPlaceholderScreen(
      title: 'Library',
      subtitle: 'Reading, favorites, and beta-reading placeholder.',
      icon: Icons.local_library_outlined,
    );
  }
}
