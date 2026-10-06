import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../data/gifts_repository.dart';
import '../data/gift_package.dart';

class ReceivedGiftsWidget extends ConsumerWidget {
  final String userId;
  
  const ReceivedGiftsWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final giftsAsync = ref.watch(giftsHistoryProvider(userId));

    return giftsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (gifts) {
        // Filter only received gifts for this user
        final receivedGifts = gifts.where((g) => g.receiverId == userId).toList();
        
        if (receivedGifts.isEmpty) {
          return const SizedBox.shrink(); // Hide section if no gifts
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'الهدايا المستلمة 🎁',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: receivedGifts.length,
                itemBuilder: (context, index) {
                  final gift = receivedGifts[index];
                  final pkg = GiftPackage.fromId(gift.giftType);
                  
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(pkg?.emoji ?? '🎁', style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(
                          gift.senderName ?? 'مجهول',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeago.format(gift.createdAt, locale: 'ar'),
                          style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
