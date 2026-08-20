import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

class HelpDetailScreen extends ConsumerWidget {
  const HelpDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/help'),
        ),
        title: Text(ticketId),
      ),
      body: SafeArea(
        child: FutureBuilder<HelpTicket>(
          future: ref.read(helpApiProvider).detail(ticketId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: LoadingSkeleton(lines: 4),
              );
            }
            return _TicketBody(ticket: snapshot.data!);
          },
        ),
      ),
    );
  }
}

class _TicketBody extends StatelessWidget {
  const _TicketBody({required this.ticket});

  final HelpTicket ticket;

  static Color _statusColor(String status) => switch (status) {
        'Urgent' => AppColors.error,
        'In Progress' => AppColors.secondary,
        'Open' => AppColors.warning,
        'Resolved' => AppColors.success,
        _ => AppColors.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(ticket.status);
    final createdStr = DateFormat('d MMM yyyy, HH:mm').format(ticket.createdAt);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Status card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: statusColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.id, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                    Text(
                      ticket.issueType,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Submitted $createdStr',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              StatusChip(label: ticket.status, color: statusColor),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Description
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description',
                    style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  ticket.description,
                  style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.onSurface),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Status timeline
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Timeline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.md),
                _TimelineItem(
                  icon: Icons.add_circle_outline,
                  label: 'Ticket created',
                  time: createdStr,
                  color: AppColors.primary,
                  isFirst: true,
                ),
                if (ticket.status == 'In Progress' || ticket.status == 'Resolved' || ticket.status == 'Urgent')
                  _TimelineItem(
                    icon: Icons.pending_outlined,
                    label: 'Under review by support team',
                    time: 'Approx. 30 minutes later',
                    color: AppColors.secondary,
                    isFirst: false,
                  ),
                if (ticket.status == 'Resolved')
                  _TimelineItem(
                    icon: Icons.check_circle,
                    label: 'Resolved by support team',
                    time: 'Within 24 hours',
                    color: AppColors.success,
                    isFirst: false,
                    isLast: true,
                  )
                else
                  _TimelineItem(
                    icon: Icons.hourglass_top_outlined,
                    label: 'Awaiting response',
                    time: 'Expected within 24 hours',
                    color: AppColors.onSurfaceVariant,
                    isFirst: false,
                    isLast: true,
                    pending: true,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Actions
        if (ticket.status != 'Resolved')
          OutlinedButton.icon(
            onPressed: () => context.go('/help'),
            icon: const Icon(Icons.add),
            label: const Text('Submit Another Ticket'),
          ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    required this.isFirst,
    this.isLast = false,
    this.pending = false,
  });

  final IconData icon;
  final String label;
  final String time;
  final Color color;
  final bool isFirst;
  final bool isLast;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              if (!isLast)
                Container(
                  width: 2,
                  height: 32,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: AppColors.borderSubtle,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: pending ? AppColors.onSurfaceVariant : AppColors.onSurface,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
