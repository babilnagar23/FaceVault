import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/face_enrollment_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class FaceEnrollmentScreen extends ConsumerStatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  ConsumerState<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends ConsumerState<FaceEnrollmentScreen>
    with SingleTickerProviderStateMixin {
  static const _poses = [
    EnrollmentPose.straight,
    EnrollmentPose.slightRight,
    EnrollmentPose.slightLeft,
    EnrollmentPose.chinUp,
    EnrollmentPose.chinDown,
  ];

  static const _poseLabels = {
    EnrollmentPose.straight: 'Look Straight',
    EnrollmentPose.slightRight: 'Slowly Turn Right',
    EnrollmentPose.slightLeft: 'Slowly Turn Left',
    EnrollmentPose.chinUp: 'Tilt Chin Up',
    EnrollmentPose.chinDown: 'Tilt Chin Down',
  };

  static const _poseIcons = {
    EnrollmentPose.straight: Icons.face,
    EnrollmentPose.slightRight: Icons.turn_right,
    EnrollmentPose.slightLeft: Icons.turn_left,
    EnrollmentPose.chinUp: Icons.arrow_upward,
    EnrollmentPose.chinDown: Icons.arrow_downward,
  };

  _EnrollmentState _state = _EnrollmentState.ready;
  int _completedSteps = 0;
  double _quality = 0.0;
  double _livenessScore = 0.0;
  String? _instruction;
  String? _errorMessage;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _startSession();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    final employeeId = ref.read(currentEmployeeIdProvider);
    await ref.read(faceEnrollmentServiceProvider).startEnrollmentSession(employeeId);
  }

  Future<void> _captureStep() async {
    if (_state == _EnrollmentState.complete || _state == _EnrollmentState.failed) return;

    setState(() {
      _state = _EnrollmentState.scanning;
      _instruction = null;
    });

    final pose = _poses[_completedSteps];
    final result = await ref
        .read(faceEnrollmentServiceProvider)
        .captureEnrollmentSample(pose);

    if (!mounted) return;

    if (!result.captured) {
      setState(() {
        _state = _EnrollmentState.ready;
        _instruction = result.instruction;
      });
      return;
    }

    setState(() {
      _quality = result.qualityScore;
      _livenessScore = result.livenessScore;
      _completedSteps++;

      if (_completedSteps >= _poses.length) {
        _state = _EnrollmentState.finalising;
      } else {
        _state = _EnrollmentState.ready;
      }
    });

    if (_state == _EnrollmentState.finalising) {
      await _finalise();
    }
  }

  Future<void> _finalise() async {
    final result =
        await ref.read(faceEnrollmentServiceProvider).finaliseEnrollment();
    if (!mounted) return;

    if (result.success) {
      setState(() {
        _state = _EnrollmentState.complete;
        _quality = result.averageQualityScore;
        _livenessScore = result.averageLivenessScore;
      });
    } else {
      setState(() {
        _state = _EnrollmentState.failed;
        _errorMessage = result.failureReason;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await ref.read(faceEnrollmentServiceProvider).cancelEnrollmentSession();
            if (context.mounted) context.go('/onboarding/device');
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device Registration', style: TextStyle(fontSize: 16)),
            Text(
              'Step 4 of 5',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            width: 80,
            child: LinearProgressIndicator(
              value: 4 / 5,
              backgroundColor: AppColors.surfaceContainerHigh,
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text(
                    'Face Enrollment',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _state == _EnrollmentState.failed
                        ? (_errorMessage ?? 'Enrollment failed. Please try again.')
                        : 'Position your face within the frame and follow the instructions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _state == _EnrollmentState.failed
                          ? AppColors.error
                          : AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Oval face guide ──
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        final scale =
                            _state == _EnrollmentState.scanning ? _pulseAnim.value : 1.0;
                        return Transform.scale(
                          scale: scale,
                          child: SizedBox(
                            width: 220,
                            height: 280,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _state == _EnrollmentState.complete
                                          ? AppColors.success
                                          : _state == _EnrollmentState.failed
                                              ? AppColors.error
                                              : AppColors.primary,
                                      width: 3,
                                    ),
                                    borderRadius:
                                        const BorderRadius.all(Radius.elliptical(110, 140)),
                                    color: AppColors.surfaceContainerLow,
                                  ),
                                  child: _state == _EnrollmentState.complete
                                      ? const Icon(Icons.check_circle,
                                          color: AppColors.success, size: 72)
                                      : _state == _EnrollmentState.failed
                                          ? const Icon(Icons.error_outline,
                                              color: AppColors.error, size: 72)
                                          : Icon(Icons.face,
                                              color:
                                                  AppColors.primary.withValues(alpha: 0.3),
                                              size: 72),
                                ),
                                if (_quality > 0)
                                  Positioned(
                                    bottom: 0,
                                    child: _QualityBadge(
                                      quality: _quality,
                                      livenessScore: _livenessScore,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Instruction banner ──
                  if (_instruction != null) ...[
                    _InstructionBanner(instruction: _instruction!),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // ── Instruction / step card ──
                  if (_state != _EnrollmentState.complete &&
                      _state != _EnrollmentState.failed) ...[
                    _StepCard(
                      poses: _poses,
                      poseLabels: _poseLabels,
                      poseIcons: _poseIcons,
                      completedSteps: _completedSteps,
                      currentPose: _completedSteps < _poses.length
                          ? _poses[_completedSteps]
                          : _poses.last,
                    ),
                  ] else if (_state == _EnrollmentState.complete) ...[
                    _CompleteCard(
                      qualityScore: _quality,
                      livenessScore: _livenessScore,
                    ),
                  ],
                ],
              ),
            ),
            _ActionBar(
              state: _state,
              onNext: _captureStep,
              onContinue: () => context.go('/onboarding/success'),
              onCancel: () async {
                await ref
                    .read(faceEnrollmentServiceProvider)
                    .cancelEnrollmentSession();
                if (context.mounted) context.go('/login');
              },
              onRetry: () async {
                await _startSession();
                if (mounted) {
                  setState(() {
                    _state = _EnrollmentState.ready;
                    _completedSteps = 0;
                    _quality = 0;
                    _livenessScore = 0;
                    _errorMessage = null;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB-STATE ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum _EnrollmentState { ready, scanning, finalising, complete, failed }

// ─────────────────────────────────────────────────────────────────────────────
// SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.quality, required this.livenessScore});
  final double quality;
  final double livenessScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: AppColors.success, size: 14),
          const SizedBox(width: 5),
          Text(
            'Q: ${(quality * 100).toStringAsFixed(0)}%'
            '  L: ${(livenessScore * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  const _InstructionBanner({required this.instruction});
  final String instruction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 13, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.poses,
    required this.poseLabels,
    required this.poseIcons,
    required this.completedSteps,
    required this.currentPose,
  });

  final List<EnrollmentPose> poses;
  final Map<EnrollmentPose, String> poseLabels;
  final Map<EnrollmentPose, IconData> poseIcons;
  final int completedSteps;
  final EnrollmentPose currentPose;

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Instruction',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'STEP ${completedSteps + 1} OF ${poses.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                Icon(poseIcons[currentPose]!, color: AppColors.primary, size: 32),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  poseLabels[currentPose]!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: poses.asMap().entries.map((entry) {
              final idx = entry.key;
              final pose = entry.value;
              final done = idx < completedSteps;
              final active = idx == completedSteps;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? AppColors.success
                            : active
                                ? AppColors.primary
                                : AppColors.surfaceContainerHigh,
                        border: Border.all(
                          color: active ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        done ? Icons.check : poseIcons[pose]!,
                        color: done || active ? Colors.white : AppColors.onSurfaceVariant,
                        size: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      poseLabels[pose]!.split(' ').last,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        color: active ? AppColors.primary : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CompleteCard extends StatelessWidget {
  const _CompleteCard({
    required this.qualityScore,
    required this.livenessScore,
  });
  final double qualityScore;
  final double livenessScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user, color: AppColors.success, size: 32),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Face enrollment complete!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quality: ${(qualityScore * 100).toStringAsFixed(0)}%  '
            '·  Liveness: ${(livenessScore * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your biometric profile has been securely captured, encrypted, and stored on-device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.state,
    required this.onNext,
    required this.onContinue,
    required this.onCancel,
    required this.onRetry,
  });

  final _EnrollmentState state;
  final VoidCallback onNext;
  final VoidCallback onContinue;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: state == _EnrollmentState.failed ? onRetry : onCancel,
              child: Text(state == _EnrollmentState.failed ? 'Retry' : 'Cancel'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: PrimaryActionButton(
              label: switch (state) {
                _EnrollmentState.complete => 'Continue',
                _EnrollmentState.scanning || _EnrollmentState.finalising => 'Capturing...',
                _EnrollmentState.failed => 'Failed',
                _ => 'Next Step',
              },
              icon: state == _EnrollmentState.complete
                  ? Icons.arrow_forward
                  : Icons.camera_alt,
              loading: state == _EnrollmentState.scanning ||
                  state == _EnrollmentState.finalising,
              onPressed: state == _EnrollmentState.complete
                  ? onContinue
                  : state == _EnrollmentState.failed
                      ? null
                      : onNext,
            ),
          ),
        ],
      ),
    );
  }
}
