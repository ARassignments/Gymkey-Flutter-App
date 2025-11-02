class Ledger {
  final int Id;
  final String Date;
  final String SourceType;
  final String RefOrPaymentType;
  final double Credit;
  final double Debit;
  final String Balance;

  Ledger({
    required this.Id,
    required this.Date,
    required this.SourceType,
    required this.RefOrPaymentType,
    required this.Credit,
    required this.Debit,
    required this.Balance,
  });

  factory Ledger.fromJson(Map<String, dynamic> json) {
    return Ledger(
      Id: json['Id'] ?? 0,
      Date: json['Date'] ?? '',
      SourceType: json['SourceType'] ?? '',
      RefOrPaymentType: json['RefOrPaymentType'] ?? '',
      Credit: (json['Credit'] ?? 0).toDouble(),
      Debit: (json['Debit'] ?? 0).toDouble(),
      Balance: json['Balance'] ?? '',
    );
  }
}