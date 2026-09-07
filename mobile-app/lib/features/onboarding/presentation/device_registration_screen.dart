import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class DeviceRegistrationScreen extends ConsumerStatefulWidget {
  const DeviceRegistrationScreen({super.key});

  @override
  ConsumerState<DeviceRegistrationScreen> createState() => _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState extends ConsumerState<DeviceRegistrationScreen> {
  bool _registering = false;
  bool _registered = false;

  Future<void> _register() async {
    setState(() => _registering = true);
    await ref.read(userApiProvider).registerDevice();
    if (!mounted) return;
    setState(() {
      _registering = false;
      _registered = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    context.go('/onboarding/offline');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/onboarding/permissions'),
        ),
        title: const Text('Device Setup'),
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: ref.read(userApiProvider).deviceMetadata(),
          builder: (context, snapshot) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: OnboardingStepBar(
                    current: 2,
                    total: 5,
                    label: 'Device',
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Device Registration',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Your device will be securely registered to your employee account. Only this device will be authorized for attendance.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (!snapshot.hasData)
                        const LoadingSkeleton(lines: 4)
                      else ...[
                        _DeviceInfoTile(
                          icon: Icons.smartphone,
                          label: 'Device Name',
                          value: snapshot.data!.name,
                        ),
                        _DeviceInfoTile(
                          icon: Icons.memory,
                          label: 'Device Model',
                          value: snapshot.data!.model,
                        ),
                        _DeviceInfoTile(
                          icon: Icons.system_update_outlined,
                          label: 'OS Version',
                          value: snapshot.data!.osVersion,
                        ),
                        _DeviceInfoTile(
                          icon: Icons.apps,
                          label: 'App Version',
                          value: snapshot.data!.appVersion,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: _registered
                                ? AppColors.successSurface
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: _registered
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : AppColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _registered
                                    ? Icons.verified
                                    : Icons.device_unknown_outlined,
                                color: _registered
                                    ? AppColors.success
                                    : AppColors.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                _registered
                                    ? 'Device registered successfully'
                                    : 'Not yet registered',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _registered
                                      ? AppColors.success
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Text(
                            '🔒 Device metadata is collected securely. Sensitive identifiers are hashed and never exposed to UI components.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: PrimaryActionButton(
                    label: _registered ? 'Continuing...' : 'Register This Device',
                    icon: _registered ? Icons.check : Icons.verified_outlined,
                    loading: _registering,
                    onPressed: snapshot.hasData ? _register : null,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DeviceInfoTile extends StatelessWidget {
  const _DeviceInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
