import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../data/gift_package.dart';
import '../data/gifts_repository.dart';
import 'buy_crowns_sheet.dart';

class GiftSheet extends ConsumerStatefulWidget {
  final String postId;

  const GiftSheet({super.key, required this.postId});

  static void show(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => GiftSheet(postId: postId),
    );
  }

  @override
  ConsumerState<GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends ConsumerState<GiftSheet> {
  GiftPackage? _selectedPackage;

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final sendGiftState = ref.watch(sendGiftNotifierProvider);
    final balance = walletAsync.valueOrNull?.balance ?? 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تصويت للمنشور 🗳️',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  InkWell(
                    onTap: () => BuyCrownsSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Text('🎟️ ', style: TextStyle(fontSize: 14)),
                          Text(
                            '$balance',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.add_circle, color: AppColors.primary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'ادعم هذا المنشور لزيادة فرصه في الفوز بالسباق الأسبوعي!',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              
              // Grid of packages
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: GiftPackage.values.length,
                itemBuilder: (context, index) {
                  final pkg = GiftPackage.values[index];
                  final isSelected = _selectedPackage == pkg;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPackage = pkg),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(pkg.emoji, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            pkg.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pkg.crownsCost} 🎟️',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedPackage == null || sendGiftState.isLoading
                      ? null
                      : () async {
                          if (balance < _selectedPackage!.crownsCost) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('رصيدك غير كافٍ. يرجى شراء أصوات أولاً.')),
                            );
                            return;
                          }

                          await ref.read(sendGiftNotifierProvider.notifier).sendGift(
                                widget.postId,
                                _selectedPackage!,
                              );
                              
                          if (context.mounted && !ref.read(sendGiftNotifierProvider).hasError) {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(context);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('تم التصويت بـ ${_selectedPackage!.name} بنجاح!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('حدث خطأ: ${ref.read(sendGiftNotifierProvider).error}'),
                                backgroundColor: AppColors.accent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: sendGiftState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _selectedPackage == null 
                              ? 'اختر هدية' 
                              : 'تصويت مقابل ${_selectedPackage!.crownsCost} 🎟️',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
