import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/billing_config.dart';
import 'billing_log.dart';
import 'billing_product_index.dart';
import 'billing_purchase_outcome.dart';
import 'billing_result.dart';
import 'trial_warning.dart';

/// Called when Play confirms (or no longer confirms) a Premium entitlement.
///
/// [fromStore] is true only when the store was reachable and answered.
typedef PremiumEntitlementCallback = void Function(
  bool isPremium, {
  required bool fromStore,
});

/// Google Play Billing wrapper. UI must not call [InAppPurchase] directly.
class BillingService {
  BillingService({
    InAppPurchase? iap,
    required this.onEntitlementChanged,
    this.onYearlyTrialStarted,
  }) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  final PremiumEntitlementCallback onEntitlementChanged;
  final void Function(DateTime trialEndsAt)? onYearlyTrialStarted;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<BillingSubscribeResult>? _purchaseCompleter;
  bool _listening = false;
  bool _storeAvailable = false;
  String? _lastOwnedProductId;
  GooglePlayPurchaseDetails? _activePurchase;

  final Map<String, ProductDetails> _products = {};

  bool get isStoreAvailable => _storeAvailable;

  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  String? localizedPrice(String productId) => _products[productId]?.price;

  /// Subscribe to [purchaseStream] immediately (before first purchase/restore).
  void startListening() {
    if (_listening) return;
    if (kIsWeb || !_isStorePlatform) {
      billingLog('initialize', 'skipped — not a Play/App Store platform');
      return;
    }
    try {
      _listening = true;
      billingLog('initialize', 'purchaseStream listen');
      _purchaseSub = _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (Object error, StackTrace stack) {
          billingLog('purchase error', error.runtimeType.toString());
          debugPrint('Billing: purchaseStream error: $error\n$stack');
          _completePurchase(
            const BillingSubscribeResult(BillingSubscribeStatus.error),
          );
        },
      );
    } catch (e, st) {
      _listening = false;
      billingLog('initialize', 'listen failed');
      debugPrint('Billing: startListening failed: $e\n$st');
    }
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _listening = false;
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      _purchaseCompleter!.complete(
        const BillingSubscribeResult(BillingSubscribeStatus.canceled),
      );
    }
    _purchaseCompleter = null;
  }

  Future<bool> checkStoreAvailable() async {
    try {
      _storeAvailable = await _iap.isAvailable();
      billingLog(
        'initialize',
        _storeAvailable ? 'store available' : 'store unavailable',
      );
      return _storeAvailable;
    } catch (e, st) {
      billingLog('initialize', 'store check failed');
      debugPrint('Billing: isAvailable failed: $e\n$st');
      _storeAvailable = false;
      return false;
    }
  }

  /// Loads monthly/yearly product details from Play.
  Future<BillingSubscribeResult?> queryProducts() async {
    billingLog('product query', 'start');
    if (!await checkStoreAvailable()) {
      billingLog('product query', 'skipped — store unavailable');
      return const BillingSubscribeResult(
        BillingSubscribeStatus.storeUnavailable,
      );
    }

    try {
      final details = <ProductDetails>[];
      final batchError = await _collectProductDetails(
        BillingConfig.premiumProductIds,
        details,
      );
      if (batchError != null && details.isEmpty) return batchError;

      final missing = BillingConfig.premiumProductIds
          .difference(details.map(BillingProductIndex.idOf).toSet());
      for (final id in missing) {
        billingLog('product query', 'retry $id');
        await _collectProductDetails({id}, details);
      }

      _products
        ..clear()
        ..addAll(BillingProductIndex.fromDetails(details));

      final stillMissing = BillingConfig.premiumProductIds
          .where((id) => !_products.containsKey(id))
          .toList();
      if (stillMissing.isNotEmpty) {
        final message = 'not found: ${stillMissing.join(', ')}';
        billingLog('product query', message);
        debugPrint('Billing: product query — $message');
      }
      billingLog(
        'product query',
        'loaded ${_products.length} product(s)',
      );

      if (_products.isEmpty) {
        return const BillingSubscribeResult(
          BillingSubscribeStatus.productNotFound,
        );
      }
      return null;
    } catch (e, st) {
      billingLog('product query', 'exception');
      debugPrint('Billing: queryProductDetails failed: $e\n$st');
      if (_looksLikeNetworkException(e)) {
        return const BillingSubscribeResult(
          BillingSubscribeStatus.networkError,
        );
      }
      return const BillingSubscribeResult(BillingSubscribeStatus.error);
    }
  }

  /// Restores entitlements from Play. Updates Premium only when the store
  /// actually answered ([fromStore] = true).
  ///
  /// Returns true only when this call confirmed an active subscription.
  /// A failed query leaves the previous local flag alone.
  Future<bool> restoreEntitlements() async {
    billingLog('restore', 'start');
    startListening();

    if (!await checkStoreAvailable()) {
      billingLog('restore', 'skipped — store unavailable, cache kept');
      return false;
    }

    var confirmedByStore = false;
    try {
      if (_isAndroid) {
        try {
          final addition = _iap
              .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
          final past = await addition.queryPastPurchases();
          if (past.error != null) {
            billingLog(
              'restore',
              'queryPastPurchases error code=${past.error!.code}',
            );
          } else {
            await _applyPurchases(
              past.pastPurchases,
              fromStore: true,
            );
            confirmedByStore = true;
          }
        } catch (e, st) {
          billingLog('restore', 'queryPastPurchases failed');
          debugPrint('Billing: queryPastPurchases failed: $e\n$st');
        }
      }

      await _iap.restorePurchases();
      billingLog('restore', 'restorePurchases requested');
    } catch (e, st) {
      billingLog('restore', 'failed — cache kept');
      debugPrint('Billing: restore failed: $e\n$st');
    }
    return confirmedByStore && _lastOwnedProductId != null;
  }

  Future<BillingSubscribeResult> subscribe(String productId) async {
    billingLog('purchase started', productId);
    startListening();

    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      return const BillingSubscribeResult(
        BillingSubscribeStatus.error,
        message: 'Bir satın alma zaten devam ediyor.',
      );
    }

    if (!await checkStoreAvailable()) {
      billingLog('purchase error', 'store unavailable');
      return const BillingSubscribeResult(
        BillingSubscribeStatus.storeUnavailable,
      );
    }

    if (!_products.containsKey(productId)) {
      final queryError = await queryProducts();
      if (queryError != null && !_products.containsKey(productId)) {
        return queryError;
      }
    }

    final details = _products[productId];
    if (details == null) {
      billingLog('purchase error', 'product not found: $productId');
      debugPrint('Billing: purchase error — product not found: $productId');
      return const BillingSubscribeResult(
        BillingSubscribeStatus.productNotFound,
      );
    }

    _purchaseCompleter = Completer<BillingSubscribeResult>();

    try {
      final PurchaseParam param;
      if (details is GooglePlayProductDetails) {
        final current = _activePurchase;
        final replacing = current != null && current.productID != productId;
        param = GooglePlayPurchaseParam(
          productDetails: details,
          offerToken: details.offerToken,
          changeSubscriptionParam: replacing
              ? ChangeSubscriptionParam(
                  oldPurchaseDetails: current,
                  replacementMode: ReplacementMode.withTimeProration,
                )
              : null,
        );
      } else {
        param = PurchaseParam(productDetails: details);
      }

      final started = await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        billingLog('purchase error', 'buyNonConsumable returned false');
        _purchaseCompleter = null;
        final owned = await restoreEntitlements();
        if (owned) {
          return const BillingSubscribeResult(BillingSubscribeStatus.success);
        }
        return const BillingSubscribeResult(
          BillingSubscribeStatus.storeUnavailable,
        );
      }
      // ignore: unawaited_return_in_try_block
      return _purchaseCompleter!.future;
    } catch (e, st) {
      billingLog('purchase error', e.runtimeType.toString());
      debugPrint('Billing: buyNonConsumable failed: $e\n$st');
      _purchaseCompleter = null;
      if (_isAlreadyOwnedError(e)) {
        final owned = await restoreEntitlements();
        if (owned) {
          return const BillingSubscribeResult(BillingSubscribeStatus.success);
        }
        return const BillingSubscribeResult(BillingSubscribeStatus.error);
      }
      if (_looksLikeNetworkException(e)) {
        return const BillingSubscribeResult(
          BillingSubscribeStatus.networkError,
        );
      }
      return const BillingSubscribeResult(BillingSubscribeStatus.error);
    }
  }

  Future<bool> openSubscriptionManagement() async {
    final uri = BillingConfig.manageSubscriptionsUri(
      sku: _lastOwnedProductId,
    );
    billingLog('manage subscriptions', uri.path);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
      // ignore: unawaited_return_in_try_block
      return launchUrl(
        BillingConfig.manageSubscriptionsUri(),
        mode: LaunchMode.externalApplication,
      );
    } catch (e, st) {
      billingLog('manage subscriptions', 'failed');
      debugPrint('Billing: open management failed: $e\n$st');
      return false;
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    await _applyPurchases(
      purchases,
      fromStore: true,
      isLiveUpdate: true,
    );
  }

  Future<void> _applyPurchases(
    List<PurchaseDetails> purchases, {
    required bool fromStore,
    bool isLiveUpdate = false,
  }) async {
    billingLog(
      isLiveUpdate ? 'purchaseStream' : 'restore',
      '${purchases.length} update(s)',
    );
    for (final purchase in purchases) {
      final label = purchase.productID.isEmpty ? '(no product)' : purchase.productID;
      billingLog(purchase.status.name, label);
      await _completeIfNeeded(purchase);
    }

    final outcome = interpretPurchaseUpdates(
      purchases,
      isLiveUpdate: isLiveUpdate,
    );
    if (outcome.ownedProductId != null) {
      _rememberOwned(purchases, outcome.ownedProductId!);
      _captureYearlyTrial(purchases);
    } else if (outcome.premiumActive == false) {
      _lastOwnedProductId = null;
      _activePurchase = null;
    }

    if (outcome.premiumActive != null && fromStore) {
      onEntitlementChanged(outcome.premiumActive!, fromStore: true);
      billingLog(
        outcome.premiumActive! ? 'Premium activated' : 'Premium deactivated',
      );
    }
    final status = outcome.subscribeStatus;
    if (status != null) {
      _completePurchase(BillingSubscribeResult(status));
    }
  }

  void _captureYearlyTrial(List<PurchaseDetails> purchases) {
    final callback = onYearlyTrialStarted;
    if (callback == null) return;
    final details = _products[BillingConfig.yearlyProductId];
    if (details == null) return;
    final offer = BillingProductIndex.selectedOffer(details);
    if (offer == null || !BillingProductIndex.hasFreeTrial(offer)) return;

    for (final purchase in purchases) {
      if (purchase.productID != BillingConfig.yearlyProductId) continue;
      if (purchase.status != PurchaseStatus.purchased) continue;
      final millis = int.tryParse(purchase.transactionDate ?? '');
      final started = millis == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(millis);
      callback(TrialWarning.endsAtFromStart(started));
      return;
    }
  }

  void _rememberOwned(List<PurchaseDetails> purchases, String productId) {
    _lastOwnedProductId = productId;
    for (final purchase in purchases.reversed) {
      if (purchase is! GooglePlayPurchaseDetails) continue;
      if (purchase.productID != productId) continue;
      _activePurchase = purchase;
      return;
    }
  }

  void _completePurchase(BillingSubscribeResult result) {
    final completer = _purchaseCompleter;
    if (completer == null || completer.isCompleted) return;
    _purchaseCompleter = null;
    completer.complete(result);
  }

  Future<void> _completeIfNeeded(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    if (purchase.status == PurchaseStatus.pending) return;
    try {
      await _iap.completePurchase(purchase);
    } catch (e, st) {
      billingLog('purchase error', 'completePurchase failed');
      debugPrint('Billing: completePurchase failed: $e\n$st');
    }
  }

  Future<BillingSubscribeResult?> _collectProductDetails(
    Set<String> ids,
    List<ProductDetails> into,
  ) async {
    if (ids.isEmpty) return null;
    if (_isAndroid) {
      return _collectAndroidSubscriptions(ids, into);
    }
    return _collectGenericDetails(ids, into);
  }

  Future<BillingSubscribeResult?> _collectAndroidSubscriptions(
    Set<String> ids,
    List<ProductDetails> into,
  ) async {
    final platform = InAppPurchasePlatform.instance;
    if (platform is! InAppPurchaseAndroidPlatform) {
      return _collectGenericDetails(ids, into);
    }

    final addedBefore = into.length;
    // Shared BillingClient; public queryProductDetails also asks INAPP and can
    // drop subscription results when that call fails.
    // ignore: invalid_use_of_visible_for_testing_member
    final response = await platform.billingClientManager.runWithClient(
      (client) => client.queryProductDetails(
        productList: ids
            .map(
              (id) => ProductWrapper(
                productId: id,
                productType: ProductType.subs,
              ),
            )
            .toList(),
      ),
    );

    final code = response.billingResult.responseCode;
    billingLog(
      'product query',
      'android subs code=$code products=${response.productDetailsList.length}',
    );

    for (final wrapper in response.productDetailsList) {
      final offers = wrapper.subscriptionOfferDetails;
      if (offers == null || offers.isEmpty) {
        billingLog(
          'product query',
          '${wrapper.productId} returned without offers',
        );
        debugPrint(
          'Billing: product query — ${wrapper.productId} has no available offers',
        );
        continue;
      }
      into.addAll(GooglePlayProductDetails.fromProductDetails(wrapper));
    }

    if (response.unfetchedProductList.isNotEmpty) {
      final unfetched = response.unfetchedProductList
          .map((product) => product.productId)
          .join(', ');
      billingLog('product query', 'unfetched: $unfetched');
      debugPrint('Billing: product query — unfetched: $unfetched');
    }

    if (into.length > addedBefore) return null;
    return _hardAndroidQueryError(code);
  }

  Future<BillingSubscribeResult?> _collectGenericDetails(
    Set<String> ids,
    List<ProductDetails> into,
  ) async {
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      billingLog('product query', 'error code=${response.error!.code}');
      if (isNetworkIapError(response.error!)) {
        return const BillingSubscribeResult(
          BillingSubscribeStatus.networkError,
        );
      }
      return BillingSubscribeResult(
        BillingSubscribeStatus.error,
        message: 'Ürün bilgisi alınamadı. Lütfen tekrar dene.',
      );
    }
    into.addAll(response.productDetails);
    if (response.notFoundIDs.isNotEmpty) {
      billingLog(
        'product query',
        'not found: ${response.notFoundIDs.join(', ')}',
      );
    }
    return null;
  }

  BillingSubscribeResult? _hardAndroidQueryError(BillingResponse code) {
    switch (code) {
      case BillingResponse.serviceUnavailable:
      case BillingResponse.serviceTimeout:
      case BillingResponse.networkError:
      case BillingResponse.billingUnavailable:
        return const BillingSubscribeResult(
          BillingSubscribeStatus.networkError,
        );
      case BillingResponse.serviceDisconnected:
        return const BillingSubscribeResult(
          BillingSubscribeStatus.storeUnavailable,
        );
      default:
        return null;
    }
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isStorePlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  bool _looksLikeNetworkException(Object error) {
    final blob = error.toString().toLowerCase();
    return blob.contains('socket') ||
        blob.contains('network') ||
        blob.contains('failed host lookup') ||
        blob.contains('connection');
  }

  bool _isAlreadyOwnedError(Object error) {
    final blob = error.toString().toLowerCase();
    return blob.contains('alreadyowned') ||
        blob.contains('already owned') ||
        blob.contains('item_already_owned');
  }
}
