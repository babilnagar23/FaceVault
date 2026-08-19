import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_models.dart';
import '../../shared/widgets/app_widgets.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      final hasSession = await ref.read(authApiProvider).hasSession();
      if (!mounted) return;
      context.go(hasSession ? '/dashboard' : '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.verified_user, color: Colors.white, size: 42),
            ),
            SizedBox(height: 16),
            Text('FaceVault', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('Secure AI attendance'),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final employeeId = TextEditingController(text: 'EMP-1042');
  final password = TextEditingController(text: 'demo1234');
  bool remember = true;
  bool showPassword = false;
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Employee Login',
      showBack: false,
      children: [
        const MetricCard(
          title: 'Connection',
          value: 'Online',
          icon: Icons.wifi,
          subtitle: 'Offline returning-user login is supported after a saved session.',
        ),
        AppTextField(label: 'Employee ID', controller: employeeId),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Password',
          controller: password,
          obscureText: !showPassword,
          suffix: IconButton(
            tooltip: showPassword ? 'Hide password' : 'Show password',
            icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => showPassword = !showPassword),
          ),
        ),
        CheckboxListTile(
          value: remember,
          onChanged: (value) => setState(() => remember = value ?? true),
          title: const Text('Remember session'),
          contentPadding: EdgeInsets.zero,
        ),
        if (error != null)
          StatusChip(label: error!, color: AppColors.error),
        const SizedBox(height: AppSpacing.md),
        PrimaryActionButton(
          label: 'Login',
          loading: loading,
          icon: Icons.login,
          onPressed: () async {
            setState(() {
              loading = true;
              error = null;
            });
            final result = await ref.read(authApiProvider).login(employeeId.text, password.text);
            if (!mounted) return;
            setState(() => loading = false);
            if (!result.authenticated) {
              setState(() => error = result.message ?? 'Unable to login.');
              return;
            }
            context.go(result.firstDeviceLogin ? '/onboarding/permissions' : '/dashboard');
          },
        ),
        TextButton(onPressed: () {}, child: const Text('Forgot password')),
      ],
    );
  }
}

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final permissions = [
      ('Camera', 'Required for face verification.', Icons.photo_camera, 'Granted'),
      ('Location', 'Required to verify assigned work location.', Icons.location_on, 'Granted'),
      ('Notifications', 'Required for announcements and alerts.', Icons.notifications, 'Denied'),
      ('Storage', 'Used only where the platform requires media access.', Icons.folder, 'Optional'),
    ];
    return AppScaffold(
      title: 'Permissions',
      children: [
        for (final permission in permissions)
          Card(
            child: ListTile(
              leading: Icon(permission.$3, color: AppColors.primary),
              title: Text(permission.$1),
              subtitle: Text(permission.$2),
              trailing: StatusChip(
                label: permission.$4,
                color: permission.$4 == 'Denied' ? AppColors.warning : AppColors.success,
              ),
            ),
          ),
        PrimaryActionButton(
          label: 'Continue',
          icon: Icons.arrow_forward,
          onPressed: () => context.go('/onboarding/device'),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.settings),
          label: const Text('Open system settings'),
        ),
      ],
    );
  }
}

class DeviceRegistrationScreen extends ConsumerWidget {
  const DeviceRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(userApiProvider).deviceMetadata(),
      builder: (context, snapshot) {
        final device = snapshot.data;
        return AppScaffold(
          title: 'Device Registration',
          children: [
            if (!snapshot.hasData) const LoadingSkeleton(lines: 4),
            if (device != null) ...[
              MetricCard(title: 'Device Name', value: device.name, icon: Icons.smartphone),
              MetricCard(title: 'Model', value: device.model, icon: Icons.memory),
              MetricCard(title: 'OS Version', value: device.osVersion, icon: Icons.system_update),
              MetricCard(title: 'App Version', value: device.appVersion, icon: Icons.apps),
              StatusChip(label: device.registered ? 'Registered' : 'Not registered', color: device.registered ? AppColors.success : AppColors.warning),
            ],
            PrimaryActionButton(
              label: 'Register Device',
              icon: Icons.verified,
              onPressed: () async {
                await ref.read(userApiProvider).registerDevice();
                if (context.mounted) context.go('/onboarding/face');
              },
            ),
          ],
        );
      },
    );
  }
}

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  var step = 0;
  final steps = const [
    'Read instructions',
    'Center your face',
    'Improve lighting',
    'Liveness check',
    'Capture sample 3 of 3',
    'Save enrollment',
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Face Enrollment',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Container(
                  width: 220,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.secondary, width: 3),
                    borderRadius: BorderRadius.circular(120),
                  ),
                  child: const Icon(Icons.face_retouching_natural, size: 96, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(value: (step + 1) / steps.length),
                const SizedBox(height: AppSpacing.md),
                Text(steps[step], style: Theme.of(context).textTheme.titleMedium),
                const Text('Keep your face visible, directly facing the camera, with steady lighting. Raw biometric vectors are never shown.'),
              ],
            ),
          ),
        ),
        PrimaryActionButton(
          label: step == steps.length - 1 ? 'Finish Enrollment' : 'Continue',
          icon: Icons.face,
          onPressed: () {
            if (step == steps.length - 1) {
              context.go('/onboarding/success');
            } else {
              setState(() => step += 1);
            }
          },
        ),
      ],
    );
  }
}

class RegistrationSuccessScreen extends StatelessWidget {
  const RegistrationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Registration Complete',
      showBack: false,
      children: [
        const MetricCard(
          title: 'Employee device ready',
          value: 'Registration successful',
          icon: Icons.check_circle,
          subtitle: 'Offline data, permissions, device, and face enrollment are ready.',
        ),
        PrimaryActionButton(
          label: 'Go to Dashboard',
          icon: Icons.dashboard,
          onPressed: () => context.go('/dashboard'),
        ),
      ],
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(currentEmployeeProvider);
    return employee.when(
      loading: () => const AppScaffold(title: 'Dashboard', showBack: false, children: [LoadingSkeleton(lines: 5)]),
      error: (error, stackTrace) => AppScaffold(title: 'Dashboard', showBack: false, children: [ErrorStateView(message: 'Unable to load dashboard', onRetry: () => ref.invalidate(currentEmployeeProvider))]),
      data: (employee) => AppScaffold(
        title: 'Dashboard',
        showBack: false,
        actions: [
          IconButton(onPressed: () => context.go('/notifications'), icon: const Icon(Icons.notifications)),
        ],
        children: [
          Text('Hello, ${employee.name}', style: Theme.of(context).textTheme.headlineSmall),
          Text('${employee.id} • ${employee.department}'),
          const SizedBox(height: AppSpacing.md),
          const MetricCard(title: "Today's Attendance", value: 'Not Marked', icon: Icons.how_to_reg, subtitle: 'Start when you reach your assigned location.'),
          MetricCard(title: 'Assigned Project', value: employee.project, icon: Icons.work, subtitle: employee.location),
          MetricCard(title: 'Shift', value: employee.shift, icon: Icons.schedule, subtitle: 'Shift Start 09:00 • Shift End 18:00'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _QuickAction(label: 'Mark Attendance', icon: Icons.camera_alt, route: '/attendance/today'),
              _QuickAction(label: 'History', icon: Icons.calendar_month, route: '/attendance/history'),
              _QuickAction(label: 'Ask for Help', icon: Icons.support_agent, route: '/help'),
              _QuickAction(label: 'Community', icon: Icons.campaign, route: '/community'),
              _QuickAction(label: 'Settings', icon: Icons.settings, route: '/settings'),
            ],
          ),
          const StatusChip(label: 'Pending 3 records', color: AppColors.warning),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.icon, required this.route});
  final String label;
  final IconData icon;
  final String route;
  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: () => context.go(route),
      );
}

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Attendance',
      children: [
        _NavTile(title: "Today's Attendance", subtitle: 'Face, liveness, location', route: '/attendance/today', icon: Icons.today),
        _NavTile(title: 'Attendance History', subtitle: 'Calendar and monthly records', route: '/attendance/history', icon: Icons.history),
        _NavTile(title: 'Ask for Help', subtitle: 'Create attendance support ticket', route: '/help/create', icon: Icons.support),
      ],
    );
  }
}

class TodayAttendanceScreen extends ConsumerStatefulWidget {
  const TodayAttendanceScreen({super.key});

  @override
  ConsumerState<TodayAttendanceScreen> createState() => _TodayAttendanceScreenState();
}

class _TodayAttendanceScreenState extends ConsumerState<TodayAttendanceScreen> {
  int step = -1;
  AttendanceRecord? result;
  String? failure;
  final pipeline = const [
    'Preparing camera...',
    'Position your face inside the frame',
    "Verifying that you're present...",
    'Verifying identity...',
    'Checking your work location...',
    'Finalising attendance decision...',
  ];

  Future<void> _start() async {
    for (var i = 0; i < pipeline.length; i++) {
      setState(() => step = i);
      await Future<void>.delayed(const Duration(milliseconds: 450));
    }
    final marked = await ref.read(attendanceApiProvider).markAttendance();
    setState(() => result = marked);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Today's Attendance",
      children: [
        const MetricCard(title: "Today's Shift", value: '09:00 - 18:00', icon: Icons.schedule, subtitle: 'Assigned Location: Sector 17'),
        if (step == -1 && result == null)
          PrimaryActionButton(label: 'Start Attendance', icon: Icons.camera_alt, onPressed: _start),
        if (step >= 0 && result == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const Icon(Icons.center_focus_strong, size: 92, color: AppColors.primary),
                  const SizedBox(height: AppSpacing.md),
                  Text(pipeline[step], style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  LinearProgressIndicator(value: (step + 1) / pipeline.length),
                ],
              ),
            ),
          ),
        if (failure != null)
          ErrorStateView(message: failure!, onRetry: () => setState(() => failure = null)),
        if (result != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StatusChip(label: 'Attendance Marked', color: AppColors.success),
                  const SizedBox(height: AppSpacing.md),
                  Text('Present', style: Theme.of(context).textTheme.headlineMedium),
                  Text('${result!.checkInTime} • Location Verified'),
                  Text('${result!.assignedSite} • ${result!.distanceMeters} m from assigned location'),
                  const SizedBox(height: AppSpacing.md),
                  const StatusChip(label: 'Synced', color: AppColors.success),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => setState(() => failure = 'Location Not Verified. Assigned Site: Site A. Current distance: 1.4 km.'),
          icon: const Icon(Icons.location_off),
          label: const Text('Preview location exception'),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() => failure = 'Face not recognised. Check lighting and face position, then try again.'),
          icon: const Icon(Icons.face_retouching_off),
          label: const Text('Preview face exception'),
        ),
      ],
    );
  }
}

class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(attendanceHistoryProvider);
    return AppScaffold(
      title: 'Attendance History',
      children: [
        const Wrap(
          spacing: AppSpacing.sm,
          children: [
            StatusChip(label: 'Present', color: AppColors.success),
            StatusChip(label: 'Late', color: AppColors.warning),
            StatusChip(label: 'Pending Review', color: AppColors.secondary),
          ],
        ),
        records.when(
          loading: () => const LoadingSkeleton(lines: 6),
          error: (error, stackTrace) => ErrorStateView(message: 'Unable to load records', onRetry: () => ref.invalidate(attendanceHistoryProvider)),
          data: (items) => items.isEmpty
              ? const EmptyStateView(title: 'No attendance records', message: 'Your monthly records will appear here.')
              : Column(
                  children: [
                    for (final record in items)
                      Card(
                        child: ListTile(
                          title: Text(DateFormat.yMMMd().format(record.date)),
                          subtitle: Text('${record.checkInTime} • ${record.assignedSite} • ${record.distanceMeters} m'),
                          trailing: StatusChip(label: record.status.name, color: _statusColor(record.status)),
                          onTap: () => context.go('/attendance/history/${record.id}'),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class AttendanceDetailScreen extends ConsumerWidget {
  const AttendanceDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(attendanceApiProvider).detail(id),
      builder: (context, snapshot) {
        final record = snapshot.data;
        return AppScaffold(
          title: 'Attendance Detail',
          children: [
            if (record == null) const LoadingSkeleton(lines: 5),
            if (record != null) ...[
              MetricCard(title: 'Date', value: DateFormat.yMMMd().format(record.date), icon: Icons.event),
              MetricCard(title: 'Check-in', value: record.checkInTime, icon: Icons.access_time),
              MetricCard(title: 'Assigned site', value: record.assignedSite, icon: Icons.location_on, subtitle: '${record.distanceMeters} m'),
              MetricCard(title: 'AI checks', value: '${record.faceStatus} / ${record.livenessStatus}', icon: Icons.verified_user, subtitle: 'Location: ${record.locationStatus}'),
              MetricCard(title: 'Sync', value: record.syncStatus.name, icon: Icons.sync, subtitle: record.remarks),
            ],
          ],
        );
      },
    );
  }
}

class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(helpApiProvider).issueTypes(),
      builder: (context, snapshot) {
        final types = snapshot.data ?? [];
        return AppScaffold(
          title: 'Help Center',
          children: [
            if (!snapshot.hasData) const LoadingSkeleton(lines: 6),
            for (final type in types)
              _NavTile(title: type, subtitle: 'Create a support request', route: '/help/create', icon: Icons.help_outline),
          ],
        );
      },
    );
  }
}

class HelpCreateScreen extends ConsumerStatefulWidget {
  const HelpCreateScreen({super.key});

  @override
  ConsumerState<HelpCreateScreen> createState() => _HelpCreateScreenState();
}

class _HelpCreateScreenState extends ConsumerState<HelpCreateScreen> {
  final description = TextEditingController();
  String issueType = 'Location Error';
  HelpTicket? submitted;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Create Help Request',
      children: [
        DropdownButtonFormField<String>(
          value: issueType,
          items: ['Location Error', 'Face Recognition Failed', 'GPS Problem', 'Camera Problem', 'Other']
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) => setState(() => issueType = value ?? issueType),
          decoration: const InputDecoration(labelText: 'Issue Type'),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: 'Description', controller: description, maxLines: 4),
        const MetricCard(title: 'Context', value: 'Current location and related attendance attempt attached', icon: Icons.attachment),
        PrimaryActionButton(
          label: 'Submit Request',
          icon: Icons.send,
          onPressed: () async {
            final ticket = await ref.read(helpApiProvider).createTicket(issueType: issueType, description: description.text);
            setState(() => submitted = ticket);
          },
        ),
        if (submitted != null)
          MetricCard(title: 'Request Submitted', value: submitted!.id, icon: Icons.check_circle, subtitle: 'Status: ${submitted!.status}'),
      ],
    );
  }
}

class HelpDetailScreen extends StatelessWidget {
  const HelpDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => AppScaffold(title: 'Help $id', children: const [MetricCard(title: 'Status', value: 'Pending', icon: Icons.pending_actions, subtitle: 'Support will review this request.')]);
}

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);
    return AppScaffold(
      title: 'Community',
      children: [
        announcements.when(
          loading: () => const LoadingSkeleton(lines: 4),
          error: (error, stackTrace) => ErrorStateView(message: 'Unable to load announcements', onRetry: () => ref.invalidate(announcementsProvider)),
          data: (items) => items.isEmpty
              ? const EmptyStateView(title: 'No announcements', message: 'Cached announcements will appear here.')
              : Column(
                  children: [
                    for (final item in items)
                      Card(
                        child: ListTile(
                          leading: Icon(item.urgent ? Icons.priority_high : Icons.campaign, color: item.urgent ? AppColors.error : AppColors.primary),
                          title: Text(item.title),
                          subtitle: Text('${item.category} • ${item.pinned ? 'Pinned' : 'Notice'}'),
                          trailing: StatusChip(label: item.acknowledged ? 'Ack' : 'Unread', color: item.acknowledged ? AppColors.success : AppColors.warning),
                          onTap: () => context.go('/community/${item.id}'),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class CommunityDetailScreen extends StatelessWidget {
  const CommunityDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => AppScaffold(title: 'Announcement', children: [MetricCard(title: id, value: 'Safety Update', icon: Icons.campaign, subtitle: 'Attachments, read state, and acknowledgement are tracked through the repository.')]);
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return AppScaffold(
      title: 'Notifications',
      children: [
        notifications.when(
          loading: () => const LoadingSkeleton(lines: 4),
          error: (error, stackTrace) => ErrorStateView(message: 'Unable to load notifications', onRetry: () => ref.invalidate(notificationsProvider)),
          data: (items) => Column(
            children: [
              for (final item in items)
                Card(child: ListTile(leading: const Icon(Icons.notifications_active), title: Text(item))),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(currentEmployeeProvider);
    return employee.when(
      loading: () => const AppScaffold(title: 'Profile', children: [LoadingSkeleton(lines: 5)]),
      error: (error, stackTrace) => AppScaffold(title: 'Profile', children: [ErrorStateView(message: 'Unable to load profile', onRetry: () => ref.invalidate(currentEmployeeProvider))]),
      data: (employee) => AppScaffold(
        title: 'Profile',
        children: [
          MetricCard(title: 'Personal Information', value: employee.name, icon: Icons.person, subtitle: '${employee.id} • ${employee.role}'),
          MetricCard(title: 'Department', value: employee.department, icon: Icons.business),
          MetricCard(title: 'Assignment', value: employee.project, icon: Icons.work, subtitle: employee.location),
          MetricCard(title: 'Face Enrollment Status', value: employee.faceEnrolled ? 'Enrolled' : 'Missing', icon: Icons.face),
          MetricCard(title: 'Registered Device', value: employee.deviceRegistered ? 'Registered' : 'Not registered', icon: Icons.phone_android),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ['Account', 'Security', 'Notifications', 'Permissions', 'Offline Data', 'Sync', 'Privacy', 'About'];
    return AppScaffold(
      title: 'Settings',
      children: [
        for (final item in items)
          Card(child: ListTile(title: Text(item), trailing: const Icon(Icons.chevron_right))),
        FilledButton.icon(
          onPressed: () async {
            await ref.read(authApiProvider).logout();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.title, required this.subtitle, required this.route, required this.icon});
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(route),
        ),
      );
}

Color _statusColor(AttendanceStatus status) {
  return switch (status) {
    AttendanceStatus.present => AppColors.success,
    AttendanceStatus.late || AttendanceStatus.pendingReview || AttendanceStatus.pendingSync => AppColors.warning,
    AttendanceStatus.locationError || AttendanceStatus.faceFailed || AttendanceStatus.absent => AppColors.error,
    _ => AppColors.secondary,
  };
}

