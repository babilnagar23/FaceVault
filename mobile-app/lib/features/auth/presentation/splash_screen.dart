import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Run bootstrapping alongside the enter animation
    final hasSession = await ref.read(authApiProvider).hasSession();
    if (!mounted) return;
    // Small minimum display time so logo isn't flash-shown
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    context.go(hasSession ? '/dashboard' : '/login');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleIn,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Shield + face logo
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'FaceVault',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Secure AI Attendance',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _DotLoader(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotLoader extends StatefulWidget {
  const _DotLoader();

  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (index / 3);
            final t = ((_ctrl.value - phase + 1) % 1.0);
            final opacity = t < 0.5 ? (t * 2) : (1 - (t - 0.5) * 2);
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2 + opacity * 0.8),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
