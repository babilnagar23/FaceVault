import 'package:go_router/go_router.dart';

import '../../features/app_shell/mobile_screens.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/onboarding/permissions', builder: (context, state) => const PermissionsScreen()),
    GoRoute(path: '/onboarding/device', builder: (context, state) => const DeviceRegistrationScreen()),
    GoRoute(path: '/onboarding/face', builder: (context, state) => const FaceEnrollmentScreen()),
    GoRoute(path: '/onboarding/success', builder: (context, state) => const RegistrationSuccessScreen()),
    GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
    GoRoute(path: '/attendance', builder: (context, state) => const AttendanceScreen()),
    GoRoute(path: '/attendance/today', builder: (context, state) => const TodayAttendanceScreen()),
    GoRoute(path: '/attendance/history', builder: (context, state) => const AttendanceHistoryScreen()),
    GoRoute(path: '/attendance/history/:id', builder: (context, state) => AttendanceDetailScreen(id: state.pathParameters['id']!)),
    GoRoute(path: '/help', builder: (context, state) => const HelpCenterScreen()),
    GoRoute(path: '/help/create', builder: (context, state) => const HelpCreateScreen()),
    GoRoute(path: '/help/:id', builder: (context, state) => HelpDetailScreen(id: state.pathParameters['id']!)),
    GoRoute(path: '/community', builder: (context, state) => const CommunityScreen()),
    GoRoute(path: '/community/:id', builder: (context, state) => CommunityDetailScreen(id: state.pathParameters['id']!)),
    GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
  ],
);

