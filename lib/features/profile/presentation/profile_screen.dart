import 'package:flutter/material.dart';

import '../../../core/widgets/plumora_placeholder_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlumoraPlaceholderScreen(
      title: 'Profile',
      subtitle: 'Profile placeholder for account and role information.',
      icon: Icons.person_outline,
    );
  }
}
