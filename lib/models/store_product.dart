/// A purchasable coin bundle shown in the Coin Shop.
///
/// [productId] matches a product configured in Google Play Console. During
/// development the billing service is exercised with these ids and Play's test
/// card; they must be mirrored exactly in the Play Console before release.
class CoinPack {
  const CoinPack({
    required this.id,
    required this.productId,
    required this.coins,
    required this.priceLabel,
  });

  final String id;
  final String productId;
  final int coins;
  final String priceLabel;

  /// Default shop catalogue.
  static const List<CoinPack> catalogue = [
    CoinPack(
        id: 'pack_100',
        productId: 'coins_100',
        coins: 100,
        priceLabel: '\$0.99'),
    CoinPack(
        id: 'pack_250',
        productId: 'coins_250',
        coins: 250,
        priceLabel: '\$1.99'),
    CoinPack(
        id: 'pack_500',
        productId: 'coins_500',
        coins: 500,
        priceLabel: '\$3.99'),
    CoinPack(
        id: 'pack_1000',
        productId: 'coins_1000',
        coins: 1000,
        priceLabel: '\$6.99'),
    CoinPack(
        id: 'pack_5000',
        productId: 'coins_5000',
        coins: 5000,
        priceLabel: '\$24.99'),
  ];

  static CoinPack byProductId(String productId) => catalogue.firstWhere(
        (p) => p.productId == productId,
        orElse: () => catalogue.first,
      );
}
