import 'package:flutter/material.dart';

import 'author_beta_comments_screen.dart';

class BetaFeedbackScreen extends StatelessWidget {
  const BetaFeedbackScreen({this.bookId, super.key});

  final String? bookId;

  @override
  Widget build(BuildContext context) {
    return AuthorBetaCommentsScreen(bookId: bookId);
  }
}
