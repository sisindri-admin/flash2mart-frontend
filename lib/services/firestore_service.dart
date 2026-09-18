import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== 1. PRODUCT METHODS ====================
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

  Stream<QuerySnapshot> getProducts(String merchantId) {
    return _db
        .collection('products')
        .where('merchantId', isEqualTo: merchantId)
        .snapshots();
  }

  // ==================== 2. MERCHANT PROFILE METHODS ====================
  Future<Map<String, dynamic>?> getMerchantProfile(String uid) async {
    final doc = await _db.collection('merchants').doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // ==================== 3. ORDER CREATION & FETCH METHODS ====================
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
      'orderStatus': 'Pending',
      'currentStatus': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getOrders(String merchantId) {
    return _db
        .collection('orders')
        .where('merchantId', isEqualTo: merchantId)
        .snapshots();
  }

  // ==================== 4. REAL-TIME TRACKING & STATUS METHODS ====================

  // 4 Apps (Customer, Merchant, Delivery, Admin) Instant Sync కోసం trackingHistory Array ని ఉపయోగించాము
  static Future<void> updateOrderStatusWithTracking({
    required String orderId,
    required String newStatus,
    required String title,
    required String updatedBy,
  }) async {
    try {
      final orderRef = _db.collection('orders').doc(orderId);

      await orderRef.update({
        'orderStatus': newStatus,
        'status': newStatus,
        'currentStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'trackingHistory': FieldValue.arrayUnion([
          {
            'status': newStatus,
            'title': title,
            'timestamp': DateTime.now().toIso8601String(),
            'updatedBy': updatedBy,
          }
        ]),
      });
    } catch (e) {
      debugPrint("Error updating order tracking: $e");
      rethrow;
    }
  }

  // Merchant Order Accept Logic
  static Future<void> acceptOrder({
    required String orderId,
    required Map<String, dynamic> orderData,
  }) async {
    try {
      await _db.collection('order_accept_merchant').doc(orderId).set({
        ...orderData,
        'orderId': orderId,
        'acceptedAt': FieldValue.serverTimestamp(),
        'status': 'Preparing',
        'orderStatus': 'Preparing',
      });

      await updateOrderStatusWithTracking(
        orderId: orderId,
        newStatus: 'Preparing',
        title: 'Order Accepted & Preparing',
        updatedBy: 'Merchant',
      );
    } catch (e) {
      debugPrint("Error accepting order: $e");
      rethrow;
    }
  }

  // Merchant Order Reject Logic
  static Future<void> rejectOrder({
    required String orderId,
    required Map<String, dynamic> orderData,
    required String reason,
  }) async {
    try {
      await _db.collection('rejected_orders').doc(orderId).set({
        ...orderData,
        'orderId': orderId,
        'rejectReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'status': 'Cancelled',
        'orderStatus': 'Cancelled',
      });

      await updateOrderStatusWithTracking(
        orderId: orderId,
        newStatus: 'Cancelled',
        title: 'Order Cancelled: $reason',
        updatedBy: 'Merchant',
      );
    } catch (e) {
      debugPrint("Error rejecting order: $e");
      rethrow;
    }
  }

  // Update Order Status to Packing Ready
  static Future<void> markOrderPackingReady(String orderId) async {
    await updateOrderStatusWithTracking(
      orderId: orderId,
      newStatus: 'Packing_Ready',
      title: 'Order Packed & Ready for Pickup',
      updatedBy: 'Merchant',
    );
  }
}