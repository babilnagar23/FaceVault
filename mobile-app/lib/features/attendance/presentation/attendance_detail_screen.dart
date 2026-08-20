import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

class AttendanceDetailScreen extends ConsumerWidget {
  const AttendanceDetailScreen({super.key, required this.attendanceId});

  final String attendanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(attendanceId),
      ),
      body: SafeArea(
        child: FutureBuilder<AttendanceRecord>(
          future: ref.read(attendanceApiProvider).detail(attendanceId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: LoadingSkeleton(lines: 5),
              );
            }
            return _DetailBody(record: snapshot.data!);
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(record.date);
    final statusColor = _color(record.status);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Status header
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: statusColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: statusColor, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    Text(
                      record.assignedSite,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              StatusChip(label: _statusLabel(record.status), color: statusColor),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Details card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attendance Details',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const Divider(height: AppSpacing.lg),
                InfoRow(icon: Icons.login, label: 'Check-In', value: record.checkInTime),
                const Divider(height: 1),
                InfoRow(
                  icon: Icons.logout,
                  label: 'Check-Out',
                  value: record.checkOutTime ?? '-- Pending',
                ),
                const Divider(height: 1),
                InfoRow(icon: Icons.location_on_outlined, label: 'Assigned Site', value: record.assignedSite),
                const Divider(height: 1),
                InfoRow(
                  icon: Icons.near_me_outlined,
                  label: 'Distance from Site',
                  value: '${record.distanceMeters}m',
                  valueColor: record.distanceMeters < 200 ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Biometric card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Biometric Verification',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const Divider(height: AppSpacing.lg),
                InfoRow(
                  icon: Icons.face,
                  label: 'Face Recognition',
                  value: record.faceStatus,
                  valueColor: record.faceStatus == 'Verified' ? AppColors.success : AppColors.error,
                ),
                const Divider(height: 1),
                if (record.faceScore != null)
                  InfoRow(
                    icon: Icons.bar_chart,
                    label: 'Face Match Score',
                    value: '${(record.faceScore! * 100).toStringAsFixed(1)}%',
                    valueColor: AppColors.success,
                  ),
                const Divider(height: 1),
                InfoRow(
                  icon: Icons.remove_red_eye_outlined,
                  label: 'Liveness Check',
                  value: record.livenessStatus,
                  valueColor:
                      record.livenessStatus == 'Verified' ? AppColors.success : AppColors.error,
                ),
                const Divider(height: 1),
                InfoRow(
                  icon: Icons.gps_fixed,
                  label: 'Location Status',
                  value: record.locationStatus,
                  valueColor:
                      record.locationStatus == 'Verified' ? AppColors.success : AppColors.error,
                ),
                if (record.gpsAccuracy != null) ...[
                  const Divider(height: 1),
                  InfoRow(
                    icon: Icons.my_location,
                    label: 'GPS Accuracy',
                    value: '${record.gpsAccuracy}m',
                    valueColor: AppColors.success,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Sync card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sync Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const Divider(height: AppSpacing.lg),
                InfoRow(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Sync',
                  value: _syncLabel(record.syncStatus),
                  valueColor: record.syncStatus == SyncState.synced ? AppColors.success : AppColors.warning,
                ),
                const Divider(height: 1),
                InfoRow(icon: Icons.comment_outlined, label: 'Remarks', value: record.remarks),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _color(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => AppColors.success,
        AttendanceStatus.late => AppColors.warning,
        AttendanceStatus.locationError || AttendanceStatus.faceFailed => AppColors.error,
        _ => AppColors.onSurfaceVariant,
      };

  String _statusLabel(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.late => 'Late',
        AttendanceStatus.locationError => 'Location Error',
        AttendanceStatus.faceFailed => 'Face Failed',
        _ => 'Unknown',
      };

  String _syncLabel(SyncState s) => switch (s) {
        SyncState.synced => 'Synced',
        SyncState.pending => 'Pending Sync',
        SyncState.syncing => 'Syncing...',
        SyncState.failed => 'Sync Failed',
        SyncState.offline => 'Offline',
      };
}
