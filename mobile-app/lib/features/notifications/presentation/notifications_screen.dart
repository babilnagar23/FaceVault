import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alerts'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationApiProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: SafeArea(
        child: notifAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: LoadingSkeleton(lines: 4),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ErrorStateView(
              message: 'Failed to load notifications.',
              onRetry: () => ref.invalidate(notificationsProvider),
            ),
          ),
          data: (items) => items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: EmptyStateView(
                    title: 'All Clear',
                    message: 'No notifications at this time.',
                    icon: Icons.notifications_none,
                  ),
                )
              : _NotificationList(items: items, ref: ref),
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.items, required this.ref});

  final List<AppNotification> items;
  final WidgetRef ref;

  static IconData _typeIcon(String type) => switch (type) {
        'attendance' => Icons.fingerprint,
        'announcement' => Icons.campaign_outlined,
        'help' => Icons.headset_mic_outlined,
        'verification' => Icons.security_outlined,
        'system' => Icons.settings_outlined,
        _ => Icons.notifications_outlined,
      };

  static Color _typeColor(String type) => switch (type) {
        'attendance' => AppColors.primary,
        'announcement' => AppColors.secondary,
        'help' => AppColors.warning,
        'verification' => AppColors.error,
        'system' => AppColors.onSurfaceVariant,
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final n = items[i];
        final color = _typeColor(n.type);

        return InkWell(
          onTap: () async {
            await ref.read(notificationApiProvider).markRead(n.id);
            ref.invalidate(notificationsProvider);
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: n.read ? AppColors.surface : AppColors.primary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: n.read ? AppColors.borderSubtle : AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(_typeIcon(n.type), color: color, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        n.body,
                        style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('HH:mm • d MMM').format(n.timestamp),
                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (!n.read)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
