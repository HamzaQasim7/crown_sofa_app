import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:form_order_app/data/models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'orders';

  // Get all orders
  Stream<List<OrderModel>> getOrders() {
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get orders from last 7 days
  Stream<List<OrderModel>> getLastSevenDaysOrders() {
    final DateTime sevenDaysAgo = DateTime.now().subtract(
      const Duration(days: 7),
    );

    return _firestore
        .collection(_collection)
        .where('timestamp', isGreaterThanOrEqualTo: sevenDaysAgo)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get orders from previous month
  Stream<List<OrderModel>> getPreviousMonthOrders() {
    final DateTime now = DateTime.now();
    final DateTime firstDayPrevMonth = DateTime(now.year, now.month - 1, 1);
    final DateTime lastDayPrevMonth = DateTime(now.year, now.month, 0);

    return _firestore
        .collection(_collection)
        .where('timestamp', isGreaterThanOrEqualTo: firstDayPrevMonth)
        .where('timestamp', isLessThanOrEqualTo: lastDayPrevMonth)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
        });
  }

  // Search orders by customer name, order ID, or phone number
  Stream<List<OrderModel>> searchOrders(String query) {
    // Convert query to lowercase for case-insensitive search
    final String lowercaseQuery = query.toLowerCase();

    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .where((order) {
                return order.customerName.toLowerCase().contains(
                      lowercaseQuery,
                    ) ||
                    order.id.toLowerCase().contains(lowercaseQuery) ||
                    order.phoneNumber.contains(query);
              })
              .toList();
        });
  }

  // Get a single order by ID
  Future<OrderModel?> getOrderById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return OrderModel.fromFirestore(doc);
    }
    return null;
  }

  // Update order status
  Future<void> updateOrderStatus(String id, String status) async {
    await _firestore.collection(_collection).doc(id).update({
      'status': status,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}
