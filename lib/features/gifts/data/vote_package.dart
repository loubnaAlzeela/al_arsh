enum VotePackage {
  votes100(
    id: 'votes_100',
    productId: 'iap_votes_100',
    name: '100 صوت',
    emoji: '🎟️',
    votesAmount: 100,
    usdPrice: 0.99,
  ),
  votes500(
    id: 'votes_500',
    productId: 'iap_votes_500',
    name: '500 صوت',
    emoji: '🎟️',
    votesAmount: 500,
    usdPrice: 4.99,
  ),
  votes1000(
    id: 'votes_1000',
    productId: 'iap_votes_1000',
    name: '1000 صوت',
    emoji: '🎟️',
    votesAmount: 1000,
    usdPrice: 9.99,
  ),
  votes5000(
    id: 'votes_5000',
    productId: 'iap_votes_5000',
    name: '5000 صوت',
    emoji: '🎟️',
    votesAmount: 5000,
    usdPrice: 49.99,
  );

  final String id;
  final String productId;
  final String name;
  final String emoji;
  final int votesAmount;
  final double usdPrice;

  const VotePackage({
    required this.id,
    required this.productId,
    required this.name,
    required this.emoji,
    required this.votesAmount,
    required this.usdPrice,
  });

  static VotePackage? fromId(String id) {
    try {
      return VotePackage.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
