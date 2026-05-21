import 'package:flutter/material.dart';

import '../../../core/widgets/plumora_placeholder_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlumoraPlaceholderScreen(
      title: 'Discover',
      subtitle: 'Catalog and recommendation placeholder for published books.',
      icon: Icons.explore_outlined,
    );
  }
}
