import '/Models/customer_model.dart';

class CustomerResponse {
  final List<Customer> accounts;
  final bool success;

  CustomerResponse({required this.accounts, required this.success});

  factory CustomerResponse.fromJson(Map<String, dynamic> json) {
    return CustomerResponse(
      accounts: (json['Accounts'] as List<dynamic>)
          .map((e) => Customer.fromJson(e))
          .toList(),
      success: json['Success'] ?? false,
    );
  }
}
