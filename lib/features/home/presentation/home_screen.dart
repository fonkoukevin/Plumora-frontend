import 'package:flutter/material.dart';

import '../../../core/widgets/plumora_placeholder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlumoraPlaceholderScreen(
      title: 'Home',
      subtitle: 'Global dashboard placeholder for the MVP.',
      icon: Icons.dashboard_outlined,
    );
  }
}
