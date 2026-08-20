import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'app_widgets.dart';

/// The persistent bottom navigation shell.
/// All main tabs render inside this widget — navigation state is preserved.
class FaceVaultShell extends StatelessWidget {
  const FaceVaultShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  FaceVaultTab get _currentTab {
    if (location.startsWith('/attendance')) return FaceVaultTab.attendance;
    if (location.startsWith('/community')) return FaceVaultTab.community;
    if (location.startsWith('/alerts')) return FaceVaultTab.alerts;
    if (location.startsWith('/profile')) return FaceVaultTab.profile;
    return FaceVaultTab.home;
  }

  void _onTap(BuildContext context, FaceVaultTab tab) {
    final path = switch (tab) {
      FaceVaultTab.home => '/dashboard',
      FaceVaultTab.attendance => '/attendance/today',
      FaceVaultTab.community => '/community',
      FaceVaultTab.alerts => '/alerts',
      FaceVaultTab.profile => '/profile',
    };
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: FaceVaultNavBar(
        currentTab: _currentTab,
        onTap: (tab) => _onTap(context, tab),
        alertCount: 2,
      ),
    );
  }
}
