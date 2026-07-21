import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/models/store_product.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/billing_service.dart';
import 'package:neon_flap1_game/services/coin_service.dart';
import 'package:neon_flap1_game/widgets/animated_background.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';

/// Coin Shop powered by Google Play Billing. Purchases are consumable coin
/// packs; the balance is credited only after a verified, acknowledged purchase.
class CoinShopScreen extends StatefulWidget {
  const CoinShopScreen({super.key});

  @override
  State<CoinShopScreen> createState() => _CoinShopScreenState();
}

class _CoinShopScreenState extends State<CoinShopScreen> {
  String? _message;

  @override
  void initState() {
    super.initState();
    final billing = sl<BillingService>();
    billing.lastPurchased.addListener(_onPurchased);
  }

  void _onPurchased() {
    final pack = sl<BillingService>().lastPurchased.value;
    if (pack != null) {
      sl<AudioService>().playSfx(Sfx.purchaseSuccess);
      HapticFeedback.mediumImpact();
      if (mounted) {
        setState(() => _message = 'Purchased ${pack.coins} coins!');
        Future.delayed(const Duration(seconds: 2),
            () => mounted ? setState(() => _message = null) : null);
      }
    }
  }

  @override
  void dispose() {
    sl<BillingService>().lastPurchased.removeListener(_onPurchased);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coins = sl<CoinService>();
    final billing = sl<BillingService>();
    return Scaffold(
      body: AnimatedBackground(
        accent: NeonPalette.yellow,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 18),
              const Text('COIN SHOP', style: NeonTextStyle.heading),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: coins,
                builder: (_, __) => Text(
                  'BALANCE: ${coins.coins} COINS',
                  style:
                      NeonTextStyle.label.copyWith(color: NeonPalette.yellow),
                ),
              ),
              const SizedBox(height: 12),
              if (_message case final msg?)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: NeonPalette.green.withOpacity(0.15),
                    border: Border.all(color: NeonPalette.green),
                  ),
                  child: Text(msg,
                      style: NeonTextStyle.label
                          .copyWith(color: NeonPalette.green)),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedBuilder(
                  animation: billing,
                  builder: (_, __) => ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: CoinPack.catalogue.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (c, i) =>
                        _PackRow(pack: CoinPack.catalogue[i]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Payments handled securely by Google Play.',
                style: NeonTextStyle.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              NeonBackButton(
                  label: 'BACK', onPressed: () => Navigator.pop(context)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackRow extends StatelessWidget {
  const _PackRow({required this.pack});
  final CoinPack pack;

  @override
  Widget build(BuildContext context) {
    final billing = sl<BillingService>();
    final themeColors = NeonTheme.colors(context);
    final details = billing.detailsFor(pack.productId);
    final price = details?.price ?? pack.priceLabel;
    final canBuy = billing.available && details != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: themeColors.panel.withOpacity(0.9),
        border: Border.all(color: NeonPalette.yellow.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NeonPalette.yellow.withOpacity(0.2),
              border: Border.all(color: NeonPalette.yellow),
            ),
            child: const Center(
              child: Icon(Icons.circle, color: NeonPalette.yellow, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pack.coins} COINS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NeonTextStyle.heading.copyWith(fontSize: 18),
                ),
                Text(
                  canBuy ? 'Tap to purchase' : 'Store unavailable',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NeonTextStyle.body.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 112,
            child: NeonButton(
              label: price,
              icon: Icons.shopping_cart_checkout_rounded,
              color: NeonPalette.yellow,
              fontSize: 12,
              enabled: canBuy,
              onPressed: () => billing.buy(pack),
            ),
          ),
        ],
      ),
    );
  }
}
