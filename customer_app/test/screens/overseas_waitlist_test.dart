import 'package:flutter_test/flutter_test.dart';
import 'package:shipeast_customer/screens/overseas_order_screen.dart';

/// P5-02. The overseas screen was a WebView pointed at two placeholder form
/// URLs this project does not own. It contained zero Firestore writes, so even
/// a form that loaded reached nothing; in practice both URLs fail and the
/// customer is shown "Connection Error".
///
/// It is now a gate with interest capture, and the only pure logic in it is
/// this validator — which stands between a customer's real address and a
/// waitlist entry nobody can act on.
void main() {
  group('isPlausibleEmail', () {
    test('accepts ordinary addresses', () {
      for (final email in [
        'a@b.co',
        'marcia.brown@gmail.com',
        'marcia+shipeast@gmail.com',
        'MARCIA@EXAMPLE.COM',
        'user_name@sub.domain.org',
      ]) {
        expect(isPlausibleEmail(email), isTrue, reason: email);
      }
    });

    test('trims surrounding whitespace before judging', () {
      expect(isPlausibleEmail('  me@example.com  '), isTrue);
    });

    test('rejects addresses that cannot receive mail', () {
      for (final email in [
        '',
        '   ',
        'marcia',
        'marcia@',
        '@example.com',
        'marcia@example',
        'a@b@c.com',
        'marcia example@mail.com',
      ]) {
        expect(isPlausibleEmail(email), isFalse, reason: '"$email"');
      }
    });

    test('rejects an address longer than the rules allow', () {
      // firestore.rules caps `email` at 320 characters; anything longer is
      // rejected server-side, and failing here means the customer is told so
      // rather than watching the write fail.
      expect(isPlausibleEmail('${'x' * 320}@example.com'), isFalse);
    });

    test('is permissive rather than clever', () {
      /* The only thing an over-strict pattern achieves is rejecting a real
         customer's real address. Deliverability is proven by sending, not by a
         regex — so unusual but legal addresses must pass. */
      expect(isPlausibleEmail("o'brien@example.com"), isTrue);
      expect(isPlausibleEmail('a.very-long.name+tag@mail.co.uk'), isTrue);
    });
  });
}
