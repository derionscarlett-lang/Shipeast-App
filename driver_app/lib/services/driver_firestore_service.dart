import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/order_status.dart';

class DriverFirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> setDriverOnline(String uid, bool isOnline) =>
      _db.collection('drivers').doc(uid).set(
        {'isOnline': isOnline},
        SetOptions(merge: true),
      );

  static Stream<DocumentSnapshot<Map<String, dynamic>>> driverStream(
          String uid) =>
      _db.collection('drivers').doc(uid).snapshots();

  static Future<Map<String, dynamic>?> getDriverData(String uid) async {
    final doc = await _db.collection('drivers').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  static Stream<List<Map<String, dynamic>>> pendingOrdersStream() =>
      _db
          .collection('orders')
          .where('status', isEqualTo: OrderStatus.pending)
          .where('driverId', isNull: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
              .toList());

  /// Stream of the driver's current active order.
  ///
  /// Covers every state in which a driver holds the order. This previously
  /// listed only confirmed and picked_up, so the moment an order moved to
  /// in_transit it dropped out of this query and the driver's dashboard
  /// blanked mid-delivery — with the goods already in their vehicle and no
  /// recovery path in the UI.
  static Stream<List<Map<String, dynamic>>> activeOrderStream(String uid) =>
      _db
          .collection('orders')
          .where('driverId', isEqualTo: uid)
          .where('status', whereIn: OrderStatus.driverHeld)
          .snapshots()
          .map((s) => s.docs
              .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
              .toList());

  /// Thrown when another driver won the race for an order.
  static const String orderTakenCode = 'order-already-taken';

  /// Claims an order for [driverUid].
  ///
  /// Runs in a transaction that aborts if the order already has a driver or has
  /// moved off `pending` — two drivers tapping Accept at the same instant would
  /// otherwise both succeed with a blind `update()`, and the second write would
  /// silently steal the first driver's order.
  ///
  /// Throws [StateError] with [orderTakenCode] when the claim is lost.
  static Future<void> acceptOrder(String orderId, String driverUid) async {
    String driverName = '';
    String driverPhone = '';
    try {
      final doc = await _db.collection('drivers').doc(driverUid).get();
      if (doc.exists) {
        driverName = doc.data()?['name'] as String? ?? '';
        driverPhone = doc.data()?['phone'] as String? ?? '';
      }
    } catch (_) {}

    await _db.runTransaction((tx) async {
      final ref = _db.collection('orders').doc(orderId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError(orderTakenCode);

      final data = snap.data() ?? const <String, dynamic>{};
      final existingDriver = data['driverId'];
      final status = data['status'] as String? ?? OrderStatus.pending;
      final claimed = existingDriver != null &&
          (existingDriver as String).isNotEmpty &&
          existingDriver != driverUid;
      if (claimed || status != OrderStatus.pending) {
        throw StateError(orderTakenCode);
      }

      tx.update(ref, {
        'driverId': driverUid,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'status': OrderStatus.confirmed,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> confirmPickup(String orderId) =>
      _db.collection('orders').doc(orderId).update({
        'status': OrderStatus.pickedUp,
        'pickedUpAt': FieldValue.serverTimestamp(),
      });

  /// Marks the driver as en route to the customer.
  ///
  /// This state has never existed in the data. It is what makes the customer's
  /// "On the Way" tracker step reachable — before this, the customer jumped
  /// from "Picked Up" straight to "Delivered" with no signal that the driver
  /// had actually set off.
  static Future<void> startTransit(String orderId) =>
      _db.collection('orders').doc(orderId).update({
        'status': OrderStatus.inTransit,
        'inTransitAt': FieldValue.serverTimestamp(),
      });

  static Future<String> uploadDeliveryPhoto(String orderId, File file) async {
    final ref =
        FirebaseStorage.instance.ref('orders/$orderId/delivery_photo.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Confirms delivery via the server and returns the authoritative commission.
  ///
  /// P3-04. This used to be a client-side batch that computed the commission on
  /// this device and wrote it straight into the driver's own earnings field —
  /// a driver could pay themselves anything. Worse, it took `orderTotal` as a
  /// parameter from the caller instead of reading it from the order, so even an
  /// honest client paid the wrong amount whenever its cached total was stale.
  ///
  /// The function recomputes from the order's stored `total` using the server's
  /// rate. [DriverPay.commissionOn] survives for on-screen estimates only.
  static Future<int> confirmDelivery(
    String orderId, {
    String? photoUrl,
    String? note,
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('confirmDelivery');
    final result = await callable.call<Map<String, dynamic>>({
      'orderId': orderId,
      if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return (result.data['commission'] as num?)?.toInt() ?? 0;
  }

  static Future<String> uploadProfilePhoto(String uid, File file) async {
    final ref = FirebaseStorage.instance.ref('drivers/$uid/avatar.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  static Stream<List<Map<String, dynamic>>> driverOrderHistoryStream(
          String uid) =>
      _db
          .collection('orders')
          .where('driverId', isEqualTo: uid)
          .snapshots()
          .map((s) {
        final docs = s.docs
            .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
            .toList();
        docs.sort((a, b) {
          final at = (a['createdAt'] as Timestamp?)?.toDate() ??
              (a['deliveredAt'] as Timestamp?)?.toDate() ??
              DateTime(0);
          final bt = (b['createdAt'] as Timestamp?)?.toDate() ??
              (b['deliveredAt'] as Timestamp?)?.toDate() ??
              DateTime(0);
          return bt.compareTo(at);
        });
        return docs;
      });

  static Future<void> saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _db.collection('drivers').doc(uid).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
      }
    } catch (_) {}
  }

  static String get currentUid =>
      FirebaseAuth.instance.currentUser?.uid ?? '';
}
