import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            _SectionLabel('Account'),
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Employee Profile',
              onTap: () => context.push('/profile'),
            ),
            _SettingsTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password change — contact your administrator.')),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _SectionLabel('Security & Biometric'),
            _SettingsTile(
              icon: Icons.face,
              title: 'Re-enroll Face',
              subtitle: 'Update your biometric profile',
              onTap: () => context.push('/onboarding/face'),
            ),
            _SettingsTile(
              icon: Icons.smartphone,
              title: 'Registered Devices',
              onTap: () {},
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _SectionLabel('Notifications'),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: AppColors.primary,
              ),
            ),
            _SettingsTile(
              icon: Icons.campaign_outlined,
              title: 'Announcements',
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: AppColors.primary,
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _SectionLabel('Offline & Sync'),
            _SettingsTile(
              icon: Icons.cloud_sync_outlined,
              title: 'Sync Pending Records',
              onTap: () async {
                await ref.read(syncApiProvider).flush();
                ref.invalidate(syncStatusProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Records synced successfully.')),
                  );
                }
              },
            ),
            _SettingsTile(
              icon: Icons.wifi_off,
              title: 'Offline Mode',
              subtitle: 'Current: Enabled when offline',
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _SectionLabel('About'),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'App Version',
              trailing: const Text(
                '1.0.0 Enterprise',
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () {},
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: AppSpacing.md),
            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showConfirmation(
                    context,
                    title: 'Sign Out',
                    message: 'Are you sure you want to sign out of FaceVault? Pending sync records will be saved locally.',
                    confirmLabel: 'Sign Out',
                    cancelLabel: 'Cancel',
                    destructive: true,
                  );
                  if (confirmed == true) {
                    await ref.read(authApiProvider).logout();
                    if (context.mounted) context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant))
          : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant, size: 20) : null),
      onTap: onTap,
    );
  }
}
