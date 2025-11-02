class OrderDetailResponse {
  final bool success;
  final List<OrderDetail> orderDetails;
  final List<OrderItem> orderItems;

  OrderDetailResponse({
    required this.success,
    required this.orderDetails,
    required this.orderItems,
  });

  factory OrderDetailResponse.fromJson(Map<String, dynamic> json) {
    return OrderDetailResponse(
      success: json['Success'] ?? false,
      orderDetails: (json['OrderDetails'] as List)
          .map((e) => OrderDetail.fromJson(e))
          .toList(),
      orderItems: (json['OrderItems'] as List)
          .map((e) => OrderItem.fromJson(e))
          .toList(),
    );
  }
}

class OrderDetail {
  final int Id;
  final String RefNo;
  final String UserName;
  final int UserId;
  final String Contact;
  final String Address;
  final double TotalAmount;
  final double Paid;
  final double Balance;
  final double SubTotal;
  final String TransType;
  final double SalesTax;
  final double Discount;
  final String OrderStatus;
  final String OrderDate;
  final String Remarks;

  OrderDetail({
    required this.Id,
    required this.RefNo,
    required this.UserName,
    required this.UserId,
    required this.Contact,
    required this.Address,
    required this.TotalAmount,
    required this.Paid,
    required this.Balance,
    required this.SubTotal,
    required this.TransType,
    required this.SalesTax,
    required this.Discount,
    required this.OrderStatus,
    required this.OrderDate,
    required this.Remarks,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      Id: json['Id'],
      RefNo: json['RefNo'],
      UserName: json['UserName'],
      UserId: json['UserId'],
      Contact: json['Contact'],
      Address: json['Address'],
      TotalAmount: (json['TotalAmount'] ?? 0).toDouble(),
      Paid: (json['Paid'] ?? 0).toDouble(),
      Balance: (json['Balance'] ?? 0).toDouble(),
      SubTotal: (json['SubTotal'] ?? 0).toDouble(),
      TransType: json['TransType'],
      SalesTax: (json['SalesTax'] ?? 0).toDouble(),
      Discount: (json['Discount'] ?? 0).toDouble(),
      OrderStatus: json['OrderStatus'],
      OrderDate: json['OrderDate'],
      Remarks: json['Remarks'],
    );
  }
}

class OrderItem {
  final int ProductId;
  final String ProductName;
  final int Quantity;
  final double Price;
  final double DiscountedTaxPerPiece;
  final double DiscountPer;
  final String OrderType;
  final double TotalPrice;
  final double SalesTaxPrice;
  final double DiscountPrice;

  OrderItem({
    required this.ProductId,
    required this.ProductName,
    required this.Quantity,
    required this.Price,
    required this.DiscountedTaxPerPiece,
    required this.DiscountPer,
    required this.OrderType,
    required this.TotalPrice,
    required this.SalesTaxPrice,
    required this.DiscountPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      ProductId: json['ProductId'],
      ProductName: json['ProductName'],
      Quantity: json['Quantity'],
      Price: (json['Price'] ?? 0).toDouble(),
      DiscountedTaxPerPiece: (json['DiscountedTaxPerPiece'] ?? 0).toDouble(),
      DiscountPer: (json['DiscountPer'] ?? 0).toDouble(),
      OrderType: json['OrderType'],
      TotalPrice: (json['TotalPrice'] ?? 0).toDouble(),
      SalesTaxPrice: (json['SalesTaxPrice'] ?? 0).toDouble(),
      DiscountPrice: (json['DiscountPrice'] ?? 0).toDouble(),
    );
  }
}
