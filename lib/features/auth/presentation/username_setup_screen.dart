import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../main.dart';
import '../../../shared/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsernameSetupScreen extends ConsumerStatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  ConsumerState<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends ConsumerState<UsernameSetupScreen> {
  final _usernameController  = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _avatarFile;
  bool _isLoading     = false;
  bool _checkingUsername = false;
  bool _usernameAvailable = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

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
        _checkingUsername = false;
      });
    }
  }

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
    final ext = _avatarFile!.path.split('.').last;
    final path = '$userId/avatar.$ext';
    await supabase.storage
        .from('avatars')
        .upload(path, _avatarFile!, fileOptions: const FileOptions(upsert: true));
    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_usernameAvailable) return;

    setState(() => _isLoading = true);
    try {
      final session = supabase.auth.currentSession!;
      final userId  = session.user.id;
      final username = _usernameController.text.trim().toLowerCase();
      final displayName = _displayNameController.text.trim();

      final avatarUrl = await _uploadAvatar(userId);

      await supabase.from('users').insert({
        'id':           userId,
        'username':     username,
        'display_name': displayName.isEmpty ? username : displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'level':       'مجهول',
        'tier':        'blue',
        'created_at':  DateTime.now().toIso8601String(),
      });

      await ref.read(currentUserProvider.notifier).refresh();
      if (!mounted) return;
      context.go(AppRoutes.feed);
    } catch (e) {
      if (!mounted) return;
      final s = ref.read(appL10nProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.genericError}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appL10nProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  s.setupUsername,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Avatar picker
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: AppColors.surface,
                          backgroundImage: _avatarFile != null
                              ? FileImage(_avatarFile!)
                              : null,
                          child: _avatarFile == null
                              ? const Icon(Icons.person, size: 56, color: AppColors.textHint)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
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
                const SizedBox(height: 24),

                // Username field
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _usernameController.text.length >= 3
                            ? Icon(
                                _usernameAvailable ? Icons.check_circle : Icons.cancel,
                                color: _usernameAvailable ? AppColors.success : AppColors.accent,
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

                // Display name field
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: s.displayNameLabel,
                    hintText: s.displayNameHint,
                  ),
                ),
                const SizedBox(height: 40),

                // Create account button
                ElevatedButton(
                  onPressed: _isLoading ? null : _createProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(s.createAccount),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: _isLoading ? null : () => _createProfile(),
                  child: Text(s.skipForNow),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
