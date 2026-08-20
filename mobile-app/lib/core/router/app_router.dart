import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/attendance/presentation/attendance_detail_screen.dart';
import '../../features/attendance/presentation/attendance_history_screen.dart';
import '../../features/attendance/presentation/dashboard_screen.dart';
import '../../features/attendance/presentation/today_attendance_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/face_enrollment/presentation/face_enrollment_screen.dart';
import '../../features/help_center/presentation/help_center_screen.dart';
import '../../features/help_center/presentation/help_create_screen.dart';
import '../../features/help_center/presentation/help_detail_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/device_registration_screen.dart';
import '../../features/onboarding/presentation/permissions_screen.dart';
import '../../features/onboarding/presentation/registration_success_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/widgets/facevault_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // ── Pre-auth ──
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // ── Onboarding ──
    GoRoute(
      path: '/onboarding/permissions',
      builder: (context, state) => const PermissionsScreen(),
    ),
    GoRoute(
      path: '/onboarding/device',
      builder: (context, state) => const DeviceRegistrationScreen(),
    ),
    GoRoute(
      path: '/onboarding/face',
      builder: (context, state) => const FaceEnrollmentScreen(),
    ),
    GoRoute(
      path: '/onboarding/success',
      builder: (context, state) => const RegistrationSuccessScreen(),
    ),
    // ── Authenticated shell (bottom nav) ──
    ShellRoute(
      builder: (context, state, child) => FaceVaultShell(
        location: state.fullPath ?? '/dashboard',
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => CommunityDetailScreen(
                announcementId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/alerts',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    // ── Attendance (pushed over shell) ──
    GoRoute(
      path: '/attendance/today',
      builder: (context, state) => const TodayAttendanceScreen(),
    ),
    GoRoute(
      path: '/attendance/history',
      builder: (context, state) => const AttendanceHistoryScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => AttendanceDetailScreen(
            attendanceId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
    // ── Help ──
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpCenterScreen(),
      routes: [
        GoRoute(
          path: 'create',
          builder: (context, state) => HelpCreateScreen(
            issueType: (state.extra as String?) ?? 'Other',
          ),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) => HelpDetailScreen(
            ticketId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
    // ── Settings ──
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
