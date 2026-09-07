import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String _selectedCategory = 'All';
  static const _categories = ['All', 'Pinned', 'Urgent', 'Safety', 'Policy', 'Project', 'Emergency'];

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/alerts')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category filter tabs
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final active = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: active ? AppColors.primary : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: announcementsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: LoadingSkeleton(lines: 4),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ErrorStateView(
                    message: 'Failed to load announcements.',
                    onRetry: () => ref.invalidate(announcementsProvider),
                  ),
                ),
                data: (items) {
                  final filtered = _filter(items);
                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: EmptyStateView(
                        title: 'No Announcements',
                        message: 'No announcements in this category.',
                        icon: Icons.campaign_outlined,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => _AnnouncementCard(
                      announcement: filtered[i],
                      onTap: () => context.push('/community/${filtered[i].id}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Announcement> _filter(List<Announcement> items) {
    return switch (_selectedCategory) {
      'All' => items,
      'Pinned' => items.where((a) => a.pinned).toList(),
      'Urgent' => items.where((a) => a.urgent).toList(),
      _ => items.where((a) => a.category == _selectedCategory).toList(),
    };
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, required this.onTap});

  final Announcement announcement;
  final VoidCallback onTap;

  static Color _categoryColor(String cat) => switch (cat) {
        'Safety' => AppColors.warning,
        'Emergency' => AppColors.error,
        'Policy' => AppColors.secondary,
        'Project' => AppColors.primary,
        _ => AppColors.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(announcement.category);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: announcement.urgent
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.borderSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(label: announcement.category, color: catColor),
                if (announcement.pinned) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.push_pin, color: AppColors.primary, size: 14),
                ],
                if (announcement.urgent) ...[
                  const SizedBox(width: 6),
                  const StatusChip(label: 'URGENT', color: AppColors.error),
                ],
                const Spacer(),
                if (!announcement.read)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              announcement.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: announcement.read ? FontWeight.w500 : FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              announcement.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  announcement.publisher ?? 'Administration',
                  style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  DateFormat('d MMM, HH:mm').format(announcement.publishedAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail screen ──

class CommunityDetailScreen extends ConsumerWidget {
  const CommunityDetailScreen({super.key, required this.announcementId});

  final String announcementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Announcement'),
      ),
      body: SafeArea(
        child: FutureBuilder<Announcement>(
          future: ref.read(announcementApiProvider).detail(announcementId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: LoadingSkeleton(lines: 5),
              );
            }
            final a = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusChip(label: a.category, color: AppColors.primary),
                            if (a.urgent) ...[
                              const SizedBox(width: 8),
                              const StatusChip(label: 'URGENT', color: AppColors.error),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(a.title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          '${a.publisher ?? 'Administration'} • ${DateFormat('EEEE, d MMM yyyy, HH:mm').format(a.publishedAt)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Body
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      a.body,
                      style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.onSurface),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Acknowledge
                if (!a.acknowledged)
                  PrimaryActionButton(
                    label: 'Acknowledge',
                    icon: Icons.check,
                    onPressed: () async {
                      await ref.read(announcementApiProvider).acknowledge(announcementId);
                      ref.invalidate(announcementsProvider);
                      if (context.mounted) context.pop();
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Acknowledged',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
