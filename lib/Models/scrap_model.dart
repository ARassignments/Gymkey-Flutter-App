class ScrapModel {
  final int Id;
  final int UserAccountId;
  final String UserName;
  final int Items;
  final int LocationId;
  final double Quantity;
  final double Price;
  final String OrderType;
  final double TotalPrice;
  final String Remarks;
  final DateTime CreatedAt;

  ScrapModel({
    required this.Id,
    required this.UserAccountId,
    required this.UserName,
    required this.Items,
    required this.LocationId,
    required this.Quantity,
    required this.Price,
    required this.OrderType,
    required this.TotalPrice,
    required this.Remarks,
    required this.CreatedAt,
  });

  factory ScrapModel.fromJson(Map<String, dynamic> json) {
    return ScrapModel(
      Id: json['Id'],
      UserAccountId: json['UserAccountId'],
      UserName: json['UserName'] ?? '',
      Items: json['Items'] ?? 0,
      LocationId: json['LocationId'] ?? 0,
      Quantity: (json['Quantity'] ?? 0).toDouble(),
      Price: (json['Price'] ?? 0).toDouble(),
      OrderType: json['OrderType'] ?? '',
      TotalPrice: (json['TotalPrice'] ?? 0).toDouble(),
      Remarks: json['Remarks'] ?? '',
      CreatedAt: DateTime.parse(json['CreatedAt']),
    );
  }
}
