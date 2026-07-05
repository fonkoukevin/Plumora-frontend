import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';

class BetaFeedbackScreen extends StatefulWidget {
  const BetaFeedbackScreen({this.bookId, super.key});

  final String? bookId;

  @override
  State<BetaFeedbackScreen> createState() => _BetaFeedbackScreenState();
}

class _BetaFeedbackScreenState extends State<BetaFeedbackScreen> {
  String _activeFilter = 'all';

  static const _filters = ['all', 'Incoherence', 'Rythme', 'Dialogue', 'Style'];
  static const _feedbacks = [
    _Feedback(
      chapter: 'Chapitre 3',
      type: 'Incoherence',
      priority: 'high',
      beta: 'Sarah Dubois',
      text:
          "Ce passage arrive trop vite, on ne comprend pas pourquoi elle change d'avis.",
      excerpt: "Elle changea d'avis brusquement...",
      icon: Icons.error_outline,
      color: PlumoraColors.destructive,
    ),
    _Feedback(
      chapter: 'Chapitre 2',
      type: 'Rythme lent',
      priority: 'medium',
      beta: 'Marc Lambert',
      text: "La description de la foret est trop longue, ca ralentit l'action.",
      excerpt: "La foret s'etendait devant...",
      icon: Icons.schedule,
      color: PlumoraColors.orange,
    ),
    _Feedback(
      chapter: 'Chapitre 4',
      type: 'Dialogue',
      priority: 'low',
      beta: 'Julie Martin',
      text: 'Le dialogue entre Clara et Elias manque de naturel.',
      excerpt: '"Nous devons partir maintenant"...',
      icon: Icons.chat_bubble_outline,
      color: PlumoraColors.primaryLight,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FigmaScreen(
      maxWidth: 1120,
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FigmaBackButton(
            label: 'Retour',
            onTap: () => context.go(AppRoutes.write),
          ),
          const SizedBox(height: 18),
          const Text(
            'Retours beta',
            style: TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'La Nuit Rouge - 12 commentaires recus',
            style: TextStyle(color: PlumoraColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 24),
          const _SummaryGrid(),
          const SizedBox(height: 22),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(
                  Icons.filter_list,
                  color: PlumoraColors.textSecondary,
                ),
                const SizedBox(width: 10),
                for (final filter in _filters) ...[
                  FigmaPillTab(
                    label: filter == 'all' ? 'Tous' : filter,
                    selected: _activeFilter == filter,
                    onTap: () => setState(() => _activeFilter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          for (final feedback in _feedbacks) ...[
            _FeedbackCard(feedback: feedback),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Rythme', '4', PlumoraColors.orange),
      ('Personnage', '3', Colors.blue),
      ('Incoherence', '2', PlumoraColors.destructive),
      ('Style', '3', PlumoraColors.primaryLight),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        final spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: FigmaCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              style: const TextStyle(
                                color: PlumoraColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              item.$2,
                              style: const TextStyle(
                                color: PlumoraColors.primary,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: item.$3.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            item.$2,
                            style: TextStyle(
                              color: item.$3,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});

  final _Feedback feedback;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: PlumoraColors.muted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(feedback.icon, color: feedback.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FigmaBadge(label: feedback.chapter),
                        FigmaBadge(
                          label: feedback.type,
                          backgroundColor: feedback.color.withValues(
                            alpha: 0.12,
                          ),
                          foregroundColor: feedback.color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      feedback.text,
                      style: const TextStyle(
                        color: PlumoraColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${feedback.excerpt}"',
                      style: const TextStyle(
                        color: PlumoraColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Par ${feedback.beta}',
                      style: const TextStyle(
                        color: PlumoraColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.editor),
                icon: const Icon(Icons.open_in_new),
                label: const Text("Ouvrir dans l'editeur"),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Marquer comme traite'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Feedback {
  const _Feedback({
    required this.chapter,
    required this.type,
    required this.priority,
    required this.beta,
    required this.text,
    required this.excerpt,
    required this.icon,
    required this.color,
  });

  final String chapter;
  final String type;
  final String priority;
  final String beta;
  final String text;
  final String excerpt;
  final IconData icon;
  final Color color;
}
