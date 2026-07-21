import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
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
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        returnToPreviousOr(context, AppRoutes.home),
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
                              style: GoogleFonts.playfairDisplay(
                                color: context.colors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            unreadCountAsync.maybeWhen(
                              data: (count) => Text(
                                count == 0
                                    ? 'Tout est lu'
                                    : '$count notification${count > 1 ? 's' : ''} non lue${count > 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              orElse: () => Text(
                                'Activité Plumora récente',
                                style: TextStyle(
                                  color: context.colors.textSecondary,
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
                    error: (error, _) => FigmaEmptyState(
                      icon: Icons.error_outline,
                      title: 'Notifications indisponibles',
                      message: AppError.messageFor(error),
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
                        return const FigmaEmptyState(
                          icon: Icons.notifications_none_outlined,
                          title: 'Aucune notification',
                          message:
                              'Les invitations, retours bêta et publications apparaîtront ici.',
                        );
                      }

                      return FigmaResponsiveGrid(
                        minTileWidth: 480,
                        maxColumns: 2,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final notification in notifications)
                            _NotificationCard(
                              notification: notification,
                              busy: _busyNotificationId == notification.id,
                              onRead: notification.isRead
                                  ? null
                                  : () => _markAsRead(notification.id),
                            ),
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
    final color = _typeColor(context, notification.type);
    return PlumoraCard(
      leftAccent: notification.isRead ? context.colors.border : color,
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
                      PlumoraBadge(
                        label: 'Nouveau',
                        backgroundColor: context.colors.success.withValues(
                          alpha: 0.12,
                        ),
                        foregroundColor: context.colors.success,
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  notification.message.isEmpty
                      ? 'Nouvelle activité sur Plumora.'
                      : notification.message,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  _dateLabel(notification.createdAt),
                  style: TextStyle(
                    color: context.colors.textSecondary,
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

Color _typeColor(BuildContext context, String type) {
  final normalized = type.trim().toUpperCase();
  if (normalized.contains('BETA')) {
    return context.colors.info;
  }
  if (normalized.contains('BOOK') || normalized.contains('PUBLICATION')) {
    return context.colors.primary;
  }
  if (normalized.contains('REVIEW')) {
    return context.colors.plumoAccent;
  }
  if (normalized.contains('FAVORITE')) {
    return context.colors.destructive;
  }

  return context.colors.textSecondary;
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
