import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/locale_provider.dart';
import '../../../main.dart';
import '../../../shared/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _usernameController    = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey               = GlobalKey<FormState>();

  bool    _isLoading           = false;
  bool    _isLogin             = true;
  bool    _obscurePassword     = true;
  bool    _checkingUsername    = false;
  bool    _usernameAvailable   = true;
  File?   _avatarFile;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  // ── Avatar ──────────────────────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<String?> _uploadAvatar(String userId) async {
    if (_avatarFile == null) return null;
    final ext  = _avatarFile!.path.split('.').last;
    final path = '$userId/avatar.$ext';
    await supabase.storage
        .from('avatars')
        .upload(path, _avatarFile!, fileOptions: const FileOptions(upsert: true));
    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  // ── Username check ──────────────────────────────────────────────────────────
  Future<void> _checkUsername(String value) async {
    if (value.length < 3) return;
    setState(() => _checkingUsername = true);
    final result = await supabase
        .from('users')
        .select('id')
        .eq('username', value.toLowerCase())
        .maybeSingle();
    if (mounted) {
      setState(() {
        _usernameAvailable = result == null;
        _checkingUsername  = false;
      });
    }
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    final s        = ref.read(appL10nProvider);

    try {
      if (_isLogin) {
        // ── Login ──
        final response = await supabase.auth.signInWithPassword(
          email: email, password: password,
        );
        if (!mounted) return;
        if (response.session != null) {
          final user = await supabase
              .from('users')
              .select('id')
              .eq('id', response.session!.user.id)
              .maybeSingle();
          if (!mounted) return;
          context.go(user == null ? AppRoutes.usernameSetup : AppRoutes.feed);
        }
      } else {
        // ── Sign-up (single step) ──
        if (!_usernameAvailable) return;

        final response = await supabase.auth.signUp(
          email: email, password: password,
        );
        if (!mounted) return;

        if (response.session != null) {
          // Account is immediately active → create profile in one shot
          final userId      = response.session!.user.id;
          final username    = _usernameController.text.trim().toLowerCase();
          final displayName = _displayNameController.text.trim();
          final avatarUrl   = await _uploadAvatar(userId);

          await supabase.from('users').insert({
            'id':           userId,
            'username':     username,
            'display_name': displayName.isEmpty ? username : displayName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
            'level':        'مجهول',
            'tier':         'blue',
            'created_at':   DateTime.now().toIso8601String(),
          });

          await ref.read(currentUserProvider.notifier).refresh();
          if (!mounted) return;
          context.go(AppRoutes.feed);
        } else {
          // Email confirmation required
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.emailConfirmMsg)),
          );
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.genericError}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final s        = ref.watch(appL10nProvider);
    final locale   = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // ── Language toggle (top-right) ──
                const Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _LanguageToggle(),
                ),


                const SizedBox(height: 32),

                // ── Logo ──
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/splash_logo.png',
                        width: 100, height: 100, fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Image.asset(
                        'assets/images/splash_text.png',
                        height: 32, fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.appTagline,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Title ──
                Text(
                  _isLogin ? s.login : s.signUp,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // ══ SIGN-UP ONLY: avatar + username + display name ══════════
                if (!_isLogin) ...[
                  // Avatar picker
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.surface,
                            backgroundImage: _avatarFile != null
                                ? FileImage(_avatarFile!) : null,
                            child: _avatarFile == null
                                ? const Icon(Icons.person, size: 48, color: AppColors.textHint)
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _pickAvatar,
                      child: Text(s.addPhoto),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: s.chooseUsername,
                      hintText: s.usernameHint,
                      prefixText: '@  ',
                      prefixStyle: const TextStyle(color: AppColors.primary),
                      suffixIcon: _checkingUsername
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _usernameController.text.length >= 3
                              ? Icon(
                                  _usernameAvailable
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _usernameAvailable
                                      ? AppColors.success
                                      : AppColors.accent,
                                )
                              : null,
                    ),
                    onChanged: (v) {
                      setState(() {});
                      if (v.length >= 3) _checkUsername(v);
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return s.usernameInvalid;
                      if (v.trim().length < 3) return s.usernameTooShort;
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) return s.usernameInvalid;
                      if (!_usernameAvailable) return s.usernameExists;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Display name
                  TextFormField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: s.displayNameLabel,
                      hintText: s.displayNameHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Email ──
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: s.emailHint,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return s.emailRequired;
                    if (!v.contains('@') || !v.contains('.')) return s.emailInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password ──
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: s.passwordHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return s.passwordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Submit button ──
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black,
                          ),
                        )
                      : Text(_isLogin ? s.login : s.signUp),
                ),
                const SizedBox(height: 16),

                // ── Toggle login/signup ──
                TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                    _usernameController.clear();
                    _displayNameController.clear();
                    _avatarFile = null;
                    _usernameAvailable = true;
                  }),
                  child: Text(
                    _isLogin ? s.dontHaveAccount : s.alreadyHaveAccount,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),

                // ── Browse without account ──
                TextButton(
                  onPressed: () => context.go(AppRoutes.feed),
                  child: Text(
                    isArabic ? 'تصفح بدون حساب' : 'Browse without account',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),


                const SizedBox(height: 16),
                Center(
                  child: Text(
                    s.termsText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Language Toggle Widget ─────────────────────────────────────────────────────
class _LanguageToggle extends ConsumerWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale   = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    return GestureDetector(
      onTap: () => ref.read(localeProvider.notifier).toggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isArabic ? '🇬🇧' : '🇸🇦',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              isArabic ? 'EN' : 'AR',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
