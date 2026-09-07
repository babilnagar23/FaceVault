import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

enum _ScanState { ready, scanning, stepFace, stepLiveness, stepLocation, success, failed }

class TodayAttendanceScreen extends ConsumerStatefulWidget {
  const TodayAttendanceScreen({super.key});

  @override
  ConsumerState<TodayAttendanceScreen> createState() => _TodayAttendanceScreenState();
}

class _TodayAttendanceScreenState extends ConsumerState<TodayAttendanceScreen> {
  _ScanState _state = _ScanState.ready;
  AttendanceVerificationResult? _result;

  Future<void> _startScan() async {
    setState(() => _state = _ScanState.scanning);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    setState(() => _state = _ScanState.stepFace);
    final faceResult = await ref.read(faceRecognitionServiceProvider).verifyLiveFace();

    if (!faceResult.verified) {
      setState(() => _state = _ScanState.failed);
      return;
    }

    setState(() => _state = _ScanState.stepLiveness);
    final livenessResult = await ref.read(livenessServiceProvider).checkLiveness();

    if (!livenessResult.passed) {
      setState(() => _state = _ScanState.failed);
      return;
    }

    setState(() => _state = _ScanState.stepLocation);
    final locationResult = await ref.read(locationServiceProvider).verify();

    final verifyResult = AttendanceVerificationResult(
      faceVerified: faceResult.verified,
      faceScore: faceResult.score,
      livenessVerified: livenessResult.passed,
      livenessScore: livenessResult.score,
      locationVerified: locationResult.verified,
      distanceMeters: locationResult.distanceMeters,
      gpsAccuracyMeters: locationResult.gpsAccuracyMeters,
      assignedSite: locationResult.assignedSite,
      timestamp: DateTime.now(),
      attendanceStatus: locationResult.verified
          ? AttendanceStatus.present
          : AttendanceStatus.locationError,
      syncStatus: SyncState.synced,
    );

    await ref.read(attendanceApiProvider).markAttendance();
    if (!mounted) return;

    setState(() {
      _result = verifyResult;
      _state = _ScanState.success;
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_state == _ScanState.success && _result != null) {
      return _SuccessView(result: _result!);
    }
    if (_state == _ScanState.failed) {
      return _FailedView(onRetry: () => setState(() => _state = _ScanState.ready));
    }

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
                  // Fingerprint circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: _state == _ScanState.ready
                          ? AppColors.surfaceContainerLow
                          : AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 46,
                      color: _state == _ScanState.ready
                          ? AppColors.onSurfaceVariant
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _state == _ScanState.ready ? 'Ready to Scan' : 'Scanning...',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ensure your face is well-lit and clearly visible\nbefore starting the scan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryActionButton(
                    label: _state == _ScanState.ready ? 'Start Attendance Scan' : 'Scanning...',
                    icon: Icons.play_arrow,
                    loading: _state != _ScanState.ready,
                    onPressed: _state == _ScanState.ready ? _startScan : null,
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
                    label: 'Face Detection',
                    subtitle: 'Locating features...',
                    status: switch (_state) {
                      _ScanState.ready => PipelineStepStatus.waiting,
                      _ScanState.scanning => PipelineStepStatus.active,
                      _ => PipelineStepStatus.success,
                    },
                  ),
                  PipelineStep(
                    icon: Icons.grid_on,
                    label: 'Face Alignment',
                    subtitle: 'Normalising geometry...',
                    status: switch (_state) {
                      _ScanState.scanning => PipelineStepStatus.waiting,
                      _ScanState.stepFace => PipelineStepStatus.active,
                      _ScanState.ready => PipelineStepStatus.waiting,
                      _ => PipelineStepStatus.success,
                    },
                  ),
                  PipelineStep(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Liveness Detection',
                    subtitle: 'Anti-spoofing check...',
                    status: switch (_state) {
                      _ScanState.stepLiveness => PipelineStepStatus.active,
                      _ScanState.success => PipelineStepStatus.success,
                      _ScanState.failed => PipelineStepStatus.failed,
                      _ScanState.stepLocation => PipelineStepStatus.success,
                      _ => PipelineStepStatus.waiting,
                    },
                  ),
                  PipelineStep(
                    icon: Icons.shield_outlined,
                    label: 'Matching',
                    subtitle: 'Comparing with DB...',
                    status: switch (_state) {
                      _ScanState.stepLocation => PipelineStepStatus.active,
                      _ScanState.success => PipelineStepStatus.success,
                      _ => PipelineStepStatus.waiting,
                    },
                  ),
                  PipelineStep(
                    icon: Icons.location_on_outlined,
                    label: 'GPS Validation',
                    subtitle: 'Checking geofence...',
                    status: switch (_state) {
                      _ScanState.success => PipelineStepStatus.success,
                      _ => PipelineStepStatus.waiting,
                    },
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Success view ──

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.result});

  final AttendanceVerificationResult result;

  @override
  Widget build(BuildContext context) {
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: AppColors.warning, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Offline Saved, Sync Pending',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const InfoRow(
                    icon: Icons.person_outline,
                    label: 'Employee',
                    value: 'Aarav Mehta',
                  ),
                  const Divider(height: 1),
                  const InfoRow(
                    icon: Icons.schedule,
                    label: 'Time',
                    value: '09:48 AM',
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: result.assignedSite,
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    icon: Icons.face,
                    label: 'Face Match',
                    value: '${(result.faceScore * 100).toStringAsFixed(1)}%',
                    valueColor: AppColors.success,
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    icon: Icons.gps_fixed,
                    label: 'GPS Accuracy',
                    value: '${result.gpsAccuracyMeters}m',
                    valueColor: AppColors.success,
                  ),
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
  const _FailedView({required this.onRetry});

  final VoidCallback onRetry;

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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onSurface),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Biometric verification could not be completed. Please ensure you are in good lighting and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryActionButton(label: 'Try Again', icon: Icons.refresh, onPressed: onRetry),
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
