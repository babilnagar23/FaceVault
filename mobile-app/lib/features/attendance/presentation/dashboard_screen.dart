import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(currentEmployeeProvider);
    final syncAsync = ref.watch(syncStatusProvider);
    final unreadAsync = ref.watch(unreadNotificationCountProvider);

    final unreadCount = unreadAsync.valueOrNull ?? 0;
    final syncStatus = syncAsync.valueOrNull ?? SyncState.synced;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _DashboardAppBar(unreadCount: unreadCount),
            // Offline / sync banner
            SyncBanner(
              status: _syncBannerStatus(syncStatus),
              pendingCount: 4,
              onSyncNow: () {
                ref.read(syncApiProvider).flush();
              },
            ),
            Expanded(
              child: employeeAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: LoadingSkeleton(lines: 6),
                ),
                error: (e, _) => ErrorStateView(
                  message: 'Failed to load your profile. Please try again.',
                  onRetry: () => ref.invalidate(currentEmployeeProvider),
                ),
                data: (employee) => _DashboardBody(employee: employee),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SyncBannerStatus _syncBannerStatus(SyncState state) {
    return switch (state) {
      SyncState.offline => SyncBannerStatus.offline,
      SyncState.syncing => SyncBannerStatus.syncing,
      SyncState.pending => SyncBannerStatus.pending,
      SyncState.failed => SyncBannerStatus.failed,
      SyncState.synced => SyncBannerStatus.synced,
    };
  }
}

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle, width: 2),
            ),
            child: const Center(
              child: Text(
                'AM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Title
          const Text(
            'FaceVault',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          // Settings
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                color: AppColors.onSurface,
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(attendanceHistoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        // ── Identity ──
        _IdentityRow(employee: employee),
        const SizedBox(height: AppSpacing.md),

        // ── Metric grid ──
        _MetricGrid(employee: employee),
        const SizedBox(height: AppSpacing.md),

        // ── Assigned site ──
        _AssignedSiteCard(employee: employee),
        const SizedBox(height: AppSpacing.md),

        // ── Today's log ──
        historyAsync.when(
          loading: () => const LoadingSkeleton(lines: 2, height: 64),
          error: (_, __) => const SizedBox.shrink(),
          data: (records) => _TodayLogCard(latestRecord: records.isNotEmpty ? records.first : null),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Quick actions ──
        const _QuickActionsSection(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.id,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                employee.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        // On-site badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.successSurface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              StatusDot(label: '', color: AppColors.success),
              SizedBox(width: 2),
              Text(
                'On\nSite',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends ConsumerWidget {
  const _MetricGrid({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncAsync = ref.watch(syncStatusProvider);
    final pendingCount = syncAsync.valueOrNull == SyncState.pending ? 4 : 0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        // Today's hours
        _GridCard(
          icon: Icons.schedule_outlined,
          title: "Today's Hours",
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('06', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              Text('h ', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
              Text('32', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              Text('m', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        // Weekly target
        _GridCard(
          icon: Icons.calendar_today_outlined,
          title: 'Weekly Target',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '78%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: const LinearProgressIndicator(
                  value: 0.78,
                  minHeight: 4,
                  backgroundColor: Color(0xFFE3EAF4),
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        // Pending syncs
        if (pendingCount > 0)
          _GridCard(
            icon: Icons.sync,
            title: 'Pending Syncs',
            iconColor: AppColors.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pendingCount',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
                const Text(
                  'Awaiting connectivity',
                  style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          _GridCard(
            icon: Icons.check_circle_outline,
            title: 'Sync Status',
            iconColor: AppColors.success,
            child: const Text(
              'All synced',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
        // Punch In/Out
        GestureDetector(
          onTap: () => context.push('/attendance/today'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fingerprint, color: Colors.white, size: 36),
                SizedBox(height: 8),
                Text(
                  'Punch Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({
    required this.icon,
    required this.title,
    required this.child,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor ?? AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          child,
        ],
      ),
    );
  }
}

class _AssignedSiteCard extends StatelessWidget {
  const _AssignedSiteCard({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          MapPlaceholder(siteName: employee.location, height: 120),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      employee.project,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _SiteMeta(label: 'Site Code', value: employee.siteCode ?? 'N/A'),
                    ),
                    Expanded(
                      child: _SiteMeta(label: 'Zone', value: employee.zone ?? 'N/A'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _SiteMeta(label: 'Manager', value: employee.managerName ?? 'N/A'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        context.push('/attendance/today');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SiteMeta extends StatelessWidget {
  const _SiteMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
      ],
    );
  }
}

class _TodayLogCard extends StatelessWidget {
  const _TodayLogCard({required this.latestRecord});

  final AttendanceRecord? latestRecord;

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Log",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                Text(
                  'Last updated 5m ago',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(height: 16, indent: 16, endIndent: 16),
          // Check in
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.successSurface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.login, color: AppColors.success, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Check In',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        'Biometric • Verified',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  latestRecord?.checkInTime ?? '09:02 AM',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Check out
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: AppColors.onSurfaceVariant,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Check Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Pending',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const Text(
                  '--:--',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
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

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.8,
          children: [
            QuickActionCard(
              label: 'History',
              icon: Icons.history,
              onTap: () => context.push('/attendance/history'),
            ),
            QuickActionCard(
              label: 'Leave Req',
              icon: Icons.calendar_today_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Leave requests — coming soon.')),
                );
              },
            ),
            QuickActionCard(
              label: 'Support',
              icon: Icons.headset_mic_outlined,
              onTap: () => context.push('/help'),
            ),
            QuickActionCard(
              label: 'Community',
              icon: Icons.campaign_outlined,
              onTap: () => context.push('/community'),
            ),
          ],
        ),
      ],
    );
  }
}
