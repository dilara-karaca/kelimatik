import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/config/billing_config.dart';
import '../../data/services/billing/billing_result.dart';
import '../../data/services/billing/billing_service.dart';
import 'premium_provider.dart';

class BillingCatalogState {
  const BillingCatalogState({
    this.storeAvailable = false,
    this.loadingProducts = false,
    this.products = const {},
  });

  final bool storeAvailable;
  final bool loadingProducts;
  final Map<String, ProductDetails> products;

  String priceOrFallback(String productId, String fallback) =>
      products[productId]?.price ?? fallback;

  BillingCatalogState copyWith({
    bool? storeAvailable,
    bool? loadingProducts,
    Map<String, ProductDetails>? products,
  }) {
    return BillingCatalogState(
      storeAvailable: storeAvailable ?? this.storeAvailable,
      loadingProducts: loadingProducts ?? this.loadingProducts,
      products: products ?? this.products,
    );
  }
}

final billingProvider =
    NotifierProvider<BillingNotifier, BillingCatalogState>(BillingNotifier.new);

class BillingNotifier extends Notifier<BillingCatalogState> {
  BillingService? _service;

  @override
  BillingCatalogState build() {
    final service = BillingService(
      onEntitlementChanged: (isPremium, {required bool fromStore}) {
        if (!fromStore) return;
        unawaited(
          ref.read(premiumProvider.notifier).setPremiumActive(isPremium),
        );
      },
    );
    _service = service;
    service.startListening();
    ref.onDispose(() {
      unawaited(service.dispose());
      _service = null;
    });
    return const BillingCatalogState();
  }

  BillingService get _requireService {
    final service = _service;
    if (service == null) {
      throw StateError('BillingService is not ready');
    }
    return service;
  }

  /// Query products + restore entitlements from Play.
  Future<void> bootstrap() async {
    final service = _requireService;
    await service.restoreEntitlements();
    await service.queryProducts();
    if (!ref.mounted) return;
    state = state.copyWith(
      storeAvailable: service.isStoreAvailable,
      products: service.products,
      loadingProducts: false,
    );
  }

  Future<void> queryProducts() async {
    state = state.copyWith(loadingProducts: true);
    final service = _requireService;
    await service.queryProducts();
    if (!ref.mounted) return;
    state = state.copyWith(
      storeAvailable: service.isStoreAvailable,
      products: service.products,
      loadingProducts: false,
    );
  }

  Future<BillingSubscribeResult> subscribeMonthly() =>
      subscribeProduct(BillingConfig.monthlyProductId);

  Future<BillingSubscribeResult> subscribeYearly() =>
      subscribeProduct(BillingConfig.yearlyProductId);

  Future<BillingSubscribeResult> subscribeProduct(String productId) async {
    final result = await _requireService.subscribe(productId);
    if (!ref.mounted) return result;
    state = state.copyWith(
      storeAvailable: _requireService.isStoreAvailable,
      products: _requireService.products,
    );
    return result;
  }

  Future<bool> openSubscriptionManagement() {
    return _requireService.openSubscriptionManagement();
  }
}
