import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/real/attendance_pipeline_coordinator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

enum _ScanState { ready, stepFace, stepLiveness, stepLocation, stepSync, success, failed }

class TodayAttendanceScreen extends ConsumerStatefulWidget {
  const TodayAttendanceScreen({super.key});

  @override
  ConsumerState<TodayAttendanceScreen> createState() => _TodayAttendanceScreenState();
}

class _TodayAttendanceScreenState extends ConsumerState<TodayAttendanceScreen> {
  _ScanState _state = _ScanState.ready;
  AttendanceVerificationResult? _result;
  String? _errorMessage;

  Future<void> _startScan() async {
    setState(() {
      _state = _ScanState.stepFace;
      _errorMessage = null;
    });

    try {
      // The coordinator sequences face → liveness → location → sync
      // with real service results — no hardcoded scores.
      final coordinator = ref.read(attendancePipelineProvider);

      final result = await coordinator.run(
        onStep: (step) {
          if (!mounted) return;
          setState(() {
            _state = switch (step) {
              AttendancePipelineStep.face => _ScanState.stepFace,
              AttendancePipelineStep.liveness => _ScanState.stepLiveness,
              AttendancePipelineStep.location => _ScanState.stepLocation,
              AttendancePipelineStep.sync => _ScanState.stepSync,
            };
          });
        },
      );

      if (!mounted) return;

      // Consider verification successful if face + liveness passed,
      // even if location check failed (location error shown in result).
      final overallSuccess = result.faceVerified && result.livenessVerified;

      setState(() {
        _result = result;
        _state = overallSuccess ? _ScanState.success : _ScanState.failed;
        if (!overallSuccess) {
          _errorMessage = result.failureReason;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScanState.failed;
        _errorMessage = 'An unexpected error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _ScanState.success && _result != null) {
      return _SuccessView(result: _result!);
    }
    if (_state == _ScanState.failed) {
      return _FailedView(
        reason: _errorMessage,
        onRetry: () => setState(() {
          _state = _ScanState.ready;
          _errorMessage = null;
        }),
      );
    }

    final isScanning = _state != _ScanState.ready;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'FaceVault',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'AM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SizedBox(height: AppSpacing.sm),
            const Text(
              "Today's Attendance",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Secure biometric verification required for clock-in.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Scanner card ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: isScanning
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 46,
                      color: isScanning
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _stepLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stepSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryActionButton(
                    label: isScanning ? 'Verifying...' : 'Start Attendance Scan',
                    icon: Icons.play_arrow,
                    loading: isScanning,
                    onPressed: isScanning ? null : _startScan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Pipeline card ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verification Pipeline',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Divider(height: AppSpacing.lg),
                  PipelineStep(
                    icon: Icons.photo_camera_outlined,
                    label: 'Camera Preview',
                    subtitle: 'Waiting for feed...',
                    status: _state.index > _ScanState.ready.index
                        ? PipelineStepStatus.success
                        : PipelineStepStatus.waiting,
                  ),
                  PipelineStep(
                    icon: Icons.face,
                    label: 'Face Detection & Quality',
                    subtitle: 'Locating and checking face...',
                    status: switch (_state) {
                      _ScanState.ready => PipelineStepStatus.waiting,
                      _ScanState.stepFace => PipelineStepStatus.active,
                      _ => PipelineStepStatus.success,
                    },
                  ),
                  PipelineStep(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Liveness Detection',
                    subtitle: 'Anti-spoofing check (on-device)...',
                    status: switch (_state) {
                      _ScanState.stepLiveness => PipelineStepStatus.active,
                      _ScanState.stepLocation ||
                      _ScanState.stepSync ||
                      _ScanState.success => PipelineStepStatus.success,
                      _ScanState.failed => PipelineStepStatus.failed,
                      _ => PipelineStepStatus.waiting,
                    },
                  ),
                  PipelineStep(
                    icon: Icons.shield_outlined,
                    label: 'Face Matching',
                    subtitle: 'Comparing with enrolled template...',
                    status: switch (_state) {
                      _ScanState.stepLocation ||
                      _ScanState.stepSync ||
                      _ScanState.success => PipelineStepStatus.success,
                      _ScanState.stepFace => PipelineStepStatus.active,
                      _ => PipelineStepStatus.waiting,
                    },
                  ),
                  PipelineStep(
                    icon: Icons.location_on_outlined,
                    label: 'GPS Validation',
                    subtitle: 'Checking geofence (offline)...',
                    status: switch (_state) {
                      _ScanState.stepLocation => PipelineStepStatus.active,
                      _ScanState.stepSync ||
                      _ScanState.success => PipelineStepStatus.success,
                      _ => PipelineStepStatus.waiting,
                    },
                  ),
                  PipelineStep(
                    icon: Icons.cloud_upload_outlined,
                    label: 'Sync / Queue',
                    subtitle: 'Submit or store offline...',
                    status: switch (_state) {
                      _ScanState.stepSync => PipelineStepStatus.active,
                      _ScanState.success => PipelineStepStatus.success,
                      _ => PipelineStepStatus.waiting,
                    },
                    isLast: true,
                  ),
                ],
              ),
            ),

            // ── Offline badge ──
            const SizedBox(height: AppSpacing.sm),
            _OfflineBadge(),
          ],
        ),
      ),
    );
  }

  String get _stepLabel => switch (_state) {
        _ScanState.ready => 'Ready to Scan',
        _ScanState.stepFace => 'Detecting Face...',
        _ScanState.stepLiveness => 'Liveness Check...',
        _ScanState.stepLocation => 'GPS Verification...',
        _ScanState.stepSync => 'Saving Result...',
        _ => 'Processing...',
      };

  String get _stepSubtitle => switch (_state) {
        _ScanState.ready =>
          'Ensure your face is well-lit and clearly visible\nbefore starting the scan.',
        _ScanState.stepFace =>
          'Face detection and quality checks in progress.\nLook directly at the camera.',
        _ScanState.stepLiveness =>
          'Anti-spoofing model running on-device.\nPlease remain still.',
        _ScanState.stepLocation =>
          'Reading GPS and computing geofence.\nThis works offline.',
        _ScanState.stepSync =>
          'Submitting attendance event or\nqueueing for later sync.',
        _ => '',
      };
}

// ── Offline indicator ──

class _OfflineBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(offlinePendingCountProvider);
    return pendingAsync.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warningSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: AppColors.warning, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$count attendance event${count > 1 ? 's' : ''} pending sync.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Success view ──

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.result});

  final AttendanceVerificationResult result;

  @override
  Widget build(BuildContext context) {
    final syncLabel = result.syncStatus == SyncState.synced
        ? 'Synced to Server'
        : 'Offline Saved, Sync Pending';
    final syncIcon = result.syncStatus == SyncState.synced
        ? Icons.cloud_done_outlined
        : Icons.cloud_upload_outlined;
    final syncColor = result.syncStatus == SyncState.synced
        ? AppColors.success
        : AppColors.warning;
    final syncBg = result.syncStatus == SyncState.synced
        ? AppColors.successSurface
        : AppColors.warningSurface;

    final livenessLabel = switch (result.livenessStatus) {
      LivenessStatus.passed => 'Passed',
      LivenessStatus.failed => 'Failed',
      LivenessStatus.timeout => 'Timed out',
      LivenessStatus.unsupported => 'Unsupported',
      LivenessStatus.error => 'Error',
      LivenessStatus.checking => 'Checking',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('FaceVault'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Attendance Marked',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: syncBg,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(syncIcon, color: syncColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          syncLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: syncColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: result.assignedSite.isEmpty
                        ? 'Not verified'
                        : result.assignedSite,
                    valueColor: result.locationVerified
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    icon: Icons.face,
                    label: 'Face Match',
                    value: '${(result.faceScore * 100).toStringAsFixed(1)}%',
                    valueColor: result.faceVerified
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Liveness',
                    value: livenessLabel,
                    valueColor: result.livenessVerified
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    icon: Icons.gps_fixed,
                    label: 'GPS Accuracy',
                    value: '${result.gpsAccuracyMeters}m',
                    valueColor: AppColors.success,
                  ),
                  if (!result.locationVerified &&
                      result.failureReason != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.warningSurface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        result.failureReason!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryActionButton(
                    label: 'Done',
                    icon: Icons.check,
                    onPressed: () => context.go('/dashboard'),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Failed view ──

class _FailedView extends StatelessWidget {
  const _FailedView({required this.onRetry, this.reason});

  final VoidCallback onRetry;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('FaceVault'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 40),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Verification Failed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                reason ??
                    'Biometric verification could not be completed. '
                    'Please ensure you are in good lighting and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryActionButton(
                label: 'Try Again',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.push('/help'),
                icon: const Icon(Icons.headset_mic_outlined),
                label: const Text('Get Help'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
