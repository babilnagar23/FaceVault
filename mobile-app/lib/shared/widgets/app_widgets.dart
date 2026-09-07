import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────
// SCAFFOLD
// ─────────────────────────────────────────

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.showBack = true,
    this.leading,
    this.floatingActionButton,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? leading;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: showBack,
        leading: leading,
        actions: actions,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            ...children,
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// BOTTOM NAV ITEMS
// ─────────────────────────────────────────

enum FaceVaultTab { home, attendance, community, alerts, profile }

class FaceVaultNavBar extends StatelessWidget {
  const FaceVaultNavBar({
    super.key,
    required this.currentTab,
    required this.onTap,
    this.alertCount = 0,
  });

  final FaceVaultTab currentTab;
  final ValueChanged<FaceVaultTab> onTap;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
              active: currentTab == FaceVaultTab.home,
              onTap: () => onTap(FaceVaultTab.home),
            ),
            _NavItem(
              icon: Icons.fingerprint,
              activeIcon: Icons.fingerprint,
              label: 'Attendance',
              active: currentTab == FaceVaultTab.attendance,
              onTap: () => onTap(FaceVaultTab.attendance),
            ),
            _NavItem(
              icon: Icons.campaign_outlined,
              activeIcon: Icons.campaign,
              label: 'Community',
              active: currentTab == FaceVaultTab.community,
              onTap: () => onTap(FaceVaultTab.community),
            ),
            _NavItem(
              icon: Icons.notifications_outlined,
              activeIcon: Icons.notifications,
              label: 'Alerts',
              active: currentTab == FaceVaultTab.alerts,
              badge: alertCount > 0 ? alertCount.toString() : null,
              onTap: () => onTap(FaceVaultTab.alerts),
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              active: currentTab == FaceVaultTab.profile,
              onTap: () => onTap(FaceVaultTab.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (active)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Icon(activeIcon, color: color, size: 22),
                    )
                  else
                    Icon(icon, color: color, size: 22),
                  if (badge != null)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SYNC BANNER
// ─────────────────────────────────────────

class SyncBanner extends StatelessWidget {
  const SyncBanner({
    super.key,
    required this.status,
    this.pendingCount = 0,
    this.onSyncNow,
  });

  final SyncBannerStatus status;
  final int pendingCount;
  final VoidCallback? onSyncNow;

  @override
  Widget build(BuildContext context) {
    if (status == SyncBannerStatus.synced) return const SizedBox.shrink();

    final (color, bg, icon, label) = switch (status) {
      SyncBannerStatus.offline => (
          AppColors.warning,
          AppColors.warningSurface,
          Icons.wifi_off,
          'Offline Mode: Data pending sync',
        ),
      SyncBannerStatus.syncing => (
          AppColors.secondary,
          const Color(0xFFE3F2FD),
          Icons.sync,
          'Syncing $pendingCount records...',
        ),
      SyncBannerStatus.pending => (
          AppColors.warning,
          AppColors.warningSurface,
          Icons.cloud_upload_outlined,
          '$pendingCount records pending sync',
        ),
      SyncBannerStatus.failed => (
          AppColors.error,
          AppColors.errorSurface,
          Icons.sync_problem,
          'Sync failed. Tap to retry.',
        ),
      SyncBannerStatus.synced => (
          AppColors.success,
          AppColors.successSurface,
          Icons.check_circle,
          'All synced',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      color: bg,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ),
          if (status == SyncBannerStatus.offline || status == SyncBannerStatus.pending)
            GestureDetector(
              onTap: onSyncNow,
              child: Text(
                'Sync Now',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          if (status == SyncBannerStatus.syncing)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
        ],
      ),
    );
  }
}

enum SyncBannerStatus { offline, syncing, pending, failed, synced }

// ─────────────────────────────────────────
// ONBOARDING STEP INDICATOR
// ─────────────────────────────────────────

class OnboardingStepBar extends StatelessWidget {
  const OnboardingStepBar({
    super.key,
    required this.current,
    required this.total,
    required this.label,
  });

  final int current;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP $current OF $total',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: current / total,
            backgroundColor: AppColors.surfaceContainerHigh,
            color: AppColors.primary,
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// PRIMARY BUTTON
// ─────────────────────────────────────────

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon ?? Icons.arrow_forward),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color ?? AppColors.primary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// METRIC CARD
// ─────────────────────────────────────────

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.iconColor,
    this.trailing,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? AppColors.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ic.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: ic, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null)
                    Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// STATUS CHIP
// ─────────────────────────────────────────

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// STATUS DOT
// ─────────────────────────────────────────

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────
// TEXT FIELD
// ─────────────────────────────────────────

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.suffix,
    this.prefix,
    this.maxLines = 1,
    this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffix;
  final Widget? prefix;
  final int maxLines;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
        prefixIcon: prefix,
      ),
    );
  }
}

// ─────────────────────────────────────────
// LOADING SKELETON (shimmer)
// ─────────────────────────────────────────

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.lines = 3, this.height = 56});

  final int lines;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainerHigh,
      highlightColor: AppColors.surfaceContainerLow,
      child: Column(
        children: List.generate(
          lines,
          (index) => Container(
            height: height,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.action,
    this.actionLabel,
  });

  final String title;
  final String message;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: action, child: Text(actionLabel ?? 'Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
    this.helpAction,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? helpAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 36),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                if (helpAction != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(onPressed: helpAction, child: const Text('Get Help')),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─────────────────────────────────────────
// QUICK ACTION CARD
// ─────────────────────────────────────────

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: ic, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// CONFIRMATION DIALOG
// ─────────────────────────────────────────

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

Future<bool?> showConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
}

// ─────────────────────────────────────────
// VERIFICATION PIPELINE STEP
// ─────────────────────────────────────────

enum PipelineStepStatus { waiting, active, success, failed }

class PipelineStep extends StatelessWidget {
  const PipelineStep({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.status,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final PipelineStepStatus status;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      PipelineStepStatus.waiting => (AppColors.onSurfaceVariant, AppColors.surfaceContainerLow),
      PipelineStepStatus.active => (AppColors.primary, const Color(0xFFE3F2FD)),
      PipelineStepStatus.success => (AppColors.success, AppColors.successSurface),
      PipelineStepStatus.failed => (AppColors.error, AppColors.errorSurface),
    };

    final statusIcon = switch (status) {
      PipelineStepStatus.waiting => icon,
      PipelineStepStatus.active => Icons.radio_button_checked,
      PipelineStepStatus.success => Icons.check_circle,
      PipelineStepStatus.failed => Icons.cancel,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Icon(statusIcon, color: color, size: 18),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: color.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: status == PipelineStepStatus.waiting
                          ? AppColors.onSurfaceVariant
                          : AppColors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// INFO ROW (key-value detail row)
// ─────────────────────────────────────────

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// MAP PLACEHOLDER (upgradeable to real map)
// ─────────────────────────────────────────

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({
    super.key,
    required this.siteName,
    this.height = 160,
  });

  final String siteName;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD2E4FF), Color(0xFFF7F9FC)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Stack(
        children: [
          // Grid lines to suggest a map
          CustomPaint(
            size: Size.infinite,
            painter: _MapGridPainter(),
          ),
          // Geofence circle
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 2),
              ),
            ),
          ),
          // Site marker
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    siteName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
