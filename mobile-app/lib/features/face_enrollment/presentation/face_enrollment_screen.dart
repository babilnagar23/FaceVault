import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

enum _EnrollmentStep {
  lookStraight,
  turnRight,
  turnLeft,
  blink,
}

enum _EnrollmentState {
  ready,
  scanning,
  complete,
  failed,
}

class FaceEnrollmentScreen extends ConsumerStatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  ConsumerState<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends ConsumerState<FaceEnrollmentScreen>
    with SingleTickerProviderStateMixin {
  _EnrollmentState _state = _EnrollmentState.ready;
  _EnrollmentStep _currentStep = _EnrollmentStep.lookStraight;
  double _quality = 0.0;
  int _completedSteps = 0;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  static const _steps = [
    _EnrollmentStep.lookStraight,
    _EnrollmentStep.turnRight,
    _EnrollmentStep.turnLeft,
    _EnrollmentStep.blink,
  ];

  static const _stepLabels = {
    _EnrollmentStep.lookStraight: 'Look Straight',
    _EnrollmentStep.turnRight: 'Slowly Turn Right',
    _EnrollmentStep.turnLeft: 'Slowly Turn Left',
    _EnrollmentStep.blink: 'Blink Naturally',
  };

  static const _stepIcons = {
    _EnrollmentStep.lookStraight: Icons.face,
    _EnrollmentStep.turnRight: Icons.turn_right,
    _EnrollmentStep.turnLeft: Icons.turn_left,
    _EnrollmentStep.blink: Icons.remove_red_eye_outlined,
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_state == _EnrollmentState.complete || _state == _EnrollmentState.failed) return;

    setState(() {
      _state = _EnrollmentState.scanning;
      _quality = 0.0;
    });

    // Simulate quality score building up
    for (int i = 0; i <= 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() => _quality = i / 10.0);
    }

    setState(() {
      _completedSteps++;
      if (_completedSteps >= _steps.length) {
        _state = _EnrollmentState.complete;
      } else {
        _state = _EnrollmentState.ready;
        _currentStep = _steps[_completedSteps];
        _quality = 0.98;
      }
    });

    if (_state == _EnrollmentState.complete) {
      await ref.read(faceEnrollmentApiProvider).completeEnrollment();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/onboarding/device'),
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
                  const Text(
                    'Position your face within the frame and follow the instructions to capture your biometric profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // ── Oval face guide ──
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        final scale = _state == _EnrollmentState.scanning ? _pulseAnim.value : 1.0;
                        return Transform.scale(
                          scale: scale,
                          child: SizedBox(
                            width: 220,
                            height: 280,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // Oval border
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _state == _EnrollmentState.complete
                                          ? AppColors.success
                                          : AppColors.primary,
                                      width: 3,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.elliptical(110, 140),
                                    ),
                                    color: AppColors.surfaceContainerLow,
                                  ),
                                  child: _state == _EnrollmentState.complete
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: AppColors.success,
                                          size: 72,
                                        )
                                      : Icon(
                                          Icons.face,
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          size: 72,
                                        ),
                                ),
                                // Quality badge
                                if (_quality > 0)
                                  Positioned(
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.full),
                                        border: Border.all(
                                          color: AppColors.success.withValues(alpha: 0.3),
                                        ),
                                        boxShadow: AppShadows.card,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.verified,
                                            color: AppColors.success,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Quality: ${(_quality * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
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
                  if (_state != _EnrollmentState.complete) ...[
                    // ── Instruction card ──
                    Container(
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
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  'STEP ${_completedSteps + 1} OF ${_steps.length}',
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
                                Icon(
                                  _stepIcons[_currentStep]!,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  _stepLabels[_currentStep]!,
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
                            children: _steps.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final step = entry.value;
                              final done = idx < _completedSteps;
                              final active = idx == _completedSteps;
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
                                          color: active
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        done ? Icons.check : _stepIcons[step]!,
                                        color: done || active ? Colors.white : AppColors.onSurfaceVariant,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _stepLabels[step]!.split(' ').last,
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
                    ),
                  ] else ...[
                    // ── Complete state ──
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.verified_user, color: AppColors.success, size: 32),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Face enrollment complete!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your biometric profile has been securely captured and encrypted.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: PrimaryActionButton(
                      label: _state == _EnrollmentState.complete
                          ? 'Continue'
                          : _state == _EnrollmentState.scanning
                              ? 'Capturing...'
                              : 'Next Step',
                      icon: _state == _EnrollmentState.complete
                          ? Icons.arrow_forward
                          : Icons.camera_alt,
                      loading: _state == _EnrollmentState.scanning,
                      onPressed: _state == _EnrollmentState.complete
                          ? () => context.go('/onboarding/success')
                          : _nextStep,
                    ),
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
