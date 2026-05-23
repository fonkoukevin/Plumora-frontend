import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isMarkingAll = false;
  String? _busyNotificationId;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(myNotificationsProvider);
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 760 ? 32.0 : 16.0;
        final bottomPadding = constraints.maxWidth >= 900 ? 32.0 : 92.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            28,
            horizontal,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Retour'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: PlumoraColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            unreadCountAsync.maybeWhen(
                              data: (count) => Text(
                                count == 0
                                    ? 'Tout est lu'
                                    : '$count notification${count > 1 ? 's' : ''} non lue${count > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: PlumoraColors.textSecondary,
                                ),
                              ),
                              orElse: () => const Text(
                                'Activité Plumora récente',
                                style: TextStyle(
                                  color: PlumoraColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _isMarkingAll ? null : _markAllAsRead,
                        icon: _isMarkingAll
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.done_all, size: 18),
                        label: const Text('Tout lire'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  notificationsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => _StateCard(
                      title: 'Notifications indisponibles',
                      subtitle: AppError.messageFor(error),
                      action: FilledButton(
                        onPressed: () {
                          ref.invalidate(myNotificationsProvider);
                          ref.invalidate(unreadNotificationsCountProvider);
                        },
                        child: const Text('Réessayer'),
                      ),
                    ),
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return const _StateCard(
                          title: 'Aucune notification',
                          subtitle:
                              'Les invitations, retours bêta et publications apparaîtront ici.',
                        );
                      }

                      return Column(
                        children: [
                          for (final notification in notifications) ...[
                            _NotificationCard(
                              notification: notification,
                              busy: _busyNotificationId == notification.id,
                              onRead: notification.isRead
                                  ? null
                                  : () => _markAsRead(notification.id),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    setState(() => _busyNotificationId = notificationId);
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(notificationId);
      ref.invalidate(myNotificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _busyNotificationId = null);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isMarkingAll = true);
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
      ref.invalidate(myNotificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.busy,
    required this.onRead,
  });

  final NotificationModel notification;
  final bool busy;
  final VoidCallback? onRead;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(notification.type);
    return PlumoraCard(
      leftAccent: notification.isRead ? PlumoraColors.border : color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlumoraIconTile(
            size: 46,
            radius: 12,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(_typeIcon(notification.type), color: color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      notification.title.isEmpty
                          ? 'Notification Plumora'
                          : notification.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!notification.isRead)
                      const PlumoraBadge(
                        label: 'Nouveau',
                        backgroundColor: Color(0xFFE6EFE4),
                        foregroundColor: PlumoraColors.success,
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  notification.message.isEmpty
                      ? 'Nouvelle activité sur Plumora.'
                      : notification.message,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  _dateLabel(notification.createdAt),
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRead != null) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: busy ? null : onRead,
              child: Text(busy ? '...' : 'Lire'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: PlumoraColors.textSecondary),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

IconData _typeIcon(String type) {
  final normalized = type.trim().toUpperCase();
  if (normalized.contains('BETA')) {
    return Icons.forum_outlined;
  }
  if (normalized.contains('BOOK') || normalized.contains('PUBLICATION')) {
    return Icons.menu_book_outlined;
  }
  if (normalized.contains('REVIEW')) {
    return Icons.rate_review_outlined;
  }
  if (normalized.contains('FAVORITE')) {
    return Icons.favorite_border;
  }

  return Icons.notifications_none_outlined;
}

Color _typeColor(String type) {
  final normalized = type.trim().toUpperCase();
  if (normalized.contains('BETA')) {
    return PlumoraColors.info;
  }
  if (normalized.contains('BOOK') || normalized.contains('PUBLICATION')) {
    return PlumoraColors.primary;
  }
  if (normalized.contains('REVIEW')) {
    return PlumoraColors.mukemeAccent;
  }
  if (normalized.contains('FAVORITE')) {
    return PlumoraColors.destructive;
  }

  return PlumoraColors.textSecondary;
}

String _dateLabel(DateTime? date) {
  if (date == null) {
    return 'Maintenant';
  }

  final local = date.toLocal();
  final difference = DateTime.now().difference(local);
  if (difference.inMinutes < 1) {
    return 'À l’instant';
  }
  if (difference.inHours < 1) {
    return 'Il y a ${difference.inMinutes} min';
  }
  if (difference.inHours < 24) {
    return 'Il y a ${difference.inHours}h';
  }
  if (difference.inDays == 1) {
    return 'Hier';
  }

  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
