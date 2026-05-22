import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  String _activeTab = 'Mes manuscrits';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final horizontal = isWide ? 32.0 : 16.0;
        final bottomPadding = constraints.maxWidth >= 900 ? 32.0 : 82.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            28,
            horizontal,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(isWide: isWide),
                  const SizedBox(height: 24),
                  PlumoraSegmentedTabs(
                    tabs: const [
                      'Mes manuscrits',
                      'Retours bêta',
                      'Publication',
                    ],
                    selectedTab: _activeTab,
                    onSelected: (value) => setState(() => _activeTab = value),
                  ),
                  const SizedBox(height: 26),
                  if (_activeTab == 'Mes manuscrits') const _ManuscriptsTab(),
                  if (_activeTab == 'Retours bêta') const _FeedbackTab(),
                  if (_activeTab == 'Publication') const _PublicationTab(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Écrire',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: PlumoraColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Gérez vos manuscrits et votre activité d'auteur",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: PlumoraColors.textSecondary),
        ),
      ],
    );

    final button = FilledButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add, size: 19),
      label: const Text('Nouveau livre'),
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: button),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        button,
      ],
    );
  }
}

class _ManuscriptsTab extends StatelessWidget {
  const _ManuscriptsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 940
                ? 3
                : constraints.maxWidth >= 650
                ? 2
                : 1;
            const spacing = 16.0;
            final width = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: 16,
              children: [
                for (final manuscript in _manuscripts)
                  SizedBox(
                    width: width,
                    child: _ManuscriptCard(manuscript: manuscript),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        const _StatsGrid(),
      ],
    );
  }
}

class _ManuscriptCard extends StatelessWidget {
  const _ManuscriptCard({required this.manuscript});

  final _Manuscript manuscript;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      clip: true,
      child: Stack(
        children: [
          Positioned(
            top: -62,
            right: -62,
            child: Container(
              width: 128,
              height: 128,
              decoration: const BoxDecoration(
                color: Color(0x1AA88A54),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      manuscript.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  PlumoraBadge(
                    label: manuscript.badge,
                    backgroundColor: manuscript.badgeBackground,
                    foregroundColor: manuscript.badgeColor,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (manuscript.progress != null) ...[
                _InfoPill(
                  icon: Icons.schedule,
                  label: "Modifié ${manuscript.lastModified}",
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Progression',
                              style: TextStyle(
                                color: PlumoraColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${manuscript.progress}%',
                            style: const TextStyle(
                              color: PlumoraColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: (manuscript.progress ?? 0) / 100,
                          backgroundColor: Colors.white,
                          color: PlumoraColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _InfoPill(
                  icon: manuscript.feedbacks == null
                      ? Icons.check_circle_outline
                      : Icons.forum_outlined,
                  label: manuscript.feedbacks == null
                      ? 'Prêt pour la publication'
                      : '${manuscript.feedbacks} retours reçus',
                  foregroundColor: manuscript.feedbacks == null
                      ? PlumoraColors.success
                      : PlumoraColors.info,
                  backgroundColor: manuscript.feedbacks == null
                      ? const Color(0xFFE6F0E7)
                      : const Color(0xFFE8F0F5),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: manuscript.route == null
                    ? OutlinedButton(
                        onPressed: () {},
                        child: Text(manuscript.action),
                      )
                    : FilledButton(
                        onPressed: () => context.go(manuscript.route!),
                        child: Text(manuscript.action),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    this.foregroundColor = PlumoraColors.textSecondary,
    this.backgroundColor = PlumoraColors.muted,
  });

  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 3 : 1;
        const spacing = 16.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: const [
            _StatCard(label: 'Total de manuscrits', value: '3'),
            _StatCard(label: "En cours d'écriture", value: '1'),
            _StatCard(label: 'Livres publiés', value: '1'),
          ].map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      shadow: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: PlumoraColors.primary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Retours bêta récents',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.betaFeedback),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _FeedbackCard(
          chapter: 'Chapitre 3',
          type: 'Incohérence',
          book: 'Les Ombres de Minuit',
          beta: 'Sarah Dubois',
          highPriority: true,
        ),
        const SizedBox(height: 14),
        const _FeedbackCard(
          chapter: 'Chapitre 2',
          type: 'Rythme lent',
          book: 'Les Ombres de Minuit',
          beta: 'Marc Lambert',
          highPriority: false,
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.chapter,
    required this.type,
    required this.book,
    required this.beta,
    required this.highPriority,
  });

  final String chapter;
  final String type;
  final String book;
  final String beta;
  final bool highPriority;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      leftAccent: PlumoraColors.primary,
      onTap: () => context.go(AppRoutes.betaFeedback),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PlumoraBadge(
                      label: chapter,
                      backgroundColor: const Color(0xFFE6EFE4),
                      foregroundColor: const Color(0xFF5F7A5A),
                    ),
                    PlumoraBadge(
                      label: type,
                      backgroundColor: highPriority
                          ? const Color(0xFFF7E0DC)
                          : const Color(0xFFF8E6D2),
                      foregroundColor: highPriority
                          ? const Color(0xFFA85B50)
                          : const Color(0xFFA4683E),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  book,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Par $beta',
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: PlumoraColors.primary),
        ],
      ),
    );
  }
}

class _PublicationTab extends StatelessWidget {
  const _PublicationTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PlumoraCard(
          leftAccent: PlumoraColors.primary,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PlumoraIconTile(
                child: Icon(Icons.cloud_upload_outlined, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prêt à publier ?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vos manuscrits prêts pour la publication apparaîtront ici. Complétez tous les éléments requis avant de soumettre.',
                      style: TextStyle(
                        color: PlumoraColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('Soumettre un livre'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _manuscripts = [
  _Manuscript(
    title: 'La Nuit Rouge',
    badge: 'Brouillon',
    badgeBackground: Color(0xFFF1E8D8),
    badgeColor: Color(0xFF8E7345),
    progress: 35,
    lastModified: "aujourd'hui",
    action: 'Continuer',
    route: AppRoutes.editor,
  ),
  _Manuscript(
    title: 'Les Ombres de Minuit',
    badge: 'Bêta-test',
    badgeBackground: Color(0xFFE6EFE4),
    badgeColor: Color(0xFF5F7A5A),
    feedbacks: 12,
    action: 'Voir les retours',
    route: AppRoutes.betaFeedback,
  ),
  _Manuscript(
    title: "Sang d'Encre",
    badge: 'Prêt',
    badgeBackground: Color(0xFFE6F0E7),
    badgeColor: Color(0xFF4F7A56),
    action: 'Soumettre à publication',
  ),
];

class _Manuscript {
  const _Manuscript({
    required this.title,
    required this.badge,
    required this.badgeBackground,
    required this.badgeColor,
    required this.action,
    this.progress,
    this.lastModified,
    this.feedbacks,
    this.route,
  });

  final String title;
  final String badge;
  final Color badgeBackground;
  final Color badgeColor;
  final String action;
  final int? progress;
  final String? lastModified;
  final int? feedbacks;
  final String? route;
}
