import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/order_status.dart';
import '../models/promo_code.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ─── Merchants ───────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> merchantsByCategory(String category) =>
      _db
          .collection('merchants')
          .where('category', isEqualTo: category)
          .snapshots()
          .map((s) =>
              s.docs.map((d) => <String, dynamic>{'id': d.id, ...d.data()}).toList());

  static Stream<List<Map<String, dynamic>>> allMerchantsStream() =>
      _db.collection('merchants').snapshots().map((s) =>
          s.docs.map((d) => <String, dynamic>{'id': d.id, ...d.data()}).toList());

  static Stream<List<Map<String, dynamic>>> menuItemsStream(String merchantId) =>
      _db
          .collection('merchants')
          .doc(merchantId)
          .collection('menuItems')
          .snapshots()
          .map((s) =>
              s.docs.map((d) => <String, dynamic>{'id': d.id, ...d.data()}).toList());

  // ─── Orders ──────────────────────────────────────────────────────────────────

  static Future<String> placeOrder({
    required String merchantId,
    required String merchantName,
    required List<Map<String, dynamic>> items,
    required int subtotal,
    required int deliveryFee,
    required int serviceFee,
    required int total,
    required String paymentMethod,
    required String deliveryAddress,
    int discount = 0,
    String? promoCode,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // P3-02. Before this, a discounted order recorded only the final `total`
    // with no field explaining the gap, so `subtotal + fees != total` on every
    // one of them and nothing could reconcile. Asserting here means a
    // mis-computed total fails loudly at the call site instead of becoming a
    // permanently un-reconcilable order document.
    //
    // Security rules enforce the same equation on create (P2-01), so this is
    // the friendly local copy of a check that is authoritative on the server.
    final expected = subtotal + deliveryFee + serviceFee - discount;
    if (expected != total) {
      throw StateError(
        'Order does not reconcile: subtotal($subtotal) + deliveryFee($deliveryFee) '
        '+ serviceFee($serviceFee) - discount($discount) = $expected, '
        'but total is $total.',
      );
    }

    String customerName = '';
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      customerName = doc.data()?['name'] as String? ?? '';
    } catch (_) {}

    final ref = await _db.collection('orders').add({
      'customerId': user.uid,
      'customerName': customerName,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'items': items
          .map((i) => {
                'name': i['name'],
                'price': i['price'],
                'quantity': i['quantity'],
              })
          .toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'discount': discount,
      'promoCode': promoCode,
      'total': total,
      'paymentMethod': paymentMethod,
      'status': OrderStatus.pending,
      'deliveryAddress': deliveryAddress,
      'createdAt': FieldValue.serverTimestamp(),
      'driverId': null,
      'rated': false,
    });
    return ref.id;
  }

  static Stream<List<Map<String, dynamic>>> orderHistoryStream(String uid) =>
      _db
          .collection('orders')
          .where('customerId', isEqualTo: uid)
          .snapshots()
          .map((s) {
            final docs = s.docs
                .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
                .toList();
            docs.sort((a, b) {
              final at = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              final bt = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              return bt.compareTo(at);
            });
            return docs;
          });

  static Stream<Map<String, dynamic>?> watchOrder(String orderId) =>
      _db
          .collection('orders')
          .doc(orderId)
          .snapshots()
          .map((s) =>
              s.exists ? <String, dynamic>{'id': s.id, ...s.data()!} : null);

  static Stream<Map<String, dynamic>?> watchDriver(String driverId) =>
      _db.collection('drivers').doc(driverId).snapshots().map(
          (s) => s.exists ? <String, dynamic>{'id': s.id, ...s.data()!} : null);

  // ─── Addresses ───────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> addressStream(String uid) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .snapshots()
          .map((s) {
            final docs = s.docs
                .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
                .toList();
            docs.sort((a, b) {
              final at = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              final bt = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              return at.compareTo(bt);
            });
            return docs;
          });

  static Future<List<Map<String, dynamic>>> getAddressesOnce(String uid) async {
    final snap = await _db.collection('users').doc(uid).collection('addresses').get();
    return _sortedAddresses(snap.docs);
  }

  static List<Map<String, dynamic>> _sortedAddresses(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final list =
        docs.map((d) => <String, dynamic>{'id': d.id, ...d.data()}).toList();
    list.sort((a, b) {
      final at = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      final bt = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      return at.compareTo(bt);
    });
    return list;
  }

  static Future<void> addAddress(String uid, String label, String text) =>
      _db.collection('users').doc(uid).collection('addresses').add({
        'label': label,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

  static Future<void> updateAddress(
          String uid, String addressId, String label, String text) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc(addressId)
          .update({'label': label, 'text': text});

  static Future<void> deleteAddress(String uid, String addressId) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc(addressId)
          .delete();

  // ─── User Profile ────────────────────────────────────────────────────────────

  static Stream<Map<String, dynamic>?> watchUserProfile(String uid) =>
      _db.collection('users').doc(uid).snapshots().map((s) =>
          s.exists ? <String, dynamic>{'id': s.id, ...s.data()!} : null);

  // ─── Rating ──────────────────────────────────────────────────────────────────

  /// Previews a promo code without consuming a use (P3-03).
  ///
  /// Advisory only — the discount actually applied to the order comes from
  /// [redeemPromo]. This exists so the customer sees the saving immediately
  /// instead of waiting on a function cold start, and it enforces the full rule
  /// set (expiry, usage cap, minimum) rather than the two checks it used to.
  static Future<PromoResult> previewPromoCode(String code, int subtotal) async {
    try {
      final doc =
          await _db.collection('promoCodes').doc(code.trim().toUpperCase()).get();
      return PromoCodes.evaluate(
        doc.exists ? doc.data() : null,
        subtotal,
        DateTime.now(),
      );
    } catch (_) {
      // A read failure is not the same as a bad code, and must not be reported
      // as one.
      rethrow;
    }
  }

  /// Consumes one use of [code] and returns the authoritative discount.
  ///
  /// Called at order placement, not at code entry — a customer who types a code
  /// and abandons checkout must not burn a use. Throws when the code is
  /// rejected; the message is safe to show.
  static Future<int> redeemPromo(String code, int subtotal) async {
    final callable = FirebaseFunctions.instance.httpsCallable('redeemPromo');
    final result = await callable.call<Map<String, dynamic>>({
      'code': code.trim().toUpperCase(),
      'subtotal': subtotal,
    });
    return (result.data['discount'] as num?)?.toInt() ?? 0;
  }

  /// Submits a rating for a delivered order.
  ///
  /// [merchantRating] is nullable on purpose: an unrated merchant must send
  /// `null`, never a default. The caller used to substitute 5 stars when the
  /// customer skipped that question, which was harmless while nothing counted
  /// merchant ratings and would now silently inflate every merchant's average.
  ///
  /// The driver is read from the order server-side rather than passed in — the
  /// caller does not get to decide who receives the rating.
  static Future<void> submitRating({
    required String orderId,
    required int driverRating,
    int? merchantRating,
    required String comment,
    required List<String> tags,
  }) async {
    if (orderId.isEmpty) return;

    /* P3-05. This used to be a client-side transaction that rolled the rating
       up into the driver document — and dropped `merchantRating` on the floor,
       which is why every merchant showed a permanent 5.0.

       It now goes through a callable, because the aggregate fields are
       server-only under the P2-01 rules: a driver who can write their own
       `averageRating` can award themselves five stars. The same function also
       populates `ratingCounts`, the per-star histogram the admin panel has
       been rendering an empty state for. */
    final callable = FirebaseFunctions.instance.httpsCallable('submitRating');
    await callable.call<Map<String, dynamic>>({
      'orderId': orderId,
      'driverRating': driverRating,
      'merchantRating': merchantRating,
      'comment': comment,
      'tags': tags,
    });
  }

  // ─── Avatar ──────────────────────────────────────────────────────────────────

  static Future<String> uploadAvatar(String uid, File file) async {
    final ref = FirebaseStorage.instance.ref('users/$uid/avatar.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(uid).set(
      {'avatarUrl': url},
      SetOptions(merge: true),
    );
    return url;
  }

  // ─── User Stats ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getUserStats(String uid) async {
    int orderCount = 0;
    double avgRating = 0;
    int savedCount = 0;

    try {
      final ordersSnap = await _db
          .collection('orders')
          .where('customerId', isEqualTo: uid)
          .get();
      orderCount = ordersSnap.docs.length;

      final ratedOrders = ordersSnap.docs
          .where((d) => d.data()['driverRating'] != null)
          .toList();
      if (ratedOrders.isNotEmpty) {
        final total = ratedOrders.fold<int>(
            0, (acc, d) => acc + ((d.data()['driverRating'] as num?)?.toInt() ?? 0));
        avgRating = total / ratedOrders.length;
      }
    } catch (_) {}

    try {
      final addrSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .get();
      savedCount = addrSnap.docs.length;
    } catch (_) {}

    return {
      'orderCount': orderCount,
      'avgRating': avgRating,
      'savedCount': savedCount,
    };
  }

  // ─── Notifications ────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> notificationsStream({String? uid}) =>
      _db.collection('notifications').snapshots().map((s) {
        final docs = s.docs
            .where((d) {
              final t = d.data()['target'] as String? ?? 'all';
              return t == 'all' || t == 'customers' || (uid != null && t == uid);
            })
            .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
            .toList();
        docs.sort((a, b) {
          final at = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final bt = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return bt.compareTo(at);
        });
        return docs;
      });

  static Future<void> markNotificationsRead(String uid) =>
      _db.collection('users').doc(uid).set(
        {'notificationsReadAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

  static Stream<int> unreadNotificationsCountStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().asyncMap((snap) async {
      final readAt = (snap.data()?['notificationsReadAt'] as Timestamp?)?.toDate();
      final notifSnap = await _db.collection('notifications').get();
      final unread = notifSnap.docs.where((d) {
        final target = d.data()['target'] as String? ?? 'all';
        if (target != 'all' && target != 'customers' && target != uid) return false;
        if (readAt == null) return true;
        final ts = (d.data()['createdAt'] as Timestamp?)?.toDate();
        if (ts == null) return false;
        return ts.isAfter(readAt);
      }).length;
      return unread;
    });
  }
}
