enum GiftPackage {
  coffee(
    id: 'coffee',
    productId: 'iap_coffee',
    name: 'فنجان قهوة',
    emoji: '☕',
    crownsCost: 100,
    votesAdded: 3,
    usdPrice: 0.99,
  ),
  flowers(
    id: 'flowers',
    productId: 'iap_flowers',
    name: 'باقة زهور',
    emoji: '💐',
    crownsCost: 500,
    votesAdded: 15,
    usdPrice: 4.99,
  ),
  mic(
    id: 'mic',
    productId: 'iap_mic',
    name: 'ميكروفون ذهبي',
    emoji: '🎤',
    crownsCost: 1000,
    votesAdded: 30,
    usdPrice: 9.99,
  ),
  car(
    id: 'car',
    productId: 'iap_car',
    name: 'سيارة فاخرة',
    emoji: '🏎️',
    crownsCost: 5000,
    votesAdded: 150,
    usdPrice: 49.99,
  );

  final String id;
  final String productId;
  final String name;
  final String emoji;
  final int crownsCost;
  final int votesAdded;
  final double usdPrice;

  const GiftPackage({
    required this.id,
    required this.productId,
    required this.name,
    required this.emoji,
    required this.crownsCost,
    required this.votesAdded,
    required this.usdPrice,
  });

  static GiftPackage? fromId(String id) {
    try {
      return GiftPackage.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
