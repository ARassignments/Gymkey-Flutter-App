import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Models/customer_single_model.dart';
import '/responses/scrap_response.dart';
import '/responses/ledger_response.dart';
import '/responses/payment_response.dart';
import '/responses/order_detail_response.dart';
import '/responses/order_response.dart';
import '/responses/customer_response.dart';
import '/utils/session_manager.dart';

class ApiService {
  static const String baseUrl = "https://y2ksolutions.com/api/MobileAppApi";

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"UserName": username, "Password": password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to login: ${response.body}");
    }
  }

  static Future<CustomerResponse> getAllCustomers() async {
    final orgId = await SessionManager.getOrganizationId();

    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final url = Uri.parse("$baseUrl/Users?OrganizationId=$orgId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return CustomerResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to load customers");
    }
  }

  static Future<OrdersResponse> getAllOrders({
    required String fromDate,
    required String toDate,
  }) async {
    final orgId = await SessionManager.getOrganizationId();
    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final url = Uri.parse(
      "$baseUrl/AllOrders?OrganizationId=$orgId&FromDate=$fromDate&ToDate=$toDate",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return OrdersResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch orders: ${response.body}");
    }
  }

  static Future<OrderDetailResponse> getOrderDetail(int id) async {
    final url = Uri.parse("$baseUrl/OrderDetail?Id=$id");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return OrderDetailResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch order detail: ${response.body}");
    }
  }

  static Future<LedgerResponse> getAllLedgers({
    required String fromDate,
    required String toDate,
    required int userId,
  }) async {
    final orgId = await SessionManager.getOrganizationId();
    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final url = Uri.parse(
      "$baseUrl/Ledger?OrganizationId=$orgId&UserId=$userId&FromDate=$fromDate&ToDate=$toDate",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return LedgerResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch ledgers: ${response.body}");
    }
  }

  static Future<PaymentsResponse> getAllPayments({
    required String fromDate,
    required String toDate,
  }) async {
    final orgId = await SessionManager.getOrganizationId();
    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final url = Uri.parse(
      "$baseUrl/AllPayments?OrganizationId=$orgId&FromDate=$fromDate&ToDate=$toDate",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return PaymentsResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch payments: ${response.body}");
    }
  }

  static Future<ScrapsResponse> getAllScraps({
    required String fromDate,
    required String toDate,
  }) async {
    final orgId = await SessionManager.getOrganizationId();
    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final url = Uri.parse(
      "$baseUrl/AllScraps?OrganizationId=$orgId&FromDate=$fromDate&ToDate=$toDate",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return ScrapsResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch scraps: ${response.body}");
    }
  }

  static Future<CustomerSingleModel?> getSingleCustomer(int id) async {
    final url = Uri.parse('$baseUrl/GetSingleCustomer?Id=$id');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['Success'] == true) {
        return CustomerSingleModel.fromJson(jsonData);
      } else {
        return null;
      }
    } else {
      throw Exception('Failed to fetch customer');
    }
  }
}
