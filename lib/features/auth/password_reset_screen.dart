import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/job_providers.dart';

/// Completes a password reset opened from a Supabase recovery email.
class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      setState(() => _error = 'Supabase is not configured.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      if (mounted) {
        setState(() => _notice = 'Password updated. You can now sign in.');
      }
    } on Exception catch (error) {
      if (mounted) setState(() => _error = 'Could not update password: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenGutter),
          children: [
            Text(
              'Choose a new password',
              style: AppTypography.textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                    ),
                    validator: (value) => value == null || value.length < 8
                        ? 'Use at least 8 characters.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                    ),
                    validator: (value) => value != _passwordController.text
                        ? 'Passwords do not match.'
                        : null,
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: AppTypography.textTheme.bodyMedium!.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ],
            if (_notice != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _notice!,
                style: AppTypography.textTheme.bodyMedium!.copyWith(
                  color: AppColors.success,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/auth'),
                child: const Text('Go to sign in'),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: _loading ? 'Updating...' : 'Update password',
              disabled: _loading,
              onPressed: _loading ? null : _updatePassword,
            ),
          ],
        ),
      ),
    );
  }
}
