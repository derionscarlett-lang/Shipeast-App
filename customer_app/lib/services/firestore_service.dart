import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ─── Seed ────────────────────────────────────────────────────────────────────

  static Future<void> seedMerchantsIfEmpty() async {
    try {
      final snap = await _db.collection('merchants').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final merchants = <Map<String, dynamic>>[
        // FOOD
        {'name': 'Island Jerk Palace', 'category': 'Food', 'emoji': '🍗', 'rating': 4.8, 'deliveryTime': '25–35 min', 'deliveryFee': 'Free delivery', 'isOpen': true, 'promo': '🔥 Popular', 'address': '15 Harbour Street, Kingston', 'phone': '876-555-0001', 'imageUrl': 'https://images.unsplash.com/photo-1544025162-d76538591398?w=400'},
        {'name': 'Kingston Eats', 'category': 'Food', 'emoji': '🍽️', 'rating': 4.5, 'deliveryTime': '20–30 min', 'deliveryFee': 'J\$100 delivery', 'isOpen': true, 'promo': null, 'address': '45 Constant Spring Rd, Kingston', 'phone': '876-555-0002', 'imageUrl': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400'},
        {'name': "Mama's Kitchen", 'category': 'Food', 'emoji': '🥘', 'rating': 4.7, 'deliveryTime': '30–45 min', 'deliveryFee': 'Free delivery', 'isOpen': true, 'promo': '❤️ Local Fave', 'address': '12 Main Street, Yallahs', 'phone': '876-555-0003', 'imageUrl': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400'},
        {'name': 'Rasta Pasta', 'category': 'Food', 'emoji': '🍝', 'rating': 4.3, 'deliveryTime': '25–40 min', 'deliveryFee': 'J\$150 delivery', 'isOpen': false, 'promo': null, 'address': '7 Orange Street, Kingston', 'phone': '876-555-0004', 'imageUrl': 'https://images.unsplash.com/photo-1555949258-eb67b1ef0ceb?w=400'},
        {'name': 'Seafood Shack', 'category': 'Food', 'emoji': '🦞', 'rating': 4.9, 'deliveryTime': '35–50 min', 'deliveryFee': 'Free delivery', 'isOpen': true, 'promo': '⭐ Top Rated', 'address': '1 Port Royal Street, Kingston', 'phone': '876-555-0005', 'imageUrl': 'https://images.unsplash.com/photo-1559737558-2f5a35f4523b?w=400'},
        // GROCERY
        {'name': 'FreshMart', 'category': 'Grocery', 'emoji': '🛒', 'rating': 4.6, 'deliveryTime': '20–30 min', 'deliveryFee': 'Free delivery', 'isOpen': true, 'promo': null, 'address': '88 Half Way Tree Rd, Kingston', 'phone': '876-555-0010', 'imageUrl': 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400'},
        {'name': 'SaveMore Supermarket', 'category': 'Grocery', 'emoji': '🏪', 'rating': 4.4, 'deliveryTime': '30–45 min', 'deliveryFee': 'J\$150 delivery', 'isOpen': true, 'promo': '💰 Best Value', 'address': '22 Constant Spring Rd, Kingston', 'phone': '876-555-0011', 'imageUrl': 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=400'},
        {'name': 'Green Valley Farms', 'category': 'Grocery', 'emoji': '🥬', 'rating': 4.7, 'deliveryTime': '25–35 min', 'deliveryFee': 'Free delivery', 'isOpen': true, 'promo': '🌿 Organic', 'address': '5 Barbican Rd, Kingston', 'phone': '876-555-0012', 'imageUrl': 'https://images.unsplash.com/photo-1490818387583-1baba5e638af?w=400'},
        {'name': 'Daily Essentials', 'category': 'Grocery', 'emoji': '🧴', 'rating': 4.2, 'deliveryTime': '15–25 min', 'deliveryFee': 'J\$100 delivery', 'isOpen': true, 'promo': null, 'address': '34 Maxfield Ave, Kingston', 'phone': '876-555-0013', 'imageUrl': 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400'},
        {'name': 'Farm Fresh', 'category': 'Grocery', 'emoji': '🥑', 'rating': 4.5, 'deliveryTime': '20–30 min', 'deliveryFee': 'Free delivery', 'isOpen': false, 'promo': null, 'address': '19 Mona Rd, Kingston', 'phone': '876-555-0014', 'imageUrl': 'https://images.unsplash.com/photo-1506617420156-8e4536971650?w=400'},
        // PHARMACY
        {'name': 'PharmaCare Rx', 'category': 'Pharmacy', 'emoji': '💊', 'rating': 4.8, 'deliveryTime': '20–30 min', 'deliveryFee': 'Free delivery', 'isOpen': true, 'promo': '🏥 Certified', 'address': '55 King Street, Kingston', 'phone': '876-555-0020', 'imageUrl': 'https://images.unsplash.com/photo-1585435557343-3b092031a831?w=400'},
        {'name': 'MedPlus Pharmacy', 'category': 'Pharmacy', 'emoji': '🩺', 'rating': 4.5, 'deliveryTime': '25–35 min', 'deliveryFee': 'J\$100 delivery', 'isOpen': true, 'promo': null, 'address': '12 Portmore Pkwy, St. Catherine', 'phone': '876-555-0021', 'imageUrl': 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=400'},
        {'name': 'HealthFirst', 'category': 'Pharmacy', 'emoji': '🌡️', 'rating': 4.6, 'deliveryTime': '15–25 min', 'deliveryFee': 'Free delivery', 'isOpen': true, 'promo': '⚡ Fast', 'address': '3 Dunrobin Ave, Kingston', 'phone': '876-555-0022', 'imageUrl': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400'},
        {'name': 'CityDrug', 'category': 'Pharmacy', 'emoji': '💉', 'rating': 4.3, 'deliveryTime': '30–40 min', 'deliveryFee': 'J\$150 delivery', 'isOpen': false, 'promo': null, 'address': '77 Spanish Town Rd, Kingston', 'phone': '876-555-0023', 'imageUrl': 'https://images.unsplash.com/photo-1563213126-a4273aed2016?w=400'},
        {'name': 'Wellness Plus', 'category': 'Pharmacy', 'emoji': '🌿', 'rating': 4.7, 'deliveryTime': '20–30 min', 'deliveryFee': 'Free delivery', 'isOpen': true, 'promo': null, 'address': '9 Liguanea Ave, Kingston', 'phone': '876-555-0024', 'imageUrl': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=400'},
      ];

      final batch = _db.batch();
      final refsByName = <String, DocumentReference>{};
      for (final m in merchants) {
        final ref = _db.collection('merchants').doc();
        batch.set(ref, m);
        refsByName[m['name'] as String] = ref;
      }
      await batch.commit();
      await _seedMenuItems(refsByName);
    } catch (_) {
      // Silent fail — app still shows placeholder data
    }
  }

  static Future<void> _seedMenuItems(Map<String, DocumentReference> refs) async {
    final menuData = <String, List<Map<String, dynamic>>>{
      'Island Jerk Palace': [
        {'name': 'Full Jerk Chicken', 'description': 'Smoky, slow-cooked with festival & rice', 'price': 1200, 'category': 'mains', 'imageUrl': 'https://images.unsplash.com/photo-1544025162-d76538591398?w=300'},
        {'name': 'Curry Goat Plate', 'description': 'Tender curry goat, white rice & peas', 'price': 1400, 'category': 'mains', 'imageUrl': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=300'},
        {'name': 'Rice & Peas Plate', 'description': 'Jamaican staple — seasoned rice & kidney peas', 'price': 800, 'category': 'mains', 'imageUrl': 'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=300'},
        {'name': 'Festival', 'description': 'Sweet fried dumplings — the perfect side', 'price': 250, 'category': 'sides', 'imageUrl': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=300'},
        {'name': 'Sorrel Punch', 'description': 'Iced, sweet, with ginger kick', 'price': 350, 'category': 'drinks', 'imageUrl': 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=300'},
        {'name': 'Ting Soda', 'description': 'Classic Jamaican grapefruit soda', 'price': 200, 'category': 'drinks', 'imageUrl': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=300'},
      ],
      "Mama's Kitchen": [
        {'name': 'Ackee & Saltfish', 'description': "Jamaica's national dish with fried dumplings", 'price': 950, 'category': 'mains', 'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=300'},
        {'name': 'Brown Stew Chicken', 'description': 'Tender chicken in rich brown gravy', 'price': 1100, 'category': 'mains', 'imageUrl': 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=300'},
        {'name': 'Callaloo & Saltfish', 'description': 'Steamed callaloo with saltfish & peppers', 'price': 750, 'category': 'mains', 'imageUrl': 'https://images.unsplash.com/photo-1564834724105-918b73d1b9e0?w=300'},
        {'name': 'Fried Dumplings', 'description': 'Golden crispy Jamaican dumplings', 'price': 300, 'category': 'sides', 'imageUrl': 'https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=300'},
        {'name': 'Lemonade', 'description': 'Fresh squeezed lemonade with mint', 'price': 300, 'category': 'drinks', 'imageUrl': 'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=300'},
      ],
      'Seafood Shack': [
        {'name': 'Escovitch Fish', 'description': 'Crispy fried fish with peppers & onions', 'price': 1600, 'category': 'mains', 'imageUrl': 'https://images.unsplash.com/photo-1559737558-2f5a35f4523b?w=300'},
        {'name': 'Steamed Snapper', 'description': 'Whole snapper steamed with okra & butter', 'price': 1800, 'category': 'mains', 'imageUrl': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=300'},
        {'name': 'Lobster Tail', 'description': 'Grilled Caribbean lobster with garlic butter', 'price': 3500, 'category': 'mains', 'imageUrl': 'https://images.unsplash.com/photo-1533682805518-4a18d3b2af12?w=300'},
        {'name': 'Coconut Water', 'description': 'Fresh young coconut, chilled', 'price': 400, 'category': 'drinks', 'imageUrl': 'https://images.unsplash.com/photo-1541544181051-e46607bc22a4?w=300'},
      ],
      'Kingston Eats': [
        {'name': 'Oxtail & Butter Beans', 'description': 'Slow-braised oxtail with white rice', 'price': 1500, 'category': 'mains', 'imageUrl': 'https://images.unsplash.com/photo-1574484284002-952d92456975?w=300'},
        {'name': 'Jerk Pork', 'description': 'Spicy grilled pork with bammy', 'price': 1300, 'category': 'mains', 'imageUrl': 'https://images.unsplash.com/photo-1544025162-d76538591398?w=300'},
        {'name': 'Mannish Water', 'description': 'Traditional Jamaican goat soup', 'price': 700, 'category': 'mains', 'imageUrl': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=300'},
        {'name': 'Rum Punch', 'description': 'Classic Caribbean rum punch blend', 'price': 450, 'category': 'drinks', 'imageUrl': 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=300'},
      ],
    };

    for (final entry in menuData.entries) {
      final merchantRef = refs[entry.key];
      if (merchantRef == null) continue;
      final batch = _db.batch();
      for (final item in entry.value) {
        batch.set(merchantRef.collection('menuItems').doc(), item);
      }
      await batch.commit();
    }
  }

  // ─── Merchants ───────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> merchantsByCategory(String category) =>
      _db
          .collection('merchants')
          .where('category', isEqualTo: category)
          .snapshots()
          .map((s) =>
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
      'status': 'pending',
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
    final snap =
        await _db.collection('users').doc(uid).collection('addresses').get();
    if (snap.docs.isEmpty) {
      await addAddress(uid, 'Home', '14 Yallahs Main Road, St. Thomas');
      await addAddress(uid, 'Work', '45 King Street, Kingston');
      final snap2 =
          await _db.collection('users').doc(uid).collection('addresses').get();
      return _sortedAddresses(snap2.docs);
    }
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

  static Future<void> submitRating({
    required String orderId,
    required String driverId,
    required int driverRating,
    required int merchantRating,
    required String comment,
    required List<String> tags,
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'rated': true,
      'driverRating': driverRating,
      'merchantRating': merchantRating,
      'comment': comment,
      'tags': tags,
    });

    if (driverId.isNotEmpty) {
      final ref = _db.collection('drivers').doc(driverId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;
        final data = snap.data()!;
        final total =
            ((data['totalRatings'] as num?)?.toInt() ?? 0) + driverRating;
        final count =
            ((data['ratingCount'] as num?)?.toInt() ?? 0) + 1;
        tx.update(ref, {
          'totalRatings': total,
          'ratingCount': count,
          'averageRating': total / count,
        });
      });
    }
  }
}
