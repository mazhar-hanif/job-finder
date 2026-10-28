import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/router/navigation_helpers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/outline_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/job_providers.dart';

enum _AccountRole { applicant, employer }

/// Sign-in and self-service applicant or employer registration.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.nextLocation,
    this.startWithSignIn = false,
  });

  final String? nextLocation;
  final bool startWithSignIn;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = true;
  bool _isLoading = false;
  bool _showPassword = false;
  _AccountRole _role = _AccountRole.applicant;
  String? _error;
  String? _notice;
  StreamSubscription<AuthState>? _authSubscription;
  bool _routingSession = false;

  @override
  void initState() {
    super.initState();
    _isSignUp = !widget.startWithSignIn;
    _authSubscription = SupabaseConfig.clientOrNull?.auth.onAuthStateChange
        .listen((state) {
          if (state.session != null) unawaited(_routeActiveSession());
        });
    WidgetsBinding.instance.addPostFrameCallback((_) => _routeActiveSession());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      setState(() {
        _error =
            'Supabase is not configured. Follow the project setup steps in README.md.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _notice = null;
    });

    try {
      if (_isSignUp) {
        final response = await client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          emailRedirectTo: 'com.jobfinder.finderjob://auth/auth',
          data: {'full_name': _nameController.text.trim(), 'role': _role.name},
        );
        if (response.session == null) {
          setState(() {
            _notice =
                'Account created. Check your email to verify and sign in.';
          });
          return;
        }
        _openRoleHome(_role.name);
      } else {
        await client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        final profile = await client
            .from('profiles')
            .select('role')
            .eq('id', client.auth.currentUser!.id)
            .single();
        _openRoleHome(profile['role'] as String);
      }
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } on PostgrestException catch (error) {
      setState(() => _error = 'Could not load your account: ${error.message}');
    } on Exception catch (error) {
      setState(() => _error = 'Unable to complete account request: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _routeActiveSession() async {
    if (_routingSession) return;
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    final user = client.auth.currentUser;
    if (user == null) return;
    _routingSession = true;
    try {
      final profile = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      if (mounted) _openRoleHome(profile['role'] as String);
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not load your account: $error');
      }
    } finally {
      _routingSession = false;
    }
  }

  void _openRoleHome(String role) {
    if (!mounted) return;
    if (role == 'employer') {
      context.go('/employer');
    } else if (widget.nextLocation?.startsWith('/apply/') ?? false) {
      context.go(widget.nextLocation!);
    } else {
      context.go('/home');
    }
  }

  Future<void> _sendPasswordReset() async {
    final client = ref.read(supabaseClientProvider);
    final email = _emailController.text.trim();
    if (client == null) {
      setState(() => _error = 'Supabase is not configured.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    setState(() {
      _error = null;
      _notice = null;
    });
    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.jobfinder.finderjob://auth/reset',
      );
      setState(
        () => _notice = 'Password reset instructions have been emailed.',
      );
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } on Exception catch (error) {
      setState(() => _error = 'Could not send reset email: $error');
    }
  }

  void _switchAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _error = null;
      _notice = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.xs,
            AppSpacing.screenGutter,
            AppSpacing.xxl,
          ),
          children: [
            Row(
              children: [
                IconCircleButton(
                  icon: Icons.arrow_back_rounded,
                  semanticLabel: 'Back',
                  onPressed: () => goBackOrHome(context),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _isSignUp ? 'Create account' : 'Welcome back',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                border: Border.all(color: AppColors.brand100),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      _isSignUp
                          ? Icons.person_add_alt_1_rounded
                          : Icons.lock_open_rounded,
                      color: AppColors.surface,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSignUp
                              ? 'Your next step starts here'
                              : 'Welcome back to JobFinder',
                          style: AppTypography.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          _isSignUp
                              ? 'Create an account to apply or hire.'
                              : 'Sign in to continue to your account.',
                          style: AppTypography.textTheme.bodyMedium!.copyWith(
                            color: AppColors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: AppSpacing.shadowBlur,
                    offset: Offset(0, AppSpacing.shadowOffsetY),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isSignUp) ...[
                        Text(
                          'I am joining as',
                          style: AppTypography.textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          children: [
                            AppChip(
                              label: 'Job seeker',
                              active: _role == _AccountRole.applicant,
                              onTap: () => setState(
                                () => _role = _AccountRole.applicant,
                              ),
                            ),
                            AppChip(
                              label: 'Employer',
                              active: _role == _AccountRole.employer,
                              onTap: () =>
                                  setState(() => _role = _AccountRole.employer),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (value) =>
                              value == null || value.trim().length < 2
                              ? 'Enter your name.'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) =>
                            value == null ||
                                !RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(value.trim())
                            ? 'Enter a valid email.'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        autofillHints: _isSignUp
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        textInputAction: _isSignUp
                            ? TextInputAction.next
                            : TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _showPassword
                                ? 'Hide password'
                                : 'Show password',
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.length < 8
                            ? 'Use at least 8 characters.'
                            : null,
                      ),
                      if (_isSignUp) ...[
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_showPassword,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          validator: (value) =>
                              value != _passwordController.text
                              ? 'Passwords do not match.'
                              : null,
                        ),
                      ],
                      if (!_isSignUp)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _sendPasswordReset,
                            child: const Text('Forgot password?'),
                          ),
                        ),
                    ],
                  ),
                ),
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
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: _isLoading
                    ? 'Please wait...'
                    : _isSignUp
                    ? 'Create account'
                    : 'Sign in',
                disabled: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
            ),
            if (!SupabaseConfig.isConfigured) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.brand50,
                  border: Border.all(color: AppColors.brand100),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  'Account access needs Supabase configuration. You can still '
                  'explore the app using demo mode below.',
                  style: AppTypography.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Explore the app',
                style: AppTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Explore as job seeker',
                  leading: const Icon(
                    Icons.person_search_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => context.go('/home'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlineButton(
                  label: 'Explore as employer',
                  leading: const Icon(
                    Icons.business_center_rounded,
                    color: AppColors.brand500,
                  ),
                  onPressed: () => context.go('/employer'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _isSignUp
                        ? 'Already have an account? '
                        : 'New to JobFinder? ',
                    style: AppTypography.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _switchAuthMode,
                    child: Text(
                      _isSignUp ? 'Sign in' : 'Create account',
                      style: AppTypography.textTheme.labelLarge!.copyWith(
                        color: AppColors.brand500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
