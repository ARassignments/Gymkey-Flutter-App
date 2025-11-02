class Order {
  final int OrderId;
  final String OrderStatus;
  final String TransactionType;
  final DateTime OrderDate;
  final int UserId;
  final String UserName;
  final String RefNo;
  final String OrderType;
  final String PhoneNo;
  final double Quantity;
  final double Payable;
  final double Paid;
  final double Balance;
  final double TotalPurchaseQuantity;
  final double TotalPurchaseAmount;

  Order({
    required this.OrderId,
    required this.OrderStatus,
    required this.TransactionType,
    required this.OrderDate,
    required this.UserId,
    required this.UserName,
    required this.RefNo,
    required this.OrderType,
    required this.PhoneNo,
    required this.Quantity,
    required this.Payable,
    required this.Paid,
    required this.Balance,
    required this.TotalPurchaseQuantity,
    required this.TotalPurchaseAmount,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      OrderId: json['OrderId'],
      OrderStatus: json['OrderStatus'],
      TransactionType: json['TransactionType'],
      OrderDate: DateTime.parse(json['OrderDate']),
      UserId: json['UserId'],
      UserName: json['UserName'],
      RefNo: json['RefNo'],
      OrderType: json['OrderType'],
      PhoneNo: json['PhoneNo'],
      Quantity: (json['Quantity'] as num).toDouble(),
      Payable: (json['Payable'] as num).toDouble(),
      Paid: (json['Paid'] as num).toDouble(),
      Balance: (json['Balance'] as num).toDouble(),
      TotalPurchaseQuantity: (json['TotalPurchaseQuantity'] as num).toDouble(),
      TotalPurchaseAmount: (json['TotalPurchaseAmount'] as num).toDouble(),
    );
  }
}
