enum BillingSubscribeStatus {
  success,
  pending,
  canceled,
  productNotFound,
  storeUnavailable,
  networkError,
  error,
}

class BillingSubscribeResult {
  const BillingSubscribeResult(this.status, {this.message});

  final BillingSubscribeStatus status;
  final String? message;

  String get userMessage {
    if (message != null && message!.isNotEmpty) return message!;
    switch (status) {
      case BillingSubscribeStatus.success:
        return 'Premium aboneliğin aktif.';
      case BillingSubscribeStatus.pending:
        return 'Ödemen onay bekliyor. Premium, onaylanınca aktif olacak.';
      case BillingSubscribeStatus.canceled:
        return 'Satın alma iptal edildi.';
      case BillingSubscribeStatus.productNotFound:
        return 'Abonelik ürünü bulunamadı. Lütfen daha sonra tekrar dene.';
      case BillingSubscribeStatus.storeUnavailable:
        return 'Google Play şu an kullanılamıyor.';
      case BillingSubscribeStatus.networkError:
        return 'İnternet bağlantısı yok. Lütfen tekrar dene.';
      case BillingSubscribeStatus.error:
        return 'Satın alma tamamlanamadı. Lütfen tekrar dene.';
    }
  }
}
