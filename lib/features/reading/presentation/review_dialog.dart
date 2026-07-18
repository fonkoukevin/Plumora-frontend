import 'package:flutter/material.dart';

import '../../../core/theme/plumora_colors.dart';
import '../data/models/review_model.dart';

Future<ReviewUpsertRequest?> showPlumoraReviewDialog(BuildContext context) {
  return showDialog<ReviewUpsertRequest>(
    context: context,
    builder: (context) => const _ReviewDialog(),
  );
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _controller = TextEditingController();
  int _rating = 5;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Donner mon avis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Note', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var value = 1; value <= 5; value++)
                IconButton(
                  tooltip: '$value étoiles',
                  onPressed: () => setState(() => _rating = value),
                  icon: Icon(
                    value <= _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFF5C84C),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Commentaire',
              hintText: 'Partage ton ressenti sur ce livre...',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: context.colors.destructive,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Publier')),
      ],
    );
  }

  void _submit() {
    final comment = _controller.text.trim();
    if (comment.length < 3) {
      setState(() => _error = 'Ajoute un commentaire un peu plus détaillé.');
      return;
    }

    Navigator.of(
      context,
    ).pop(ReviewUpsertRequest(rating: _rating, comment: comment));
  }
}
