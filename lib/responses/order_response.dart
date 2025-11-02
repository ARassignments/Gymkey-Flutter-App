import '/Models/order_model.dart';

class OrdersResponse {
  final List<Order> orders;
  final bool success;

  OrdersResponse({required this.orders, required this.success});

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      orders: (json['Orders'] as List)
          .map((item) => Order.fromJson(item))
          .toList(),
      success: json['Success'],
    );
  }
}
