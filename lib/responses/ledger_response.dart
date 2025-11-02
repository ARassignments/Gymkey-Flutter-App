import '/Models/ledger_model.dart';

class LedgerResponse {
  final List<Ledger> ledger;
  final bool success;

  LedgerResponse({required this.ledger, required this.success});

  factory LedgerResponse.fromJson(Map<String, dynamic> json) {
    return LedgerResponse(
      ledger: (json['Ledgers'] as List)
          .map((item) => Ledger.fromJson(item))
          .toList(),
      success: json['Success'],
    );
  }
}