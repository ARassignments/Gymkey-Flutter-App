class Customer {
  final int UserId;
  final String UserName;
  final int AccGroup;
  final double OpeningBalance;
  final int BalanceType;
  final String Address;
  final String? UserAccountName;
  final String StateName;
  final String CityName;
  final String PhoneNo;
  final String Email;
  final String BankName;
  final String BankAccount;
  final String BankBranchCode;

  Customer({
    required this.UserId,
    required this.UserName,
    required this.AccGroup,
    required this.OpeningBalance,
    required this.BalanceType,
    required this.Address,
    this.UserAccountName,
    required this.StateName,
    required this.CityName,
    required this.PhoneNo,
    required this.Email,
    required this.BankName,
    required this.BankAccount,
    required this.BankBranchCode,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      UserId: json['UserId'] ?? 0,
      UserName: json['UserName'] ?? '',
      AccGroup: json['AccGroup'] ?? 0,
      OpeningBalance: (json['OpeningBalance'] ?? 0).toDouble(),
      BalanceType: json['BalanceType'] ?? 0,
      Address: json['Address'] ?? '',
      UserAccountName: json['UserAccountName'],
      StateName: json['StateName'] ?? '',
      CityName: json['CityName'] ?? '',
      PhoneNo: json['PhoneNo'] ?? '',
      Email: json['Email'] ?? '',
      BankName: json['BankName'] ?? '',
      BankAccount: json['BankAccount'] ?? '',
      BankBranchCode: json['BankBranchCode'] ?? '',
    );
  }
}
