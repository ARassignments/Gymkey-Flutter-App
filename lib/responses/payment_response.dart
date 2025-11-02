import '/Models/payment_model.dart';

class PaymentsResponse {
  final List<PaymentModel> payments;
  final bool success;

  PaymentsResponse({required this.payments, required this.success});

  factory PaymentsResponse.fromJson(Map<String, dynamic> json) {
    return PaymentsResponse(
      payments: (json['PaymentList'] as List)
          .map((item) => PaymentModel.fromJson(item))
          .toList(),
      success: json['Success'],
    );
  }
}
