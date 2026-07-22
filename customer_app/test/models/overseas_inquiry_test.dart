import 'package:flutter_test/flutter_test.dart';
import 'package:shipeast_customer/models/overseas_inquiry.dart';

/// The overseas screen was a WebView pointed at two placeholder form URLs this
/// project does not own; it contained zero Firestore writes, so even a form
/// that loaded reached nothing. It is now a real enquiry that an admin works
/// from a queue.
///
/// What is pinned here is the boundary between the two: which requests are
/// complete enough for an operator to price, and what shape the document takes.
/// A request that reaches the panel missing a phone number is a request nobody
/// can answer — which is the defect all over again, one step further along.

/// A draft with everything filled in. Individual tests break one field at a
/// time, so a new required field fails loudly here rather than silently
/// weakening every other case.
OverseasInquiryDraft valid({
  String contactEmail = 'marcia@example.com',
  String contactPhone = '+1 718 555 0134',
  String originCountry = 'Brooklyn, USA',
  String recipientName = 'Delroy Brown',
  String recipientPhone = '876 555 0110',
  String recipientAddress = '14 Bay Street, Morant Bay',
  String recipientParish = 'St. Thomas',
  String itemCategory = 'Food & groceries',
  String itemDescription = '3 tins of ackee, 2 packs of rice',
  String weightKgRaw = '',
  String notes = '',
}) =>
    OverseasInquiryDraft(
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      originCountry: originCountry,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      recipientAddress: recipientAddress,
      recipientParish: recipientParish,
      itemCategory: itemCategory,
      itemDescription: itemDescription,
      weightKgRaw: weightKgRaw,
      notes: notes,
    );

void main() {
  group('OverseasStatus', () {
    test('an unknown or missing status reads as newly submitted', () {
      // A document with no status is one the server has just accepted.
      expect(OverseasStatus.of(null), OverseasStatus.submitted);
      expect(OverseasStatus.of(''), OverseasStatus.submitted);
      expect(OverseasStatus.of('in_progress'), OverseasStatus.submitted);
      expect(OverseasStatus.of(7), OverseasStatus.submitted);
    });

    test('open and terminal together account for every status', () {
      expect(
        {...OverseasStatus.open, ...OverseasStatus.terminal},
        OverseasStatus.all.toSet(),
      );
      // Nothing may be both — the panel counts the open queue by exclusion.
      expect(
        OverseasStatus.open.toSet().intersection(OverseasStatus.terminal.toSet()),
        isEmpty,
      );
    });

    test('a closed or declined enquiry is not still open', () {
      expect(OverseasStatus.isOpen(OverseasStatus.submitted), isTrue);
      expect(OverseasStatus.isOpen(OverseasStatus.quoted), isTrue);
      expect(OverseasStatus.isOpen(OverseasStatus.closed), isFalse);
      expect(OverseasStatus.isOpen(OverseasStatus.declined), isFalse);
    });

    test('every status has a customer label and an explanation', () {
      for (final s in OverseasStatus.all) {
        expect(OverseasStatus.label(s), isNotEmpty, reason: s);
        expect(OverseasStatus.explain(s), isNotEmpty, reason: s);
        // The raw slug never reaches a customer.
        expect(OverseasStatus.label(s), isNot(equals(s)), reason: s);
      }
    });
  });

  group('isPlausibleEmail', () {
    test('accepts ordinary addresses', () {
      for (final email in [
        'a@b.co',
        'marcia.brown@gmail.com',
        'marcia+shipeast@gmail.com',
        'MARCIA@EXAMPLE.COM',
        'user_name@sub.domain.org',
        "o'brien@example.com",
      ]) {
        expect(isPlausibleEmail(email), isTrue, reason: email);
      }
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

    test('trims before judging, and rejects an over-long address', () {
      expect(isPlausibleEmail('  me@example.com  '), isTrue);
      // firestore.rules caps the field at 320 characters; failing here means
      // the customer is told, rather than watching the write fail.
      expect(isPlausibleEmail('${'x' * 320}@example.com'), isFalse);
    });
  });

  group('isPlausiblePhone', () {
    test('ignores the formatting people actually type', () {
      expect(isPlausiblePhone('876-555-0110'), isTrue);
      expect(isPlausiblePhone('(876) 555 0110'), isTrue);
      expect(isPlausiblePhone('+1 718 555 0134'), isTrue);
    });

    test('rejects what nobody can be called on', () {
      expect(isPlausiblePhone(''), isFalse);
      expect(isPlausiblePhone('call me'), isFalse);
      expect(isPlausiblePhone('12345'), isFalse);
      expect(isPlausiblePhone('1' * 16), isFalse);
    });
  });

  group('parseOptionalWeightKg', () {
    test('blank is a legitimate answer', () {
      expect(parseOptionalWeightKg(''), isNull);
      expect(parseOptionalWeightKg('   '), isNull);
    });

    test('accepts a comma decimal, as half the world writes it', () {
      expect(parseOptionalWeightKg('4,5'), 4.5);
      expect(parseOptionalWeightKg('4.5'), 4.5);
      expect(parseOptionalWeightKg(' 12 '), 12);
    });

    test('rejects nonsense and impossible weights', () {
      expect(parseOptionalWeightKg('heavy'), isNull);
      expect(parseOptionalWeightKg('0'), isNull);
      expect(parseOptionalWeightKg('-3'), isNull);
    });
  });

  group('OverseasInquiryDraft.errors', () {
    test('a complete draft submits', () {
      expect(valid().errors(), isEmpty);
      expect(valid().isValid, isTrue);
    });

    test('every contact field an operator needs is required', () {
      expect(valid(contactEmail: 'nope').errors(), contains('contactEmail'));
      expect(valid(contactPhone: '').errors(), contains('contactPhone'));
      expect(valid(originCountry: '  ').errors(), contains('originCountry'));
    });

    test('the delivery end must be reachable', () {
      expect(valid(recipientName: '').errors(), contains('recipientName'));
      expect(valid(recipientPhone: 'ask him').errors(), contains('recipientPhone'));
      // A town name alone is not somewhere a courier can knock.
      expect(valid(recipientAddress: 'Kingston').errors(),
          contains('recipientAddress'));
    });

    test('parish and category must come from the lists, not free text', () {
      // The admin panel groups the queue by these. "St Thomas" and "st. thomas"
      // as separate destinations is how an operator misses one.
      expect(valid(recipientParish: 'St Thomas').errors(),
          contains('recipientParish'));
      expect(valid(recipientParish: '').errors(), contains('recipientParish'));
      expect(valid(itemCategory: 'Barrel').errors(), contains('itemCategory'));
    });

    test('contents must actually be described', () {
      // Customs asks what is in the box; "x" is not a declaration.
      expect(valid(itemDescription: 'x').errors(), contains('itemDescription'));
      expect(valid(itemDescription: '').errors(), contains('itemDescription'));
    });

    test('weight is optional, but junk in it is not accepted silently', () {
      expect(valid(weightKgRaw: '').errors(), isEmpty);
      expect(valid(weightKgRaw: '4.5').errors(), isEmpty);
      // Dropping an unparseable weight would quote a barrel as a letter.
      expect(valid(weightKgRaw: 'heavyish').errors(), contains('weightKgRaw'));
    });

    test('a freight-sized shipment is sent to a human, not through the form', () {
      expect(valid(weightKgRaw: '250').errors(), contains('weightKgRaw'));
      expect(valid(weightKgRaw: '100').errors(), isEmpty);
    });

    test('reports every problem at once', () {
      // One error per submit turns a form into twenty round trips.
      final errors = const OverseasInquiryDraft().errors();
      expect(errors.length, greaterThan(5));
    });
  });

  group('OverseasInquiryDraft.toFirestore', () {
    test('is always created as new, attributed to the caller', () {
      final map = valid().toFirestore(customerId: 'uid-1', customerName: 'Marcia');
      expect(map['customerId'], 'uid-1');
      expect(map['customerName'], 'Marcia');
      expect(map['status'], OverseasStatus.submitted);
    });

    test('carries no admin fields', () {
      // firestore.rules rejects a create carrying these, so a client that
      // invented them would have its write fail outright. Not sending them is
      // the same rule stated on the near side.
      final map = valid().toFirestore(customerId: 'uid-1', customerName: 'M');
      for (final key in ['adminNote', 'handledBy', 'handledAt', 'quotedAmount']) {
        expect(map.containsKey(key), isFalse, reason: key);
      }
    });

    test('trims what people paste, and stores weight as a number', () {
      final map = valid(
        contactEmail: '  marcia@example.com ',
        recipientName: ' Delroy Brown  ',
        weightKgRaw: ' 4,5 ',
      ).toFirestore(customerId: 'uid-1', customerName: 'M');
      expect(map['contactEmail'], 'marcia@example.com');
      expect(map['recipientName'], 'Delroy Brown');
      expect(map['estimatedWeightKg'], 4.5);
    });

    test('an omitted weight is null, not zero', () {
      // Zero is a weight. It would read as "an empty box" on the panel.
      final map = valid().toFirestore(customerId: 'uid-1', customerName: 'M');
      expect(map['estimatedWeightKg'], isNull);
    });
  });

  group('OverseasInquiry.fromMap', () {
    test('survives a document written before any of these fields existed', () {
      final inquiry = OverseasInquiry.fromMap('abc123def', const {});
      expect(inquiry.status, OverseasStatus.submitted);
      expect(inquiry.itemCategory, '—');
      // serverTimestamp() resolves after the local write, so a just-submitted
      // enquiry genuinely has no date for a moment. It must still render.
      expect(inquiry.createdAt, isNull);
    });

    test('shortens the id the way the rest of the app refers to records', () {
      expect(OverseasInquiry.fromMap('abc123def', const {}).shortId, 'ABC123');
      expect(OverseasInquiry.fromMap('ab12', const {}).shortId, 'AB12');
    });
  });
}
