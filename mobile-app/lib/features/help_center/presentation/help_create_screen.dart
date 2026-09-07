import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class HelpCreateScreen extends ConsumerStatefulWidget {
  const HelpCreateScreen({super.key, required this.issueType});

  final String issueType;

  @override
  ConsumerState<HelpCreateScreen> createState() => _HelpCreateScreenState();
}

class _HelpCreateScreenState extends ConsumerState<HelpCreateScreen> {
  late String _selectedType;
  final _descCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.issueType;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please describe the issue before submitting.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final ticket = await ref.read(helpApiProvider).createTicket(
          issueType: _selectedType,
          description: _descCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    ref.invalidate(myHelpTicketsProvider);
    // Navigate to the ticket detail
    context.go('/help/${ticket.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Report Issue'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const Text(
                    'Describe Your Issue',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Issue type
                  FutureBuilder<List<String>>(
                    future: ref.read(helpApiProvider).issueTypes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Issue Type',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedType,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            items: snapshot.data!
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedType = v ?? _selectedType),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Describe the issue in detail. Include what you were doing when the issue occurred.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: const BorderSide(color: AppColors.borderSubtle),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Auto-attached info
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.attach_file, color: AppColors.primary, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Auto-attached Information',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        _AttachmentItem(label: 'Current GPS coordinates'),
                        _AttachmentItem(label: 'Last attendance attempt log'),
                        _AttachmentItem(label: 'Device diagnostics'),
                        _AttachmentItem(label: 'App version & OS'),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorSurface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: PrimaryActionButton(
                label: 'Submit Ticket',
                icon: Icons.send_outlined,
                loading: _loading,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  const _AttachmentItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check, color: AppColors.success, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.onSurface)),
        ],
      ),
    );
  }
}
