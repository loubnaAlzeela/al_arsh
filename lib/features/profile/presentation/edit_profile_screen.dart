import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/locale_provider.dart';
import '../../../main.dart';
import '../../../shared/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  File? _newAvatar;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).valueOrNull;
    _displayNameController.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
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
      setState(() => _newAvatar = File(picked.path));
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final s = ref.read(appL10nProvider);
    try {
      String? newAvatarUrl;
      final userId = supabase.auth.currentSession!.user.id;

      if (_newAvatar != null) {
        final ext = _newAvatar!.path.split('.').last;
        final path = '$userId/avatar.$ext';
        await supabase.storage.from('avatars').upload(
          path, _newAvatar!,
          fileOptions: const FileOptions(upsert: true),
        );
        newAvatarUrl = supabase.storage.from('avatars').getPublicUrl(path);
      }

      await ref.read(currentUserProvider.notifier).updateProfile(
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        avatarUrl: newAvatarUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.saveChanges)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.genericError}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final s = ref.watch(appL10nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.editProfile),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : Text(s.saveChanges,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.surface,
                    backgroundImage: _newAvatar != null
                        ? FileImage(_newAvatar!)
                        : user?.avatarUrl != null
                            ? NetworkImage(user!.avatarUrl!) as ImageProvider
                            : null,
                    child: _newAvatar == null && user?.avatarUrl == null
                        ? const Icon(Icons.person, size: 56, color: AppColors.textHint)
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _displayNameController,
              decoration: InputDecoration(labelText: s.displayNameLabel),
            ),
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 16),
            
            // Settings Area
            ListTile(
              leading: Icon(
                ref.watch(themeNotifierProvider) == ThemeMode.dark 
                    ? Icons.light_mode 
                    : Icons.dark_mode,
                color: AppColors.primary,
              ),
              title: Text(s.isArabic ? 'تغيير المظهر' : 'Change Theme'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ref.read(themeNotifierProvider.notifier).toggleTheme();
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: AppColors.primary),
              title: Text(s.isArabic ? 'تغيير اللغة (English)' : 'Change Language (AR)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ref.read(localeProvider.notifier).toggle();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(s.isArabic ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(color: Colors.redAccent)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
              onTap: () async {
                await supabase.auth.signOut();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
