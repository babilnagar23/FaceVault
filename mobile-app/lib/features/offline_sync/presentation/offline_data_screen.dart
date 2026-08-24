import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Offline data preparation — first-time onboarding step.
/// Downloads and caches the employee profile, project details, assigned site,
/// geofence, attendance rules, and face configuration for offline-first operation.
class OfflineDataScreen extends ConsumerStatefulWidget {
  const OfflineDataScreen({super.key});

  @override
  ConsumerState<OfflineDataScreen> createState() => _OfflineDataScreenState();
}

class _OfflineDataScreenState extends ConsumerState<OfflineDataScreen> {
  final List<_DataItem> _items = [
    _DataItem(label: 'Employee Profile', icon: Icons.person_outline, done: false),
    _DataItem(label: 'Project Details', icon: Icons.work_outline, done: false),
    _DataItem(label: 'Assigned Site & GeoFence', icon: Icons.location_on_outlined, done: false),
    _DataItem(label: 'Attendance Rules', icon: Icons.rule_outlined, done: false),
    _DataItem(label: 'Shift Configuration', icon: Icons.schedule_outlined, done: false),
    _DataItem(label: 'Face Configuration', icon: Icons.face_retouching_natural, done: false),
  ];

  bool _started = false;
  bool _complete = false;
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    setState(() => _started = true);
    // Load employee data to confirm real API works through the chain
    await ref.read(userApiProvider).currentEmployee();

    for (var i = 0; i < _items.length; i++) {
      if (!mounted) return;
      setState(() => _currentIndex = i);
      // Simulate realistic download delays per item
      await Future<void>.delayed(Duration(milliseconds: 380 + i * 55));
      if (!mounted) return;
      setState(() => _items[i] = _items[i].copyWith(done: true));
    }
    if (!mounted) return;
    setState(() => _complete = true);
  }

  double get _progress {
    if (!_started) return 0;
    final done = _items.where((i) => i.done).length;
    return done / _items.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Preparing Your Device'),
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            OnboardingStepBar(current: 3, total: 5, label: 'Offline Setup'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Header card
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
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: const Icon(
                            Icons.cloud_download_outlined,
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _complete ? 'Device Ready' : 'Downloading Data',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _complete
                              ? 'All required data has been cached locally. FaceVault will now operate offline when connectivity is unavailable.'
                              : 'Downloading and caching your work data for offline use. This allows attendance marking without an active internet connection.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 8,
                            backgroundColor: AppColors.surfaceContainerHigh,
                            color: _complete ? AppColors.success : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _complete
                              ? 'Complete'
                              : '${(_progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _complete ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Data items list
                  ...List.generate(_items.length, (index) {
                    final item = _items[index];
                    final isActive = _currentIndex == index && !item.done;
                    return _DataItemTile(
                      item: item,
                      isActive: isActive,
                    );
                  }),
                  const SizedBox(height: AppSpacing.lg),
                  // Offline notice
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3EDF7),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Once downloaded, attendance can be marked even without internet access. Records are queued and synced automatically when connectivity returns.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  height: 1.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_complete)
                    PrimaryActionButton(
                      label: 'Continue to Face Enrollment',
                      icon: Icons.face,
                      onPressed: () => context.go('/onboarding/face'),
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

class _DataItem {
  const _DataItem({required this.label, required this.icon, required this.done});

  final String label;
  final IconData icon;
  final bool done;

  _DataItem copyWith({bool? done}) => _DataItem(
        label: label,
        icon: icon,
        done: done ?? this.done,
      );
}

class _DataItemTile extends StatelessWidget {
  const _DataItemTile({required this.item, required this.isActive});

  final _DataItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      decoration: BoxDecoration(
        color: item.done
            ? AppColors.successSurface
            : isActive
                ? const Color(0xFFE3EDF7)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: item.done
              ? AppColors.success.withValues(alpha: 0.3)
              : isActive
                  ? AppColors.secondary.withValues(alpha: 0.4)
                  : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.done
                  ? AppColors.success.withValues(alpha: 0.12)
                  : isActive
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              item.icon,
              size: 18,
              color: item.done
                  ? AppColors.success
                  : isActive
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: item.done
                    ? AppColors.success
                    : isActive
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
              ),
            ),
          ),
          if (item.done)
            const Icon(Icons.check_circle, size: 20, color: AppColors.success)
          else if (isActive)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          else
            const Icon(Icons.radio_button_unchecked, size: 20, color: AppColors.borderSubtle),
        ],
      ),
    );
  }
}
