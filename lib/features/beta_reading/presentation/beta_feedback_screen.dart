import 'package:flutter/material.dart';

import '../../../core/widgets/plumora_placeholder_screen.dart';

class BetaFeedbackScreen extends StatelessWidget {
  const BetaFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlumoraPlaceholderScreen(
      title: 'Bêta-retours',
      subtitle: 'Retours de bêta-lecture liés aux manuscrits.',
      icon: Icons.rate_review_outlined,
    );
  }
}
