import 'package:flutter_test/flutter_test.dart';
import 'package:shipeast_driver/driver_constants.dart';

/// The driver app's `Money` is the original the customer app's copy was ported
/// from (P3-06), yet nothing pinned its behaviour until now. Both apps render
/// the same order — a driver seeing a different figure from the customer on
/// the same delivery is a support call, or a dispute.
///
/// Mirrors `customer_app/test/utils/money_test.dart`. If the two files ever
/// disagree, the two apps disagree.
void main() {
  group('Money.plain', () {
    test('groups every thousands boundary, not just the first', () {
      // The bug this formatter exists to avoid: a single separator, so
      // 1234567 renders as "1234,567".
      expect(Money.plain(1234567), '1,234,567');
      expect(Money.plain(999), '999');
      expect(Money.plain(1000), '1,000');
      expect(Money.plain(1000000), '1,000,000');
    });

    test('rounds to whole units — money is stored as integers', () {
      expect(Money.plain(12345.6), '12,346');
      expect(Money.plain(12345.4), '12,345');
    });

    test('a null amount is zero, not a crash or an empty string', () {
      expect(Money.plain(null), '0');
    });

    test('keeps the sign on a negative amount', () {
      expect(Money.plain(-1234567), '-1,234,567');
    });
  });

  group('Money.format', () {
    test('prefixes the currency symbol', () {
      expect(Money.format(250), r'$250');
      expect(Money.format(1234567), r'$1,234,567');
    });

    test('carries no currency prefix beyond the symbol', () {
      // The 'J$' prefix was removed deliberately. Pinning its absence in both
      // apps means a revert in either one fails here rather than shipping.
      expect(Money.format(250).startsWith(r'J$'), isFalse);
      expect(Money.symbol, r'$');
    });
  });
}
