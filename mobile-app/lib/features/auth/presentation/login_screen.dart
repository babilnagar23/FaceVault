import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _employeeId = TextEditingController();
  final _password = TextEditingController();
  bool _rememberDevice = false;
  bool _showPassword = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _employeeId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final id = _employeeId.text.trim();
    final pw = _password.text;
    if (id.isEmpty) {
      setState(() => _error = 'Please enter your Employee ID.');
      return;
    }
    if (pw.isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref.read(authApiProvider).login(id, pw);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!result.authenticated) {
      setState(() => _error = result.message ?? 'Unable to login. Please try again.');
      return;
    }
    context.go(result.firstDeviceLogin ? '/onboarding/permissions' : '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero area ──
              Container(
                height: 200,
                color: AppColors.primary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'FaceVault',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Secure Employee Authentication',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form area ──
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    // Employee ID
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Employee ID',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AppTextField(
                          label: '',
                          controller: _employeeId,
                          hint: 'e.g. EMP-12345',
                          prefix: const Icon(Icons.badge_outlined, color: AppColors.onSurfaceVariant),
                          keyboardType: TextInputType.text,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Password
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AppTextField(
                          label: '',
                          controller: _password,
                          obscureText: !_showPassword,
                          hint: '••••••••',
                          prefix: const Icon(Icons.lock_outline, color: AppColors.onSurfaceVariant),
                          suffix: IconButton(
                            tooltip: _showPassword ? 'Hide password' : 'Show password',
                            icon: Icon(
                              _showPassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.onSurfaceVariant,
                            ),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Remember device + forgot
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberDevice,
                              onChanged: (v) => setState(() => _rememberDevice = v ?? false),
                              activeColor: AppColors.primary,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const Text(
                              'Remember Device',
                              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password reset — contact your administrator.')),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    // Error
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorSurface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: AppColors.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    // Login button
                    PrimaryActionButton(
                      label: 'Login',
                      icon: Icons.login,
                      loading: _loading,
                      onPressed: _login,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Biometric login
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Biometric login available after first device setup.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Biometric Login'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Center(
                      child: Text(
                        'FaceVault v1.0.0 • Enterprise Edition',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
