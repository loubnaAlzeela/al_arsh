import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../data/gift_package.dart';
import '../data/iap_service.dart';
import '../data/gifts_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuyCrownsSheet extends ConsumerWidget {
  const BuyCrownsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const BuyCrownsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iapService = ref.watch(iapServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎟️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Text(
                  'شراء أصوات',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'استخدم الأصوات لدعم صناع المحتوى المفضلين لديك',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline,
                    size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'دفع آمن عبر Google Play',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...GiftPackage.values.map(
              (pkg) => _PackageTile(
                package: pkg,
                iapService: iapService,
                onSuccess: (crownsAdded) {
                  // Immediately invalidate providers so UI refreshes
                  final userId = Supabase.instance.client.auth.currentUser?.id;
                  if (userId != null) {
                    ref.invalidate(walletProvider);
                    ref.invalidate(transactionsProvider(userId));
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PackageTile extends StatefulWidget {
  final GiftPackage package;
  final IapService iapService;
  final void Function(int crownsAdded) onSuccess;

  const _PackageTile({
    required this.package,
    required this.iapService,
    required this.onSuccess,
  });

  @override
  State<_PackageTile> createState() => _PackageTileState();
}

class _PackageTileState extends State<_PackageTile> {
  bool _loading = false;

  Future<void> _buy() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      // buyPackage resolves once the purchase is verified server-side
      final crownsAdded = await widget.iapService.buyPackage(widget.package);

      if (!mounted) return;

      // Notify parent to invalidate providers
      widget.onSuccess(crownsAdded);

      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('تمت إضافة $crownsAdded صوت ✔️'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('إلغاء')) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.border : colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.accent.withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
              child: Text(pkg.emoji, style: const TextStyle(fontSize: 24))),
        ),
        title: Text(
          '${pkg.crownsCost} صوت',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          pkg.name,
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w500),
        ),
        trailing: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            : ElevatedButton(
                onPressed: _buy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text('\$${pkg.usdPrice.toStringAsFixed(2)}'),
              ),
      ),
    );
  }
}
