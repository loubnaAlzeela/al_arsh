import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../main.dart';
import '../../../shared/providers/current_week_provider.dart';
import '../../feed/data/feed_repository.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen>
    with WidgetsBindingObserver {
  final _captionController = TextEditingController();
  File? _mediaFile;
  String? _mediaType; // 'video' | 'image'
  String? _selectedCategory; // initialized from l10n in build
  bool _isUploading = false;
  double _uploadProgress = 0;
  VideoPlayerController? _videoController;
  bool _wasPlayingBeforePause = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _wasPlayingBeforePause = _videoController?.value.isPlaying ?? false;
      _videoController?.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPlayingBeforePause) _videoController?.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    final picker = ImagePicker();
    XFile? picked;

    if (isVideo) {
      picked = await picker.pickVideo(source: source, maxDuration: const Duration(seconds: 60));
    } else {
      picked = await picker.pickImage(source: source, imageQuality: 85);
    }

    if (picked == null || !mounted) return;

    final file = File(picked.path);

    if (isVideo) {
      // Check duration first
      final ctrl = VideoPlayerController.file(file);
      try {
        await ctrl.initialize();
      } catch (e) {
        ctrl.dispose();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر تحميل الفيديو: $e')),
        );
        return;
      }
      if (ctrl.value.duration.inSeconds > 60) {
        ctrl.dispose();
        if (!mounted) return;
        final s = ref.read(appL10nProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.videoTooLong)),
        );
        return;
      }
      // Dispose old controller
      _videoController?.dispose();

      if (!mounted) {
        ctrl.dispose();
        return;
      }

      // Update state with the new controller + file together
      setState(() {
        _videoController = ctrl;
        _mediaFile = file;
        _mediaType = 'video';
      });

      ctrl.setLooping(true);
      ctrl.play();
      return; // already set state above
    }

    setState(() {
      _mediaFile = file;
      _mediaType = 'image';
    });
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('اختر نوع المحتوى',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              _MediaOption(
                icon: Icons.videocam,
                label: 'فيديو (حتى 60 ثانية)',
                color: AppColors.accent,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(ImageSource.gallery, isVideo: true);
                },
              ),
              const SizedBox(height: 12),
              _MediaOption(
                icon: Icons.image,
                label: 'صورة',
                color: AppColors.tierBlue,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final s = ref.read(appL10nProvider);
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.chooseMedia)),
      );
      return;
    }

    final week = await ref.read(currentWeekProvider.future);
    if (!mounted) return;
    if (week == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.noActiveWeeks)),
      );
      return;
    }

    if (!week.isActive) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.votingOver)),
      );
      return;
    }

    setState(() { _isUploading = true; _uploadProgress = 0; });

    try {
      final session = supabase.auth.currentSession!;
      final userId  = session.user.id;
      final fileExt = _mediaFile!.path.split('.').last;
      String contentUrl = '';
      String? thumbnailUrl;

      // Upload media (video or image) to Supabase Storage
      setState(() => _uploadProgress = 0.1);
      final extension = fileExt;
      final storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      final contentType = _mediaType == 'video' ? 'video/mp4' : 'image/jpeg';
      
      await supabase.storage.from('posts').upload(
        storagePath,
        _mediaFile!,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );
      
      setState(() => _uploadProgress = 0.7);
      contentUrl = supabase.storage.from('posts').getPublicUrl(storagePath);
      thumbnailUrl = contentUrl;

      // Insert post record
      await supabase.from('posts').insert({
        'user_id':      userId,
        'week_id':      week.id,
        'content_type': _mediaType,
        'content_url':  contentUrl,
        'thumbnail_url': thumbnailUrl,
        'caption':      _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        'category':     _selectedCategory,
        'created_at':   DateTime.now().toIso8601String(),
      });

      setState(() => _uploadProgress = 1.0);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.uploadSuccess)),
      );
      ref.invalidate(feedNotifierProvider);
      context.go('/home/feed');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.uploadFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appL10nProvider);
    // Always store the canonical (Arabic) category value — the DB only
    // accepts the Arabic strings, regardless of the UI locale.
    _selectedCategory ??= AppStrings.categories.first;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.uploadPost),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            )
          else
            TextButton(
              onPressed: _submit,
              child: Text(s.publishPost,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  )),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Media preview / picker
            GestureDetector(
              onTap: _showMediaPicker,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _mediaFile != null ? 240 : 160,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _mediaFile != null ? AppColors.primary : AppColors.border,
                    width: _mediaFile != null ? 2 : 1,
                  ),
                ),
                child: _mediaFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              size: 56, color: AppColors.primary),
                          const SizedBox(height: 12),
                          Text(s.chooseMedia,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              )),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _mediaType == 'video' && _videoController != null
                            ? AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : Image.file(_mediaFile!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Upload progress
            if (_isUploading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_uploadProgress * 100).toInt()}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Category picker
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(
                labelText: s.selectCategory,
                prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
              ),
              items: AppStrings.categories.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(s.translateCategory(cat)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 16),

            // Caption field
            TextField(
              controller: _captionController,
              maxLength: 200,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: s.addCaption,
                hintText: s.captionHint,
                alignLabelWithHint: true,
                counterStyle: const TextStyle(color: AppColors.textHint),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _submit,
              icon: const Icon(Icons.upload),
              label: Text(_isUploading ? s.uploading : s.publishPost),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaOption({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      ),
    ),
  );
}
