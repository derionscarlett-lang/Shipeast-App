/// Shop-and-deliver requests — the vocabulary shared by the customer app and
/// the admin panel.
///
/// ## What this service actually is
///
/// ShipEast is not a courier and nothing is shipped across a border. A person
/// living abroad asks us to shop for their family **inside Jamaica**: we go to
/// a local supermarket or hardware store, buy what they asked for, and deliver
/// it to their relative's door. No carrier, no customs, no freight — a local
/// errand paid for from overseas.
///
/// ## Why it is a request and not an order
///
/// The total depends on which store we use and what the goods cost on the day,
/// so nothing here can quote a price up front, and a screen that took payment
/// for one would be making a promise the business cannot keep. What it *can*
/// honestly do is take a complete, structured request and put it in front of a
/// human who confirms the total and replies. That is what this is: a request
/// for a quote, with a status the admin moves and the customer can see. The
/// customer is told a person will come back to them, and now a person actually
/// can, because the request lands somewhere with a queue behind it.
///
/// Mirrored by `admin_panel/overseas-status.js`. Edit both, or neither.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Where a request is in the handling process. Only an admin moves it.
class OverseasStatus {
  OverseasStatus._();

  /// Submitted, nobody has looked at it.
  static const String submitted = 'new';

  /// An admin has reached out to the customer.
  static const String contacted = 'contacted';

  /// A total has been given and we are waiting on the customer.
  static const String quoted = 'quoted';

  /// Handled and finished — shopped and delivered, or the customer stepped away.
  static const String closed = 'closed';

  /// We cannot do it: item we won't buy, or somewhere we don't deliver.
  static const String declined = 'declined';

  static const List<String> all = <String>[
    submitted,
    contacted,
    quoted,
    closed,
    declined,
  ];

  /// Still somebody's responsibility.
  static const List<String> open = <String>[submitted, contacted, quoted];

  static const List<String> terminal = <String>[closed, declined];

  /// Never lets an unrecognised value through to the UI as a raw slug.
  /// A request with no status is one that was just written — `new`.
  static String of(Object? raw) {
    if (raw is String && all.contains(raw)) return raw;
    return submitted;
  }

  static bool isOpen(Object? raw) => open.contains(of(raw));

  /// Customer-facing wording. Deliberately different from the admin panel's
  /// labels: an operator wants the state name, a customer wants to know what
  /// is happening to their request.
  static String label(Object? raw) {
    switch (of(raw)) {
      case contacted:
        return 'We’ve been in touch';
      case quoted:
        return 'Total sent';
      case closed:
        return 'Closed';
      case declined:
        return 'Not possible';
      default:
        return 'Received';
    }
  }

  /// One line telling the customer what happens next. A bare status word
  /// leaves them guessing whether they are waiting on us or we on them.
  static String explain(Object? raw) {
    switch (of(raw)) {
      case contacted:
        return 'Someone from ShipEast has reached out about this request.';
      case quoted:
        return 'We’ve sent you the total. Reply to that message to go ahead.';
      case closed:
        return 'This request has been handled and closed.';
      case declined:
        return 'We couldn’t take this one on. Check your email for the reason.';
      default:
        return 'We have your request and will get back to you with the total.';
    }
  }
}

/// The kinds of thing people ask us to buy locally. `other` exists because the
/// list is a shortcut, not a gate — a request we cannot categorise is still a
/// request we want.
class OverseasItemCategory {
  OverseasItemCategory._();

  static const List<String> all = <String>[
    'Groceries & food',
    'Household & cleaning',
    'Hardware & building',
    'Baby & childcare',
    'Pharmacy & health',
    'Electronics',
    'Gifts',
    'Other',
  ];
}

/// The 14 parishes of Jamaica. A free-text destination is the difference
/// between a request an operator can route and one they have to phone about.
class JamaicaParish {
  JamaicaParish._();

  static const List<String> all = <String>[
    'Kingston',
    'St. Andrew',
    'St. Thomas',
    'Portland',
    'St. Mary',
    'St. Ann',
    'Trelawny',
    'St. James',
    'Hanover',
    'Westmoreland',
    'St. Elizabeth',
    'Manchester',
    'Clarendon',
    'St. Catherine',
  ];
}

/// Field length caps. Mirrored in firestore.rules — a client that skips the
/// form cannot write a megabyte of prose into the collection.
class OverseasLimits {
  OverseasLimits._();

  static const int shortField = 120;
  static const int address = 400;
  static const int description = 1000;
  static const int notes = 1000;
  static const int email = 320;
}

/// Accepts anything with a local part, an `@`, a dot-bearing domain and no
/// whitespace. Deliberately permissive: an over-strict pattern's only
/// achievement is rejecting a real customer's real address.
bool isPlausibleEmail(String input) {
  final value = input.trim();
  if (value.isEmpty || value.length > OverseasLimits.email) return false;
  if (value.contains(RegExp(r'\s'))) return false;
  return RegExp(r'^[^@]+@[^@]+\.[^@.]+$').hasMatch(value);
}

/// Digits only, ignoring the formatting people type. Seven is the shortest
/// real Jamaican number; the upper bound leaves room for any country code.
bool isPlausiblePhone(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.length >= 7 && digits.length <= 15;
}

/// A filled-in form, before it becomes a document.
///
/// Kept separate from the widget so validation is a pure function with a test
/// suite rather than a pile of `if` statements inside a build method.
class OverseasInquiryDraft {
  final String contactEmail;
  final String contactPhone;
  final String originCountry;
  final String recipientName;
  final String recipientPhone;
  final String recipientAddress;
  final String recipientParish;
  final String itemCategory;
  final String itemDescription;

  /// What the customer is happy to spend, in their own words — "J$10,000",
  /// "US$70", "up to 15k". Free text on purpose: the number is only a
  /// guideline for the shopper, and forcing a single currency on a customer
  /// abroad paying for goods priced locally would reject more than it helps.
  final String budgetRaw;
  final String notes;

  const OverseasInquiryDraft({
    this.contactEmail = '',
    this.contactPhone = '',
    this.originCountry = '',
    this.recipientName = '',
    this.recipientPhone = '',
    this.recipientAddress = '',
    this.recipientParish = '',
    this.itemCategory = '',
    this.itemDescription = '',
    this.budgetRaw = '',
    this.notes = '',
  });

  /// Field key → message, empty when the draft can be submitted.
  ///
  /// Every required field here is one an operator needs before they can pick
  /// up the phone. Nothing is required for tidiness.
  Map<String, String> errors() {
    final e = <String, String>{};

    if (!isPlausibleEmail(contactEmail)) {
      e['contactEmail'] = 'Enter an email address we can reach you at';
    }
    if (!isPlausiblePhone(contactPhone)) {
      e['contactPhone'] = 'Enter a phone number, including the country code';
    }
    if (originCountry.trim().isEmpty) {
      e['originCountry'] = 'Where are you based?';
    }
    if (recipientName.trim().isEmpty) {
      e['recipientName'] = 'Who is receiving this in Jamaica?';
    }
    if (!isPlausiblePhone(recipientPhone)) {
      e['recipientPhone'] = 'A number for the person receiving it';
    }
    // A town alone — "Kingston", "Morant Bay" — is not somewhere a courier can
    // knock. An address names at least two things, so it carries either a
    // number or a comma between street and town. Requiring a number alone
    // would reject the many rural Jamaican addresses that have none, which is
    // the more expensive of the two mistakes; hence either, not both.
    final address = recipientAddress.trim();
    if (address.length < 10 || !address.contains(RegExp(r'[0-9,]'))) {
      e['recipientAddress'] = 'Street and town, e.g. “Top Road, Cedar Valley”';
    }
    if (!JamaicaParish.all.contains(recipientParish)) {
      e['recipientParish'] = 'Choose the parish';
    }
    if (!OverseasItemCategory.all.contains(itemCategory)) {
      e['itemCategory'] = 'Choose what you are buying';
    }
    if (itemDescription.trim().length < 3) {
      // The shopper needs to know exactly what to pick off the shelf.
      e['itemDescription'] = 'List what you’d like us to buy';
    }

    if (itemDescription.trim().length > OverseasLimits.description) {
      e['itemDescription'] = 'Please shorten this a little';
    }
    if (budgetRaw.trim().length > OverseasLimits.shortField) {
      e['budgetRaw'] = 'Please shorten this a little';
    }
    if (notes.trim().length > OverseasLimits.notes) {
      e['notes'] = 'Please shorten this a little';
    }

    return e;
  }

  bool get isValid => errors().isEmpty;

  /// The document body. Admin-only fields (`adminNote`, `handledBy`,
  /// `handledAt`) are absent on purpose: firestore.rules rejects a create that
  /// carries them, so a modified client cannot file a request that already
  /// claims to have been handled.
  Map<String, dynamic> toFirestore({
    required String customerId,
    required String customerName,
  }) {
    final budget = budgetRaw.trim();
    return <String, dynamic>{
      'customerId': customerId,
      'customerName': customerName,
      'contactEmail': contactEmail.trim(),
      'contactPhone': contactPhone.trim(),
      'originCountry': originCountry.trim(),
      'recipientName': recipientName.trim(),
      'recipientPhone': recipientPhone.trim(),
      'recipientAddress': recipientAddress.trim(),
      'recipientParish': recipientParish,
      'itemCategory': itemCategory,
      'itemDescription': itemDescription.trim(),
      // Null, not '' — an omitted budget is "spend what it takes", which the
      // panel shows as "—" rather than an empty string that reads as a blank.
      'budget': budget.isEmpty ? null : budget,
      'notes': notes.trim(),
      'status': OverseasStatus.submitted,
    };
  }
}

/// A request read back from Firestore, for the customer's own list.
class OverseasInquiry {
  final String id;
  final String status;
  final String itemCategory;
  final String recipientName;
  final String recipientParish;
  final DateTime? createdAt;

  const OverseasInquiry({
    required this.id,
    required this.status,
    required this.itemCategory,
    required this.recipientName,
    required this.recipientParish,
    required this.createdAt,
  });

  factory OverseasInquiry.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return OverseasInquiry(
      id: id,
      status: OverseasStatus.of(data['status']),
      itemCategory: (data['itemCategory'] as String?) ?? '—',
      recipientName: (data['recipientName'] as String?) ?? '—',
      recipientParish: (data['recipientParish'] as String?) ?? '',
      // serverTimestamp() resolves after the local write, so a just-submitted
      // request legitimately has no date for a moment.
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  /// Short human handle, matching how orders are referred to elsewhere.
  String get shortId =>
      id.length <= 6 ? id.toUpperCase() : id.substring(0, 6).toUpperCase();
}
