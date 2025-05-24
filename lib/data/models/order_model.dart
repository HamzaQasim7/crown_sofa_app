import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderModel {
  final String id;
  final String colorFabric;
  final List<String> combination;
  final String customerAddress;
  final String customerName;
  final DateTime deliveryDate;
  final String designName;
  final DateTime orderBookingDate;
  final String orderDetails;
  final String phoneNumber;
  final String postcode;
  final double salePrice;
  final String sellerName;
  final DateTime timestamp;
  final List<String> imageUrls;

  OrderModel({
    required this.imageUrls,
    required this.id,
    required this.colorFabric,
    required this.combination,
    required this.customerAddress,
    required this.customerName,
    required this.deliveryDate,
    required this.designName,
    required this.orderBookingDate,
    required this.orderDetails,
    required this.phoneNumber,
    required this.postcode,
    required this.salePrice,
    required this.sellerName,
    required this.timestamp,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle combination field which could be a string or a list
    List<String> combinationList = [];
    if (data['combination'] is List) {
      combinationList = List<String>.from(data['combination']);
    } else if (data['combination'] is String) {
      combinationList = [data['combination']];
    }

    // Parse dates
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return OrderModel(
      imageUrls:
          data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : [],
      id: doc.id,
      colorFabric: data['colorFabric'] ?? '',
      combination: combinationList,
      customerAddress: data['customerAddress'] ?? '',
      customerName: data['customerName'] ?? '',
      deliveryDate: parseDate(data['deliveryDate']),
      designName: data['designName'] ?? '',
      orderBookingDate: parseDate(data['orderBookingDate']),
      orderDetails: data['orderDetails'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      postcode: data['postcode'] ?? '',
      salePrice: (data['salePrice'] ?? 0).toDouble(),
      sellerName: data['sellerName'] ?? '',
      timestamp:
          data['timestamp'] is Timestamp
              ? data['timestamp'].toDate()
              : DateTime.now(),
    );
  }

  String get formattedOrderDate {
    return DateFormat('dd MMM yyyy').format(orderBookingDate);
  }

  String get formattedDeliveryDate {
    return DateFormat('dd MMM yyyy').format(deliveryDate);
  }

  String get formattedTimestamp {
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp);
  }

  String get combinationText {
    return combination.join(', ');
  }

  String get formattedPrice {
    return 'RS${salePrice.toStringAsFixed(2)}';
  }
}
