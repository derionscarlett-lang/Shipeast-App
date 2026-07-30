/// Promo code evaluation, client side (P3-03).
///
/// This is a **preview**. It exists so the discount appears the instant the
/// customer types a code, rather than after a Cloud Function cold start. The
/// number written to the order comes from `redeemPromo`, which runs this same
/// logic on the server against freshly-read state.
///
/// It must stay in step with `functions/src/promo.ts`. The two are mirrored the
/// same way `OrderStatus` is, and for the same reason: there is no shared
/// package yet (P6-04).
///
/// Every rule here was previously absent. Before P3-03 every code discounted
/// exactly J$0 — the customer read `discount` while the admin wrote
/// `discountAmount`, and the customer compared `discountType` against
/// `'percentage'` while the admin wrote `'percent'`. Both sides were wrong in
/// different ways; both are now fixed against SCHEMA.md rather than against
/// each other.
library;

enum PromoRejection {
  notFound,
  inactive,
  expired,
  exhausted,
  belowMinimum,
  malformed,
}

class PromoResult {
  const PromoResult.ok(this.discount)
      : reason = null,
        message = null;

  const PromoResult.rejected(this.reason, this.message) : discount = 0;

  /// Integer JMD. Always `0` when [reason] is non-null.
  final int discount;
  final PromoRejection? reason;
  final String? message;

  bool get isValid => reason == null;
}

abstract final class PromoCodes {
  static const messages = <PromoRejection, String>{
    PromoRejection.notFound: 'That promo code does not exist.',
    PromoRejection.inactive: 'That promo code is no longer available.',
    PromoRejection.expired: 'That promo code has expired.',
    PromoRejection.exhausted: 'That promo code has reached its usage limit.',
    PromoRejection.belowMinimum:
        'Your order is below the minimum for that promo code.',
    PromoRejection.malformed:
        'That promo code is misconfigured. Please contact support.',
  };

  static PromoResult _reject(PromoRejection reason) =>
      PromoResult.rejected(reason, messages[reason]!);

  /// Validates [promo] against [subtotal] and returns the discount to preview.
  ///
  /// [promo] is the raw Firestore document data, or null when no such code
  /// exists. [expiresAt] is read as a `Timestamp`-like value via [now]
  /// comparison; pass [now] explicitly in tests.
  ///
  /// The discount applies to the **subtotal**, not the grand total. Discounting
  /// the delivery and service fees too was never the intent, and would make the
  /// driver's commission depend on the customer's coupon.
  ///
  /// Validation order matches SCHEMA.md:
  /// active → expiresAt → usedCount < maxUses → subtotal >= minOrderTotal
  static PromoResult evaluate(
    Map<String, dynamic>? promo,
    int subtotal,
    DateTime now,
  ) {
    if (promo == null) return _reject(PromoRejection.notFound);
    if (subtotal < 0) return _reject(PromoRejection.malformed);

    final amount = (promo['discountAmount'] as num?)?.toDouble();
    if (amount == null || amount < 0) return _reject(PromoRejection.malformed);

    final type = promo['discountType'] as String?;
    if (type != 'percent' && type != 'fixed') {
      return _reject(PromoRejection.malformed);
    }

    if (promo['active'] != true) return _reject(PromoRejection.inactive);

    final expiresAt = promo['expiresAt'];
    final expiry = expiresAt is DateTime
        ? expiresAt
        : (expiresAt == null ? null : (expiresAt as dynamic).toDate() as DateTime);
    if (expiry != null && !expiry.isAfter(now)) {
      return _reject(PromoRejection.expired);
    }

    final maxUses = (promo['maxUses'] as num?)?.toInt() ?? 0;
    final usedCount = (promo['usedCount'] as num?)?.toInt() ?? 0;
    if (maxUses > 0 && usedCount >= maxUses) {
      return _reject(PromoRejection.exhausted);
    }

    final minimum = (promo['minOrderTotal'] as num?)?.toInt() ?? 0;
    if (subtotal < minimum) return _reject(PromoRejection.belowMinimum);

    int discount;
    if (type == 'percent') {
      // Clamp rather than reject: refusing a live code at checkout would punish
      // the customer for an admin's typo, and a >100% discount would otherwise
      // produce a negative total.
      final pct = amount > 100 ? 100.0 : amount;
      discount = (subtotal * pct / 100).round();

      // The cap is the whole point of maxDiscount: a 100% code with no cap is
      // an unbounded liability, and one extra zero creates it.
      final maxDiscount = (promo['maxDiscount'] as num?)?.toInt();
      if (maxDiscount != null) {
        final cap = maxDiscount < 0 ? 0 : maxDiscount;
        if (discount > cap) discount = cap;
      }
    } else {
      discount = amount.round();
    }

    if (discount > subtotal) discount = subtotal;
    if (discount < 0) discount = 0;

    return PromoResult.ok(discount);
  }
}
