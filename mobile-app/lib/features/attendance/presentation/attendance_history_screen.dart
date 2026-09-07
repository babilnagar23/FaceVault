import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(attendanceHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt_outlined), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: LoadingSkeleton(lines: 5),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ErrorStateView(
              message: 'Could not load attendance history.',
              onRetry: () => ref.invalidate(attendanceHistoryProvider),
            ),
          ),
          data: (records) => records.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: EmptyStateView(
                    title: 'No Records',
                    message: 'Your attendance history will appear here.',
                    icon: Icons.calendar_today_outlined,
                  ),
                )
              : _RecordList(records: records),
        ),
      ),
    );
  }
}

class _RecordList extends StatefulWidget {
  const _RecordList({required this.records});

  final List<AttendanceRecord> records;

  @override
  State<_RecordList> createState() => _RecordListState();
}

class _RecordListState extends State<_RecordList> {
  final _filters = <String>{'All'};
  static const _all = ['All', 'Present', 'Late', 'Location Error', 'Face Failed', 'Absent'];

  List<AttendanceRecord> get filtered {
    if (_filters.contains('All')) return widget.records;
    return widget.records.where((r) {
      return switch (r.status) {
        AttendanceStatus.present => _filters.contains('Present'),
        AttendanceStatus.late => _filters.contains('Late'),
        AttendanceStatus.locationError => _filters.contains('Location Error'),
        AttendanceStatus.faceFailed => _filters.contains('Face Failed'),
        AttendanceStatus.absent => _filters.contains('Absent'),
        _ => false,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _all.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final label = _all[i];
                final selected = _filters.contains(label);
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (label == 'All') {
                        _filters
                          ..clear()
                          ..add('All');
                      } else {
                        _filters.remove('All');
                        if (v) {
                          _filters.add(label);
                        } else {
                          _filters.remove(label);
                          if (_filters.isEmpty) _filters.add('All');
                        }
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.12),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _RecordCard(
              record: filtered[i],
              onTap: () => context.push('/attendance/history/${filtered[i].id}'),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.onTap});

  final AttendanceRecord record;
  final VoidCallback onTap;

  static Color _statusColor(AttendanceStatus status) => switch (status) {
        AttendanceStatus.present => AppColors.success,
        AttendanceStatus.late => AppColors.warning,
        AttendanceStatus.locationError ||
        AttendanceStatus.faceFailed ||
        AttendanceStatus.livenessFailed =>
          AppColors.error,
        AttendanceStatus.absent => AppColors.error,
        AttendanceStatus.pendingReview || AttendanceStatus.pendingSync => AppColors.warning,
        _ => AppColors.onSurfaceVariant,
      };

  static String _statusLabel(AttendanceStatus status) => switch (status) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.late => 'Late',
        AttendanceStatus.locationError => 'Location Error',
        AttendanceStatus.faceFailed => 'Face Failed',
        AttendanceStatus.livenessFailed => 'Liveness Failed',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.pendingReview => 'Pending Review',
        AttendanceStatus.pendingSync => 'Pending Sync',
        _ => 'Unknown',
      };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(record.status);
    final date = DateFormat('EEE, d MMM').format(record.date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(
                    record.assignedSite,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${record.checkInTime} → ${record.checkOutTime ?? '--:--'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            StatusChip(label: _statusLabel(record.status), color: color),
          ],
        ),
      ),
    );
  }
}
