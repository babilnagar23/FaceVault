import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(currentEmployeeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: employeeAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: LoadingSkeleton(lines: 5),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ErrorStateView(
              message: 'Could not load your profile.',
              onRetry: () => ref.invalidate(currentEmployeeProvider),
            ),
          ),
          data: (employee) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Avatar card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderSubtle, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            employee.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(employee.name, style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        employee.id,
                        style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StatusChip(label: employee.role, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          StatusChip(label: employee.department, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Assignment
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assignment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const Divider(height: AppSpacing.lg),
                      InfoRow(icon: Icons.work_outline, label: 'Project', value: employee.project),
                      const Divider(height: 1),
                      InfoRow(icon: Icons.location_on_outlined, label: 'Location', value: employee.location),
                      const Divider(height: 1),
                      InfoRow(icon: Icons.schedule, label: 'Shift', value: employee.shift),
                      const Divider(height: 1),
                      InfoRow(icon: Icons.person_outline, label: 'Manager', value: employee.managerName ?? 'N/A'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Biometric & device
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Device & Biometric', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const Divider(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Face Enrollment', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                          StatusChip(
                            label: employee.faceEnrolled ? 'Enrolled' : 'Not Enrolled',
                            color: employee.faceEnrolled ? AppColors.success : AppColors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Device Status', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                          StatusChip(
                            label: employee.deviceRegistered ? 'Registered' : 'Not Registered',
                            color: employee.deviceRegistered ? AppColors.success : AppColors.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
