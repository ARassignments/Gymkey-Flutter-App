import 'package:intl/intl.dart';

class PaymentModel {
  final int Id;
  final int UserId;
  final String UserName;
  final double Payment;
  final DateTime PaymentDate;
  final String PaymentType;
  final String PaymentMode;
  final String Remarks;

  PaymentModel({
    required this.Id,
    required this.UserId,
    required this.UserName,
    required this.Payment,
    required this.PaymentDate,
    required this.PaymentType,
    required this.PaymentMode,
    required this.Remarks,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      Id: json['Id'] ?? 0,
      UserId: json['UserId'] ?? 0,
      UserName: json['UserName'] ?? '',
      Payment: (json['Payment'] ?? 0).toDouble(),
      // Parse "10-10-2025" safely
      PaymentDate: DateFormat('dd-MM-yyyy').parse(json['PaymentDate']),
      PaymentType: json['PaymentType'] ?? '',
      PaymentMode: json['PaymentMode'] ?? '',
      Remarks: json['Remarks'] ?? '',
    );
  }
}
