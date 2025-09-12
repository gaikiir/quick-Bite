import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_bite/screens/models/cart_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
  failed,
}

enum PaymentStatus { pending, processing, completed, failed, refunded }

enum PaymentMethod { mpesa, cash, card }

class OrderAddress {
  final String street;
  final String country;
  final String? deliveryInstructions;

  OrderAddress({
    required this.street,
    this.country = 'Kenya',
    this.deliveryInstructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'country': country,
      'deliveryInstructions': deliveryInstructions,
    };
  }

  factory OrderAddress.fromMap(Map<String, dynamic> map) {
    return OrderAddress(
      street: map['street'] ?? '',
      country: map['country'] ?? 'Kenya',
      deliveryInstructions: map['deliveryInstructions'],
    );
  }

  @override
  String toString() {
    final parts = [street, country].where((part) => part.isNotEmpty).toList();
    return parts.join(', ');
  }
}

class PaymentInfo {
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final String? mpesaReference;
  final String? phoneNumber;
  final DateTime? paidAt;
  final String? failureReason;

  PaymentInfo({
    required this.method,
    required this.status,
    this.transactionId,
    this.mpesaReference,
    this.phoneNumber,
    this.paidAt,
    this.failureReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'method': method.name,
      'status': status.name,
      'transactionId': transactionId,
      'mpesaReference': mpesaReference,
      'phoneNumber': phoneNumber,
      'paidAt': paidAt?.toIso8601String(),
      'failureReason': failureReason,
    };
  }

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => PaymentMethod.mpesa,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      transactionId: map['transactionId'],
      mpesaReference: map['mpesaReference'],
      phoneNumber: map['phoneNumber'],
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
      failureReason: map['failureReason'],
    );
  }
}

class OrderModel {
  final String orderId;
  final String userId;
  final String userEmail;
  final String userName;
  final String userPhone;
  final List<CartModel> items;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final OrderAddress deliveryAddress;
  final PaymentInfo paymentInfo;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? estimatedDeliveryTime;
  final String? notes;
  final String? adminNotes;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.userPhone,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentInfo,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.estimatedDeliveryTime,
    this.notes,
    this.adminNotes,
  });

  // Calculate delivery fee based on location or other factors
  static double calculateDeliveryFee(OrderAddress address) {
    // Simple flat delivery fee
    const baseDeliveryFee = 100.0; // Base fee in KES

    return baseDeliveryFee;
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'userPhone': userPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress.toMap(),
      'paymentInfo': paymentInfo.toMap(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'notes': notes,
      'adminNotes': adminNotes,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      items: (map['items'] as List? ?? [])
          .map((item) => CartModel.fromMap(item))
          .toList(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      deliveryAddress: OrderAddress.fromMap(map['deliveryAddress'] ?? {}),
      paymentInfo: PaymentInfo.fromMap(map['paymentInfo'] ?? {}),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      estimatedDeliveryTime: map['estimatedDeliveryTime'] != null
          ? DateTime.parse(map['estimatedDeliveryTime'])
          : null,
      notes: map['notes'],
      adminNotes: map['adminNotes'],
    );
  }

  factory OrderModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel.fromMap(data);
  }

  OrderModel copyWith({
    OrderStatus? status,
    PaymentInfo? paymentInfo,
    DateTime? updatedAt,
    DateTime? estimatedDeliveryTime,
    String? adminNotes,
  }) {
    return OrderModel(
      orderId: orderId,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      userPhone: userPhone,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      notes: notes,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  // Utility getters
  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending Confirmation';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Being Prepared';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.failed:
        return 'Failed';
    }
  }

  String get paymentStatusDisplayName {
    switch (paymentInfo.status) {
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.processing:
        return 'Processing Payment';
      case PaymentStatus.completed:
        return 'Payment Completed';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  bool get canBeCancelled {
    return status == OrderStatus.pending || status == OrderStatus.confirmed;
  }

  bool get isCompleted {
    return status == OrderStatus.delivered;
  }

  bool get isCancelled {
    return status == OrderStatus.cancelled || status == OrderStatus.failed;
  }
}
