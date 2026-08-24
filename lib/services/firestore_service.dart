import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addProduct({
    required String merchantId,
    required String name,
    required double price,
    required int stock,
    required String category,
    required String description,
  }) async {
    final docRef = _db.collection('products').doc();

    await docRef.set({
      'productId': docRef.id,
      'merchantId': merchantId,
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'description': description,
      'imageUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addOrder({
    required String merchantId,
    required String customerName,
    required String customerPhone,
    required double totalAmount,
  }) async {
    final docRef = _db.collection('orders').doc();

    await docRef.set({
      'orderId': docRef.id,
      'merchantId': merchantId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'totalAmount': totalAmount,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getProducts(String merchantId) {
    return _db
        .collection('products')
        .where('merchantId', isEqualTo: merchantId)
        .snapshots();
  }

  Stream<QuerySnapshot> getOrders(String merchantId) {
    return _db
        .collection('orders')
        .where('merchantId', isEqualTo: merchantId)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getMerchantProfile(String uid) async {
    final doc = await _db.collection('merchants').doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }
}
