import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../data/gifts_repository.dart';

// ── Constants ────────────────────────────────────────────────────────────────
/// How many crowns equal 1 USD
const double _crownsPerUsd = 1000.0;
const int _minimumCrowns = 5000; // minimum 5 USD equivalent

// ── Payment Method ──────────────────────────────────────────────────────────
class _PaymentMethod {
  final String id;
  final String label;
  final String hint;
  final IconData icon;

  const _PaymentMethod({
    required this.id,
    required this.label,
    required this.hint,
    required this.icon,
  });
}

const _paymentMethods = [
  _PaymentMethod(
    id: 'vodafone_cash',
    label: 'فودافون كاش',
    hint: 'رقم الهاتف (01xxxxxxxxx)',
    icon: Icons.phone_android,
  ),
  _PaymentMethod(
    id: 'instapay',
    label: 'إنستاباي',
    hint: 'اسم المستخدم أو الرقم',
    icon: Icons.flash_on,
  ),
  _PaymentMethod(
    id: 'paypal',
    label: 'PayPal',
    hint: 'البريد الإلكتروني',
    icon: Icons.account_balance_wallet,
  ),
  _PaymentMethod(
    id: 'bank',
    label: 'تحويل بنكي',
    hint: 'رقم الحساب / IBAN',
    icon: Icons.account_balance,
  ),
];

// ── Sheet ────────────────────────────────────────────────────────────────────
class WithdrawalSheet extends ConsumerStatefulWidget {
  final int availableCrowns;

  const WithdrawalSheet({super.key, required this.availableCrowns});

  static Future<bool?> show(BuildContext context, {required int availableCrowns}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WithdrawalSheet(availableCrowns: availableCrowns),
    );
  }

  @override
  ConsumerState<WithdrawalSheet> createState() => _WithdrawalSheetState();
}

class _WithdrawalSheetState extends ConsumerState<WithdrawalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _detailsCtrl = TextEditingController();
  final _crownsCtrl = TextEditingController();

  String _selectedMethod = _paymentMethods[0].id;
  bool _isLoading = false;
  String? _error;

  int get _crownsEntered => int.tryParse(_crownsCtrl.text.replaceAll(',', '')) ?? 0;
  double get _usdEquivalent => _crownsEntered / _crownsPerUsd;

  _PaymentMethod get _currentMethod =>
      _paymentMethods.firstWhere((m) => m.id == _selectedMethod);

  @override
  void dispose() {
    _detailsCtrl.dispose();
    _crownsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(withdrawalNotifierProvider.notifier).request(
            crownsAmount: _crownsEntered,
            usdAmount: _usdEquivalent,
            paymentMethod: _selectedMethod,
            paymentDetails: _detailsCtrl.text.trim(),
          );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('تم إرسال طلب السحب بنجاح! سيتم مراجعته قريباً.'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.payments_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'طلب سحب الأرباح',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'رصيدك: ${NumberFormat('#,###').format(widget.availableCrowns)} 🎟️',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Min balance warning
          if (widget.availableCrowns < _minimumCrowns)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الحد الأدنى للسحب هو $_minimumCrowns 🎟️ (${(_minimumCrowns / _crownsPerUsd).toStringAsFixed(0)}\$)',
                      style: const TextStyle(color: AppColors.warning, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crowns amount
                  TextFormField(
                    controller: _crownsCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'عدد الأصوات للسحب',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      hintText: 'الحد الأدنى: $_minimumCrowns',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: const Icon(Icons.how_to_vote, color: AppColors.primary),
                      suffixText: '🎟️',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final n = int.tryParse(v?.replaceAll(',', '') ?? '');
                      if (n == null || n < _minimumCrowns) {
                        return 'الحد الأدنى $_minimumCrowns صوت';
                      }
                      if (n > widget.availableCrowns) {
                        return 'لا يمكن تجاوز رصيدك الحالي';
                      }
                      return null;
                    },
                  ),

                  // Live USD preview
                  if (_crownsEntered >= _minimumCrowns)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money, color: AppColors.success, size: 16),
                          Text(
                            'ما يعادل: \$${_usdEquivalent.toStringAsFixed(2)} USD',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Payment method selector
                  const Text(
                    'طريقة الاستلام',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _paymentMethods.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final m = _paymentMethods[i];
                        final selected = m.id == _selectedMethod;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMethod = m.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? AppColors.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  m.icon,
                                  color: selected ? AppColors.primary : AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  m.label,
                                  style: TextStyle(
                                    color: selected ? AppColors.primary : AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment details
                  TextFormField(
                    controller: _detailsCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'تفاصيل الاستلام',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      hintText: _currentMethod.hint,
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      prefixIcon: Icon(_currentMethod.icon, color: AppColors.primary),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'الرجاء إدخال تفاصيل الاستلام';
                      }
                      return null;
                    },
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.accent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppColors.accent, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'إرسال الطلب',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
