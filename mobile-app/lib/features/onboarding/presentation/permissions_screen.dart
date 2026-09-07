import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  // Mock permission states — real implementation hooks into permission_handler
  final _granted = <String>{
    'Camera',
    'Local Storage',
  };

  final _permissions = [
    const _PermissionDef(
      key: 'Camera',
      icon: Icons.photo_camera_outlined,
      title: 'Camera Access',
      description: 'Required for facial recognition check-ins and document scanning.',
    ),
    const _PermissionDef(
      key: 'Location',
      icon: Icons.location_on_outlined,
      title: 'Location Services',
      description: 'Ensures check-ins occur within designated geofenced areas.',
    ),
    const _PermissionDef(
      key: 'Local Storage',
      icon: Icons.folder_outlined,
      title: 'Local Storage',
      description: 'Allows temporary offline data storage during network interruptions.',
    ),
    const _PermissionDef(
      key: 'Notifications',
      icon: Icons.notifications_outlined,
      title: 'Push Notifications',
      description: 'Receive real-time alerts for schedule changes and system updates.',
    ),
  ];

  bool get _canContinue => _granted.contains('Camera') && _granted.contains('Location');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('Device Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permissions are required to use FaceVault.')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step bar
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: OnboardingStepBar(
                current: 1,
                total: 5,
                label: 'Permissions',
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Required Permissions',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'To ensure accurate attendance tracking and optimal device functionality, please grant the following permissions.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final perm in _permissions) ...[
                    _PermissionCard(
                      perm: perm,
                      granted: _granted.contains(perm.key),
                      onToggle: (value) {
                        setState(() {
                          if (value) {
                            _granted.add(perm.key);
                          } else {
                            _granted.remove(perm.key);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (!_canContinue)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningSurface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: AppColors.warning, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Camera and Location permissions are required to continue.',
                              style: TextStyle(fontSize: 13, color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: PrimaryActionButton(
                label: 'Continue',
                icon: Icons.arrow_forward,
                onPressed: _canContinue ? () => context.go('/onboarding/device') : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDef {
  const _PermissionDef({
    required this.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String key;
  final IconData icon;
  final String title;
  final String description;
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.perm,
    required this.granted,
    required this.onToggle,
  });

  final _PermissionDef perm;
  final bool granted;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: granted ? AppColors.primary.withValues(alpha: 0.3) : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(perm.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perm.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  perm.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Stack(
            alignment: Alignment.center,
            children: [
              Switch(
                value: granted,
                onChanged: onToggle,
                activeThumbColor: AppColors.primary,
              ),
              if (granted)
                Positioned(
                  right: 0,
                  bottom: 6,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 9),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
