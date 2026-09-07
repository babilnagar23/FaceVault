import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help Center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<String>>(
          future: ref.read(helpApiProvider).issueTypes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: LoadingSkeleton(lines: 4),
              );
            }
            final types = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const Text(
                  'Report an Issue',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select the type of issue you are experiencing. Our team will respond within 24 hours.',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: AppSpacing.lg),
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.0,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: types.map((type) => _IssueCard(issueType: type)).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                const SectionHeader(title: 'My Tickets'),
                const SizedBox(height: AppSpacing.sm),
                const _TicketList(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issueType});

  final String issueType;

  static IconData _icon(String type) => switch (type) {
        'Location Error' => Icons.location_off_outlined,
        'Face Recognition Failed' => Icons.no_accounts_outlined,
        'GPS Problem' => Icons.gps_off,
        'Camera Problem' => Icons.no_photography_outlined,
        'App Error' => Icons.error_outline,
        'Internet / Sync Issue' => Icons.wifi_off_outlined,
        'Wrong Assigned Location' => Icons.wrong_location_outlined,
        'Permission Problem' => Icons.lock_outlined,
        'Attendance Missing' => Icons.event_busy_outlined,
        'Shift Timing Issue' => Icons.schedule_outlined,
        'Device Changed' => Icons.smartphone,
        _ => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/help/create', extra: issueType),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon(issueType), color: AppColors.primary, size: 26),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                issueType,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketList extends ConsumerWidget {
  const _TicketList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(myHelpTicketsProvider);

    return ticketsAsync.when(
      loading: () => const LoadingSkeleton(lines: 2, height: 60),
      error: (_, __) => const SizedBox.shrink(),
      data: (tickets) => tickets.isEmpty
          ? const EmptyStateView(
              title: 'No open tickets',
              message: 'Your help requests will appear here.',
              icon: Icons.headset_mic_outlined,
            )
          : Column(
              children: tickets.map((t) => _TicketTile(ticket: t)).toList(),
            ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});

  final HelpTicket ticket;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (ticket.status) {
      'Urgent' => AppColors.error,
      'In Progress' => AppColors.secondary,
      'Resolved' => AppColors.success,
      _ => AppColors.onSurfaceVariant,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.id.toString(),
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                Text(ticket.issueType.toString(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          StatusChip(label: ticket.status.toString(), color: statusColor),
        ],
      ),
    );
  }
}
