class CustomerSingleModel {
  final int Id;
  final String UserName;
  final String PhoneNo;
  final String Address;
  final String CityName;
  final String StateName;
  final bool Success;

  CustomerSingleModel({
    required this.Id,
    required this.UserName,
    required this.PhoneNo,
    required this.Address,
    required this.CityName,
    required this.StateName,
    required this.Success,
  });

  factory CustomerSingleModel.fromJson(Map<String, dynamic> json) {
    return CustomerSingleModel(
      Id: json['Id'],
      UserName: json['UserName'] ?? '',
      PhoneNo: json['PhoneNo'] ?? '',
      Address: json['Address'] ?? '',
      CityName: json['CityName'] ?? '',
      StateName: json['StateName'] ?? '',
      Success: json['Success'] ?? false,
    );
  }
}
