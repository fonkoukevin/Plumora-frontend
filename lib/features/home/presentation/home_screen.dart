import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_logo_mark.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final user = session?.user;
    final displayName = _firstNameFor(user);
    final roleNames =
        session?.roles.map((role) => role.name).toSet() ?? const <String>{};
    final actions = _actionsForRoles(roleNames);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final horizontal = isWide ? 32.0 : 16.0;
        final bottomPadding = constraints.maxWidth >= 900 ? 32.0 : 82.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            21,
            horizontal,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 1120 : 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeHeader(displayName: displayName),
                  const SizedBox(height: 27),
                  const _QuoteBanner(),
                  const SizedBox(height: 27),
                  Text(
                    'Vos manuscrits',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ActionGrid(actions: actions),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Activité récente',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Tout voir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const _ActivityGrid(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _firstNameFor(dynamic user) {
    final firstname = user?.firstname.trim();
    if (firstname is String && firstname.isNotEmpty) {
      return firstname;
    }

    final username = user?.username?.trim();
    if (username is String && username.isNotEmpty) {
      return username;
    }

    final displayName = user?.displayName.toString().trim();
    if (displayName is String && displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }

    return 'Kevin';
  }

  List<_HomeAction> _actionsForRoles(Set<String> roles) {
    const allActions = [
      _HomeAction.continueWriting,
      _HomeAction.discoverBook,
      _HomeAction.betaReading,
    ];

    if (roles.isEmpty) {
      return allActions;
    }

    final prioritized = allActions
        .where((action) => roles.contains(action.roleName))
        .toList(growable: false);
    final remaining = allActions
        .where((action) => !roles.contains(action.roleName))
        .toList(growable: false);

    return [...prioritized, ...remaining];
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const PlumoraLogoMark(
              size: 33,
              color: PlumoraColors.primary,
              strokeWidth: 1.9,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Plumora',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_outlined),
              color: PlumoraColors.textSecondary,
              iconSize: 21,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 7),
            InkWell(
              onTap: () => context.go(AppRoutes.profile),
              customBorder: const CircleBorder(),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFB384D8), Color(0xFF7737B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Flexible(
              child: Text(
                'Bonjour, $displayName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 7),
            const _AnimatedWaveHand(),
          ],
        ),
      ],
    );
  }
}

class _AnimatedWaveHand extends StatefulWidget {
  const _AnimatedWaveHand();

  @override
  State<_AnimatedWaveHand> createState() => _AnimatedWaveHandState();
}

class _AnimatedWaveHandState extends State<_AnimatedWaveHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _turns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _turns = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.04, end: 0.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.02), weight: 35),
      TweenSequenceItem(tween: Tween(begin: -0.02, end: 0.03), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _turns,
      child: const Text('\u{1F44B}', style: TextStyle(fontSize: 16)),
    );
  }
}

class _QuoteBanner extends StatelessWidget {
  const _QuoteBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      decoration: BoxDecoration(
        color: PlumoraColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.format_quote,
            color: PlumoraColors.primary,
            size: 30,
          ),
          const SizedBox(width: 27),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '"N\'attendez pas l\'inspiration. Elle vient en écrivant."',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '— Victor Hugo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PlumoraColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<_HomeAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 2 : 1;
        final spacing = columns == 1 ? 18.0 : 20.0;
        final cardWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: 18,
          children: [
            for (final action in actions)
              SizedBox(
                width: cardWidth,
                child: _ActionCard(action: action),
              ),
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _HomeAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(action.path),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 103),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: PlumoraColors.cards,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PlumoraColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x17000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -53,
              right: -41,
              child: Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE4D8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 19, 16, 17),
              child: Row(
                children: [
                  _CardIconBox(action: action),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          action.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          action.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: PlumoraColors.textSecondary,
                                fontSize: 11,
                              ),
                        ),
                        if (action.progress != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    minHeight: 3,
                                    value: action.progress,
                                    backgroundColor: const Color(0xFFE8DCCA),
                                    color: PlumoraColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${((action.progress ?? 0) * 100).round()}%',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: PlumoraColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ],
                        if (action.meta != null) ...[
                          const SizedBox(height: 7),
                          Text(
                            action.meta!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: action.metaColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardIconBox extends StatelessWidget {
  const _CardIconBox({required this.action});

  final _HomeAction action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: action.iconBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: action.useLogoMark
            ? PlumoraLogoMark(
                size: 25,
                color: action.iconColor,
                strokeWidth: 2.0,
              )
            : Icon(action.icon, color: action.iconColor, size: 25),
      ),
    );
  }
}

class _ActivityGrid extends StatelessWidget {
  const _ActivityGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final spacing = 14.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: const [
            _ActivityCard(
              title: 'Chapitre 3 modifié',
              subtitle: 'La Nuit Rouge',
              meta: 'Il y a 2h',
              useLogoMark: true,
              accent: PlumoraColors.primary,
            ),
            _ActivityCard(
              title: '4 nouveaux retours bêta',
              subtitle: 'Les Ombres de Minuit',
              meta: 'Hier',
              icon: Icons.chat_bubble_outline,
              accent: PlumoraColors.mukemeAccent,
            ),
            _ActivityCard(
              title: 'Livre publié \u{1F389}',
              subtitle: "Sang d'Encre",
              meta: 'Il y a 3 jours',
              icon: Icons.check_circle_outline,
              accent: PlumoraColors.primary,
            ),
          ].map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.accent,
    this.icon,
    this.useLogoMark = false,
  });

  final String title;
  final String subtitle;
  final String meta;
  final IconData? icon;
  final bool useLogoMark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 97,
      decoration: BoxDecoration(
        color: PlumoraColors.cards,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accent, width: 3),
          top: const BorderSide(color: PlumoraColors.border),
          right: const BorderSide(color: PlumoraColors.border),
          bottom: const BorderSide(color: PlumoraColors.border),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 16, 16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withAlpha(32),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: useLogoMark
                    ? PlumoraLogoMark(size: 21, color: accent, strokeWidth: 2.0)
                    : Icon(icon, color: accent, size: 21),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PlumoraColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    meta,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PlumoraColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAction {
  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.path,
    required this.roleName,
    this.progress,
    this.meta,
    this.metaColor = PlumoraColors.mukemeAccent,
    this.useLogoMark = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String path;
  final String roleName;
  final double? progress;
  final String? meta;
  final Color metaColor;
  final bool useLogoMark;

  static const continueWriting = _HomeAction(
    title: 'Continuer à écrire',
    subtitle: 'La Nuit Rouge - Chapitre 3',
    icon: Icons.edit_outlined,
    iconBackground: PlumoraColors.primary,
    iconColor: PlumoraColors.cards,
    path: AppRoutes.editor,
    roleName: 'AUTHOR',
    progress: 0.35,
    useLogoMark: true,
  );

  static const discoverBook = _HomeAction(
    title: 'Découvrir un livre',
    subtitle: 'Explorez des milliers de livres',
    icon: Icons.menu_book_outlined,
    iconBackground: PlumoraColors.primary,
    iconColor: PlumoraColors.cards,
    path: AppRoutes.discover,
    roleName: 'READER',
    meta: '\u{2728} Recommandé par Mukeme',
  );

  static const betaReading = _HomeAction(
    title: 'Mes bêta-lectures',
    subtitle: '2 manuscrits en attente',
    icon: Icons.science_outlined,
    iconBackground: PlumoraColors.mukemeAccent,
    iconColor: PlumoraColors.cards,
    path: AppRoutes.library,
    roleName: 'BETA_READER',
    meta: '\u{23F0} Deadline : 12 juin',
    metaColor: PlumoraColors.warning,
  );
}
