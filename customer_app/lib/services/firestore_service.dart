import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/order_status.dart';

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
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');

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

  static Future<Map<String, dynamic>?> validatePromoCode(String code) async {
    try {
      final doc = await _db.collection('promoCodes').doc(code.toUpperCase()).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      if (data['active'] != true) return null;
      final expiresAt = data['expiresAt'] as Timestamp?;
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) return null;
      return {'id': doc.id, ...data};
    } catch (_) {
      return null;
    }
  }

  static Future<void> submitRating({
    required String orderId,
    required String driverId,
    required int driverRating,
    required int merchantRating,
    required String comment,
    required List<String> tags,
  }) async {
    if (orderId.isEmpty) return;
    final orderRef = _db.collection('orders').doc(orderId);
    final orderData = {
      'rated': true,
      'driverRating': driverRating,
      'merchantRating': merchantRating,
      'comment': comment,
      'tags': tags,
    };
    if (driverId.isNotEmpty) {
      final driverRef = _db.collection('drivers').doc(driverId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(driverRef);
        if (snap.exists) {
          final data = snap.data()!;
          final newTotal =
              ((data['totalRatings'] as num?)?.toInt() ?? 0) + driverRating;
          final newCount =
              ((data['ratingCount'] as num?)?.toInt() ?? 0) + 1;
          tx.update(driverRef, {
            'totalRatings': newTotal,
            'ratingCount': newCount,
            'averageRating': newTotal / newCount,
          });
        }
        tx.update(orderRef, orderData);
      });
    } else {
      await orderRef.update(orderData);
    }
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
