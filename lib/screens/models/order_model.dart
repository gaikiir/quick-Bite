import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_bite/screens/models/cart_model.dart';

// Order status enumeration
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
  failed,
}

// Payment status enumeration
enum PaymentStatus { pending, processing, completed, failed, refunded }

// Payment method enumeration
enum PaymentMethod { cash, card, mpesa }

// Order address model
class OrderAddress {
  final String street;
  final String country;
  final String? deliveryInstructions;

  const OrderAddress({
    required this.street,
    this.country = 'Kenya',
    this.deliveryInstructions,
  });

  Map<String, dynamic> toMap() => {
    'street': street,
    'country': country,
    'deliveryInstructions': deliveryInstructions,
  };

  factory OrderAddress.fromMap(Map<String, dynamic> map) => OrderAddress(
    street: map['street']?.toString() ?? '',
    country: map['country']?.toString() ?? 'Kenya',
    deliveryInstructions: map['deliveryInstructions']?.toString(),
  );

  @override
  String toString() {
    final parts = [street, country].where((part) => part.isNotEmpty);
    return parts.join(', ');
  }
}

// Payment information model
class PaymentInfo {
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final String? mpesaReceiptNumber;
  final String? phoneNumber;
  final DateTime? paidAt;
  final String? failureReason;
  final double? amount;

  const PaymentInfo({
    required this.method,
    required this.status,
    this.transactionId,
    this.mpesaReceiptNumber,
    this.phoneNumber,
    this.paidAt,
    this.failureReason,
    this.amount,
  });

  // Create payment info for M-Pesa
  factory PaymentInfo.mpesa({
    required PaymentStatus status,
    required String phoneNumber,
    required double amount,
    String? transactionId,
    String? mpesaReceiptNumber,
    String? failureReason,
  }) => PaymentInfo(
    method: PaymentMethod.mpesa,
    status: status,
    phoneNumber: phoneNumber,
    amount: amount,
    transactionId: transactionId,
    mpesaReceiptNumber: mpesaReceiptNumber,
    failureReason: failureReason,
    paidAt: status == PaymentStatus.completed ? DateTime.now() : null,
  );

  // Create payment info for cash
  factory PaymentInfo.cash({
    required double amount,
    PaymentStatus status = PaymentStatus.pending,
  }) => PaymentInfo(method: PaymentMethod.cash, status: status, amount: amount);

  // Create payment info for card
  factory PaymentInfo.card({
    required double amount,
    PaymentStatus status = PaymentStatus.processing,
    String? transactionId,
  }) => PaymentInfo(
    method: PaymentMethod.card,
    status: status,
    amount: amount,
    transactionId: transactionId,
  );

  Map<String, dynamic> toMap() => {
    'method': method.name,
    'status': status.name,
    'transactionId': transactionId,
    'mpesaReceiptNumber': mpesaReceiptNumber,
    'phoneNumber': phoneNumber,
    'paidAt': paidAt?.toIso8601String(),
    'failureReason': failureReason,
    'amount': amount,
  };

  factory PaymentInfo.fromMap(Map<String, dynamic> map) => PaymentInfo(
    method: PaymentMethod.values.firstWhere(
      (e) => e.name == map['method']?.toString(),
      orElse: () => PaymentMethod.cash,
    ),
    status: PaymentStatus.values.firstWhere(
      (e) => e.name == map['status']?.toString(),
      orElse: () => PaymentStatus.pending,
    ),
    transactionId: map['transactionId']?.toString(),
    mpesaReceiptNumber: map['mpesaReceiptNumber']?.toString(),
    phoneNumber: map['phoneNumber']?.toString(),
    paidAt: map['paidAt'] != null
        ? DateTime.parse(map['paidAt'].toString())
        : null,
    failureReason: map['failureReason']?.toString(),
    amount: map['amount']?.toDouble(),
  );

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isPending => status == PaymentStatus.pending;

  // Display name for payment status
  String get displayName {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

// Main order model
class OrderModel {
  final String orderId;
  final String userId;
  final String userEmail;
  final List<CartModel> items;
  final OrderAddress deliveryAddress;
  final PaymentInfo paymentInfo;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String? notes;

  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.userEmail,
    required this.items,
    required this.deliveryAddress,
    required this.paymentInfo,
    required this.status,
    required this.createdAt,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.updatedAt,
    this.notes,
  });

  // Create new order
  factory OrderModel.create({
    required String userId,
    required String userEmail,
    required List<CartModel> items,
    required OrderAddress deliveryAddress,
    required PaymentInfo paymentInfo,
    required double subtotal,
    required double deliveryFee,
    String? notes,
  }) {
    final orderId = 'QB_${DateTime.now().millisecondsSinceEpoch}';
    return OrderModel(
      orderId: orderId,
      userId: userId,
      userEmail: userEmail,
      items: items,
      deliveryAddress: deliveryAddress,
      paymentInfo: paymentInfo,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: subtotal + deliveryFee,
      notes: notes,
    );
  }

  // Update order status
  OrderModel copyWith({
    OrderStatus? status,
    PaymentInfo? paymentInfo,
    DateTime? updatedAt,
  }) => OrderModel(
    orderId: orderId,
    userId: userId,
    userEmail: userEmail,
    items: items,
    deliveryAddress: deliveryAddress,
    paymentInfo: paymentInfo ?? this.paymentInfo,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    total: total,
    notes: notes,
  );

  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'userId': userId,
    'userEmail': userEmail,
    'items': items.map((item) => item.toMap()).toList(),
    'deliveryAddress': deliveryAddress.toMap(),
    'paymentInfo': paymentInfo.toMap(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'total': total,
    'notes': notes,
  };

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
    orderId: map['orderId']?.toString() ?? '',
    userId: map['userId']?.toString() ?? '',
    userEmail: map['userEmail']?.toString() ?? '',
    items:
        (map['items'] as List<dynamic>?)
            ?.map((item) => CartModel.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [],
    deliveryAddress: OrderAddress.fromMap(
      map['deliveryAddress'] as Map<String, dynamic>,
    ),
    paymentInfo: PaymentInfo.fromMap(
      map['paymentInfo'] as Map<String, dynamic>,
    ),
    status: OrderStatus.values.firstWhere(
      (e) => e.name == map['status']?.toString(),
      orElse: () => OrderStatus.pending,
    ),
    createdAt: DateTime.parse(map['createdAt'].toString()),
    updatedAt: map['updatedAt'] != null
        ? DateTime.parse(map['updatedAt'].toString())
        : null,
    subtotal: map['subtotal']?.toDouble() ?? 0.0,
    deliveryFee: map['deliveryFee']?.toDouble() ?? 0.0,
    total: map['total']?.toDouble() ?? 0.0,
    notes: map['notes']?.toString(),
  );

  factory OrderModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel.fromMap(data);
  }

  // Utility getters
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isCompleted => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isPending => status == OrderStatus.pending;
  String get displayOrderId => orderId.replaceFirst('QB_', '#');

  // Backward compatibility getters for order success screen
  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
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

  double get totalAmount => total;

  String get userName => userEmail
      .split('@')
      .first
      .replaceAll('.', ' ')
      .replaceAll('_', ' ')
      .toUpperCase();

  String get userPhone => paymentInfo.phoneNumber ?? 'Not provided';

  String get paymentStatusDisplayName => paymentInfo.displayName;
}
