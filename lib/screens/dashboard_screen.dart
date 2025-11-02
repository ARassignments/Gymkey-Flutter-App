import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import '/components/dashboard_grid.dart';
import '/components/menu_drawer.dart';
import '/components/dashboard_charts.dart';
import '/components/dashboard_slider.dart';
import '/screens/scraps_screen.dart';
import '/components/appsnackbar.dart';
import '/components/customer_search_field.dart';
import '/components/dialog_orderdetail_pdf.dart';
import '/screens/payments_screen.dart';
import '/Models/ledger_model.dart';
import '/screens/customers_screen.dart';
import '/notifiers/avatar_notifier.dart';
import '/screens/profile_screen.dart';
import '/screens/order_detail_screen.dart';
import '/Models/order_model.dart';
import '/components/not_found.dart';
import '/Models/customer_model.dart';
import '/components/dialog_logout.dart';
import '/components/loading_screen.dart';
import '/responses/customer_response.dart';
import '/services/api_service.dart';
import '/theme/theme.dart';
import '/utils/session_manager.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? token;
  Map<String, dynamic>? user;

  int _currentIndex = 0;
  final ZoomDrawerController _drawerController = ZoomDrawerController();
  List<String> menus = ["Home", "Orders", "Ledgers", "Accounts"];

  //Customers BottomSheet
  late Future<CustomerResponse> _futureCustomers;
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  //Orders Screen
  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoadingOrders = true;
  bool _isRefreshingOrders = false;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  final TextEditingController _searchOrderController = TextEditingController();

  String? _selectedOrderStatus;
  String? _selectedTransactionType;
  String? _selectedOrderType;

  //Ledgers Screen
  List<Ledger> _allLedgers = [];
  bool _isLoadingLedgers = true;
  DateTime _fromDateLedger = DateTime(2025, 1, 1);
  DateTime _toDateLedger = DateTime.now();
  Customer? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchOrderController.addListener(_onOrderSearchChanged);
    _loadSessionAndCustomers();
    _loadOrders();
    _loadLedgers();
    _initAvatar();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchOrderController.removeListener(_onOrderSearchChanged);
    _searchOrderController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredCustomers = _allCustomers.where((cust) {
        return cust.UserName.toLowerCase().contains(query) ||
            cust.CityName.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onOrderSearchChanged() {
    _applyFilters();
  }

  Future<void> _initAvatar() async {
    final avatarData = await SessionManager.getAvatarAndGender();
    if (avatarData["avatar"] != null) {
      avatarNotifier.updateAvatar(avatarData["avatar"]!);
    }
  }

  Future<void> _loadSessionAndCustomers() async {
    token = await SessionManager.getUserToken();
    user = await SessionManager.getUser();

    _futureCustomers = ApiService.getAllCustomers();
    try {
      final response = await _futureCustomers;
      setState(() {
        _allCustomers = response.accounts;
        _filteredCustomers = response.accounts;
      });
    } catch (e) {
      debugPrint("Error loading customers: $e");
    }
  }

  Future<void> _refreshCustomers() async {
    setState(() => _isRefreshing = true);
    try {
      final response = await ApiService.getAllCustomers();
      setState(() {
        _allCustomers = response.accounts;
        _filteredCustomers = response.accounts;
        _searchController.clear();
      });
    } catch (e) {
      debugPrint("Error refreshing customers: $e");
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LoginScreen(),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
        ),
      );
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final response = await ApiService.getAllOrders(
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate),
      );
      debugPrint("Orders fetched: ${response.orders.length}");
      setState(() {
        _allOrders = response.orders;
        _filteredOrders = List.from(_allOrders); // show all initially
      });
    } catch (e) {
      debugPrint("Error fetching orders: $e");
    } finally {
      setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _isRefreshingOrders = true;
      _resetFilters(); // ✅ reset filters & search before reload
    });
    await _loadOrders();
    setState(() => _isRefreshingOrders = false);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      await _loadOrders();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "paid":
        return Colors.green;
      case "inprogress":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return HugeIconsSolid.clock01;
      case "paid":
        return HugeIconsSolid.checkmarkCircle01;
      case "inprogress":
        return HugeIconsSolid.loading02;
      default:
        return Icons.info;
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool hasFilters() {
              return _selectedOrderStatus != null ||
                  _selectedTransactionType != null ||
                  _selectedOrderType != null;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: Wrap(
                children: [
                  Column(
                    spacing: 16,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Filter Orders",
                        textAlign: TextAlign.center,
                        style: AppTheme.textLabel(context).copyWith(
                          fontSize: 16,
                          fontFamily: AppFontFamily.poppinsBold,
                        ),
                      ),
                      Divider(color: AppTheme.dividerBg(context)),
                      // Order Status
                      Text("Order Status", style: AppTheme.textLabel(context)),
                      Wrap(
                        spacing: 8,
                        children: ["Pending", "Paid", "InProgress"].map((
                          status,
                        ) {
                          final isSelected = _selectedOrderStatus == status;
                          return ChoiceChip(
                            label: Text(status),
                            labelStyle: AppTheme.textLabel(context).copyWith(
                              color: isSelected
                                  ? _getStatusColor(status)
                                  : AppTheme.iconColorThree(context),
                              fontSize: 12,
                            ),
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            backgroundColor: AppTheme.customListBg(context),
                            side: BorderSide(color: Colors.transparent),
                            selectedColor: _getStatusColor(
                              status,
                            ).withOpacity(0.3),
                            checkmarkColor: _getStatusColor(status),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedOrderStatus = selected ? status : null;
                              });
                              _applyFilters();
                            },
                          );
                        }).toList(),
                      ),

                      // Transaction Type
                      Text(
                        "Transaction Type",
                        style: AppTheme.textLabel(context),
                      ),
                      Wrap(
                        spacing: 8,
                        children: ["Sale", "Purchase"].map((type) {
                          final isSelected = _selectedTransactionType == type;
                          return ChoiceChip(
                            label: Text(type),
                            labelStyle: AppTheme.textLabel(context).copyWith(
                              color: AppTheme.iconColorThree(context),
                              fontSize: 12,
                            ),
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            backgroundColor: AppTheme.customListBg(context),
                            side: BorderSide(color: Colors.transparent),
                            selectedColor: AppTheme.customListBg(context),
                            checkmarkColor: AppTheme.iconColorThree(context),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedTransactionType = selected
                                    ? type
                                    : null;
                              });
                              _applyFilters();
                            },
                          );
                        }).toList(),
                      ),

                      // Order Type
                      Text("Order Type", style: AppTheme.textLabel(context)),
                      Wrap(
                        spacing: 8,
                        children: ["Credit", "Debit"].map((type) {
                          final isSelected = _selectedOrderType == type;
                          final typeColor = type == "Credit"
                              ? Colors.green
                              : Colors.red;
                          return ChoiceChip(
                            label: Text(type),
                            labelStyle: AppTheme.textLabel(context).copyWith(
                              color: isSelected
                                  ? typeColor
                                  : AppTheme.iconColorThree(context),
                              fontSize: 12,
                            ),
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            backgroundColor: AppTheme.customListBg(context),
                            side: BorderSide(color: Colors.transparent),
                            selectedColor: typeColor.withOpacity(0.3),
                            checkmarkColor: typeColor,
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedOrderType = selected ? type : null;
                              });
                              _applyFilters();
                            },
                          );
                        }).toList(),
                      ),
                      Divider(color: AppTheme.dividerBg(context)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 16,
                        children: [
                          FlatButton(
                            text: "Apply",
                            disabled:
                                !hasFilters(), // enable only if filters selected
                            onPressed: hasFilters()
                                ? () {
                                    Navigator.pop(context);
                                    _applyFilters();
                                  }
                                : null,
                          ),
                          GhostButton(
                            text: "Reset All",
                            disabled:
                                !hasFilters(), // enable only if filters selected
                            onPressed: hasFilters()
                                ? () {
                                    _refreshOrders();
                                    Navigator.pop(context);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _allOrders.where((order) {
        final statusMatch =
            _selectedOrderStatus == null ||
            order.OrderStatus.toLowerCase() ==
                _selectedOrderStatus!.toLowerCase();

        final transactionMatch =
            _selectedTransactionType == null ||
            order.TransactionType.toLowerCase() ==
                _selectedTransactionType!.toLowerCase();

        final typeMatch =
            _selectedOrderType == null ||
            order.OrderType.toLowerCase() == _selectedOrderType!.toLowerCase();

        final searchMatch =
            _searchOrderController.text.trim().isEmpty ||
            order.UserName.toLowerCase().contains(
              _searchOrderController.text.toLowerCase(),
            ) ||
            order.RefNo.toLowerCase().contains(
              _searchOrderController.text.toLowerCase(),
            );

        return statusMatch && transactionMatch && typeMatch && searchMatch;
      }).toList();
    });
  }

  void _resetFilters() {
    _selectedOrderStatus = null;
    _selectedTransactionType = null;
    _selectedOrderType = null;
    _searchOrderController.clear();
    _filteredOrders = List.from(_allOrders);
  }

  Future<void> _loadLedgers() async {
    setState(() => _isLoadingLedgers = true);

    try {
      final int? userId = _selectedCustomerId?.UserId;

      // ✅ Check if customer is selected
      if (userId == null || userId == 0) {
        setState(() => _isLoadingLedgers = false);
        AppSnackBar.show(
          context,
          message: "Please select a customer first.",
          type: AppSnackBarType.error,
        );
        return;
      }

      // ✅ Proceed with API call only if valid
      final response = await ApiService.getAllLedgers(
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDateLedger),
        toDate: DateFormat('yyyy-MM-dd').format(_toDateLedger),
        userId: userId,
      );

      debugPrint(
        "Ledger fetched for userId: $userId → ${response.ledger.length} records",
      );

      setState(() {
        _allLedgers = response.ledger;
      });
    } catch (e) {
      debugPrint("Error fetching ledgers: $e");
    } finally {
      setState(() => _isLoadingLedgers = false);
    }
  }

  Future<void> _refreshLedgers() async {
    setState(() {
      _isLoadingLedgers = true;
    });
    await _loadOrders();
    setState(() => _isLoadingLedgers = false);
  }

  Future<void> _selectDateRangeLedger(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _fromDateLedger,
        end: _toDateLedger,
      ),
    );

    if (picked != null) {
      setState(() {
        _fromDateLedger = picked.start;
        _toDateLedger = picked.end;
      });
      await _loadLedgers();
    }
  }

  List<Widget> _pages() {
    return [_homePage(), _ordersPage(), _ledgersPage(), _accountsPage()];
  }

  Widget _homePage() {
    return ListView(
      shrinkWrap: true,
      children: [
        DashboardSlider(),
        DashboardGrid(),
        DashboardCharts(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            "Need Help?",
            style: AppTheme.textLabel(
              context,
            ).copyWith(fontSize: 14, fontFamily: AppFontFamily.poppinsSemiBold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            spacing: 16,
            children: [
              Expanded(
                child: Opacity(
                  opacity: 0.5,
                  child: InkWell(
                    child: Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.customListBg(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              "FAQs",
                              style: AppTheme.textLink(context).copyWith(
                                fontSize: 13,
                                fontFamily: AppFontFamily.poppinsSemiBold,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -40,
                          bottom: -35,
                          child: Image.asset(
                            "assets/images/dashboard/faqs_image.png",
                            height: 180,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Opacity(
                  opacity: 0.5,
                  child: InkWell(
                    child: Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.customListBg(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              "Chat Now",
                              style: AppTheme.textLink(context).copyWith(
                                fontSize: 13,
                                fontFamily: AppFontFamily.poppinsSemiBold,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -40,
                          bottom: -28,
                          child: Image.asset(
                            "assets/images/dashboard/chat_image.png",
                            height: 180,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Column(
        //   children: [
        //     Text("Welcome, ${user?["FullName"] ?? "Guest"}"),
        //     Text("Email: ${user?["Email"] ?? "N/A"}"),
        //     Text("Organization Id: ${user?["OrganizationId"] ?? "Unknown"}"),
        //     Text("Token: ${token ?? "Not available"}"),
        //   ],
        // ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _ordersPage() {
    double grandCreditTotal = _filteredOrders.fold(
      0.0,
      (previousValue, order) => previousValue + order.Balance,
    );
    final formattedCreditGrandTotal = NumberFormat(
      '#,###.00',
    ).format(grandCreditTotal);
    double grandDebitTotal = _filteredOrders.fold(
      0.0,
      (previousValue, order) => previousValue + order.Paid,
    );
    final formattedDebitGrandTotal = NumberFormat(
      '#,###.00',
    ).format(grandDebitTotal);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _searchOrderController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'Search Here',
                  hintText: 'Search by name or ref no',
                  counter: const SizedBox.shrink(),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Icon(HugeIconsSolid.search01),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchOrderController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(HugeIconsStroke.cancel02),
                          onPressed: () {
                            _searchOrderController.clear();
                            _applyFilters();
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: const Icon(HugeIconsSolid.calendar03),
                          onPressed: () => _selectDateRange(context),
                        ),
                      ),
                    ],
                  ),
                ),
                style: AppInputDecoration.inputTextStyle(context),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  } else if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
                    return 'Must contain only letters or digits';
                  }
                  return null;
                },
                maxLength: 20,
              ),

              if (_searchOrderController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        style: AppTheme.textSearchInfo(context),
                        children: [
                          const TextSpan(text: 'Result for "'),
                          TextSpan(
                            text: _searchOrderController.text,
                            style: AppTheme.textSearchInfoLabeled(context),
                          ),
                          const TextSpan(text: '"'),
                        ],
                      ),
                    ),
                    RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        style: AppTheme.textSearchInfoLabeled(context),
                        children: [
                          TextSpan(text: _filteredOrders.length.toString()),
                          const TextSpan(text: ' found'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 5),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_selectedOrderStatus != null)
                    Chip(
                      label: Text("Status: $_selectedOrderStatus"),
                      backgroundColor: _getStatusColor(
                        _selectedOrderStatus!,
                      ).withOpacity(0.10),
                      side: BorderSide(
                        color: _getStatusColor(
                          _selectedOrderStatus!,
                        ).withOpacity(0.3),
                      ),
                      labelStyle: AppTheme.textLabel(context).copyWith(
                        color: _getStatusColor(_selectedOrderStatus!),
                        fontSize: 10,
                      ),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 0,
                      ),
                      avatar: Icon(
                        _getStatusIcon(_selectedOrderStatus!),
                        color: _getStatusColor(_selectedOrderStatus!),
                        size: 14,
                      ),
                      onDeleted: () {
                        setState(() => _selectedOrderStatus = null);
                        _applyFilters();
                      },
                      deleteIcon: Icon(
                        HugeIconsStroke.cancel02,
                        size: 14,
                        color: _getStatusColor(_selectedOrderStatus!),
                      ),
                    ),
                  if (_selectedTransactionType != null)
                    Chip(
                      label: Text("Transaction: $_selectedTransactionType"),
                      backgroundColor: AppTheme.customListBg(context),
                      side: BorderSide(
                        color: AppTheme.customListBg(context).withOpacity(0.3),
                      ),
                      labelStyle: AppTheme.textLabel(context).copyWith(
                        color: AppTheme.iconColor(context).withOpacity(0.8),
                        fontSize: 10,
                      ),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 0,
                      ),
                      avatar: Icon(
                        HugeIconsStroke.chartIncrease,
                        color: AppTheme.iconColor(context).withOpacity(0.8),
                        size: 14,
                      ),
                      onDeleted: () {
                        setState(() => _selectedTransactionType = null);
                        _applyFilters();
                      },
                      deleteIcon: Icon(
                        HugeIconsStroke.cancel02,
                        size: 14,
                        color: AppTheme.iconColor(context).withOpacity(0.3),
                      ),
                    ),
                  if (_selectedOrderType != null)
                    Chip(
                      label: Text("Type: $_selectedOrderType"),
                      backgroundColor: _selectedOrderType == "Credit"
                          ? Colors.green.withOpacity(0.10)
                          : Colors.red.withOpacity(0.10),
                      side: BorderSide(
                        color: _selectedOrderType == "Credit"
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                      labelStyle: AppTheme.textLabel(context).copyWith(
                        color: _selectedOrderType == "Credit"
                            ? Colors.green
                            : Colors.red,
                        fontSize: 10,
                      ),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 0,
                      ),
                      avatar: Icon(
                        _selectedOrderType == "Credit"
                            ? HugeIconsStroke.moneySend01
                            : HugeIconsStroke.moneyReceive01,
                        size: 14,
                        color: _selectedOrderType == "Credit"
                            ? Colors.green
                            : Colors.red,
                      ),
                      onDeleted: () {
                        setState(() => _selectedOrderType = null);
                        _applyFilters();
                      },
                      deleteIcon: Icon(
                        HugeIconsStroke.cancel02,
                        size: 14,
                        color: _selectedOrderType == "Credit"
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    HugeIconsSolid.calendar02,
                    size: 18,
                    color: AppTheme.iconColor(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "From: ${DateFormat('yyyy-MM-dd').format(_fromDate)}  -  To: ${DateFormat('yyyy-MM-dd').format(_toDate)}",
                    style: AppTheme.textLabel(context).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingOrders
              ? const Center(child: LoadingLogo())
              : RefreshIndicator(
                  onRefresh: _refreshOrders,
                  child: _filteredOrders.isEmpty
                      ? NotFoundWidget(
                          title: "No Orders Found",
                          message:
                              "No orders found for the selected date range.",
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            final formattedDate = DateFormat(
                              'MMMM dd, yyyy',
                            ).format(order.OrderDate);
                            final formattedAmount = NumberFormat(
                              '#,###.00',
                            ).format(order.Payable);
                            final checkOrderType = order.OrderType.contains(
                              "Credit",
                            );

                            return Card(
                              margin: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: index == 0 ? 0 : 2,
                                bottom: index == _filteredOrders.length - 1
                                    ? 0
                                    : 8,
                              ),
                              color: AppTheme.customListBg(context),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailScreen(
                                        orderId: order.OrderId,
                                      ),
                                    ),
                                  );
                                },
                                leading: Text(
                                  (index + 1).toString().padLeft(2, '0'),
                                  style: const TextStyle(
                                    fontFamily: AppFontFamily.poppinsMedium,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                "Id# ",
                                                style:
                                                    AppTheme.textLabel(
                                                      context,
                                                    ).copyWith(
                                                      fontFamily: AppFontFamily
                                                          .poppinsSemiBold,
                                                      fontSize: 12,
                                                    ),
                                              ),
                                              Text(
                                                order.OrderId.toString(),
                                                style:
                                                    AppTheme.textLabel(
                                                      context,
                                                    ).copyWith(
                                                      fontFamily: AppFontFamily
                                                          .poppinsSemiBold,
                                                      fontSize: 16,
                                                    ),
                                              ),
                                              Text(
                                                " - Ref# ",
                                                style:
                                                    AppTheme.textLabel(
                                                      context,
                                                    ).copyWith(
                                                      fontFamily: AppFontFamily
                                                          .poppinsSemiBold,
                                                      fontSize: 12,
                                                    ),
                                              ),
                                              Text(
                                                order.RefNo.toString(),
                                                style:
                                                    AppTheme.textLabel(
                                                      context,
                                                    ).copyWith(
                                                      fontFamily: AppFontFamily
                                                          .poppinsSemiBold,
                                                      fontSize: 16,
                                                    ),
                                              ),
                                            ],
                                          ),

                                          Row(
                                            children: [
                                              Icon(
                                                HugeIconsStroke.userAccount,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                order.UserName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: true,

                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: AppFontFamily
                                                      .poppinsMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                HugeIconsStroke.calendar03,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                formattedDate,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: AppFontFamily
                                                      .poppinsMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    HugeIconsStroke.package,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "Qty: ${order.Quantity.toString().padLeft(2, '0')}",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontFamily: AppFontFamily
                                                          .poppinsMedium,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(width: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    checkOrderType
                                                        ? HugeIconsStroke
                                                              .moneySend01
                                                        : HugeIconsStroke
                                                              .moneyReceive01,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "${checkOrderType ? 'Credit' : 'Debit'} Amount",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontFamily: AppFontFamily
                                                          .poppinsMedium,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              order.OrderStatus,
                                            ).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getStatusIcon(
                                                  order.OrderStatus,
                                                ),
                                                size: 10,
                                                color: _getStatusColor(
                                                  order.OrderStatus,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                order.OrderStatus,
                                                style:
                                                    AppTheme.textLink(
                                                      context,
                                                    ).copyWith(
                                                      fontSize: 8,
                                                      color: _getStatusColor(
                                                        order.OrderStatus,
                                                      ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                order.TransactionType.toString()
                                                    .contains("Sale")
                                                ? Colors.green.withOpacity(0.15)
                                                : Colors.blue.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                HugeIconsStroke.chartIncrease,
                                                size: 10,
                                                color:
                                                    order.TransactionType.toString()
                                                        .contains("Sale")
                                                    ? Colors.green
                                                    : Colors.blue,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                order.TransactionType,
                                                style:
                                                    AppTheme.textLink(
                                                      context,
                                                    ).copyWith(
                                                      fontSize: 8,
                                                      color:
                                                          order.TransactionType.toString()
                                                              .contains("Sale")
                                                          ? Colors.green
                                                          : Colors.blue,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "Rs $formattedAmount",
                                          style:
                                              AppTheme.textSearchInfoLabeled(
                                                context,
                                              ).copyWith(
                                                fontFamily:
                                                    AppFontFamily.poppinsBold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
        if (_filteredOrders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: AppTheme.textSearchInfo(
                          context,
                        ).copyWith(fontSize: 14),
                        text: 'Total Credit:',
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          HugeIconsStroke.moneySend01,
                          size: 14,
                          color: AppTheme.iconColor(context),
                        ),
                        const SizedBox(width: 6),
                        RichText(
                          textAlign: TextAlign.end,
                          text: TextSpan(
                            style: AppTheme.textSearchInfoLabeled(
                              context,
                            ).copyWith(fontSize: 14),
                            text: "Rs $formattedCreditGrandTotal",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: AppTheme.textSearchInfo(
                          context,
                        ).copyWith(fontSize: 14),
                        text: 'Total Debit:',
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          HugeIconsStroke.moneyReceive01,
                          size: 14,
                          color: AppTheme.iconColor(context),
                        ),
                        const SizedBox(width: 6),
                        RichText(
                          textAlign: TextAlign.end,
                          text: TextSpan(
                            style: AppTheme.textSearchInfoLabeled(
                              context,
                            ).copyWith(fontSize: 14),
                            text: "Rs $formattedDebitGrandTotal",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _accountsPage() {
    return ListView(
      shrinkWrap: true,
      children: [
        ValueListenableBuilder<String?>(
          valueListenable: avatarNotifier,
          builder: (context, avatar, _) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.customListBg(context),
                    foregroundImage: avatar != null
                        ? AssetImage(avatar)
                        : const AssetImage("assets/images/avatars/boy_14.png"),
                  ),
                  SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${user!["FullName"]}",
                        style: AppTheme.textLabel(context).copyWith(
                          fontSize: 17,
                          fontFamily: AppFontFamily.poppinsSemiBold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "View Profile",
                        style: AppTheme.textLink(context).copyWith(
                          fontSize: 12,
                          fontFamily: AppFontFamily.poppinsRegular,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            );
          },
        ),
        Divider(thickness: 30, height: 30, color: AppTheme.dividerBg(context)),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(HugeIconsStroke.userGroup, size: 24),
          title: Text("Customers", style: AppTheme.textLabel(context)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomersScreen()),
            );
          },
        ),
        Divider(height: 1, color: AppTheme.dividerBg(context)),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(HugeIconsStroke.moneyReceiveFlow01, size: 24),
          title: Text("Payments", style: AppTheme.textLabel(context)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentsScreen()),
            );
          },
        ),
        Divider(height: 1, color: AppTheme.dividerBg(context)),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(HugeIconsStroke.recycle02, size: 24),
          title: Text("Scraps", style: AppTheme.textLabel(context)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScrapsScreen()),
            );
          },
        ),
        Divider(height: 1, color: AppTheme.dividerBg(context)),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(HugeIconsStroke.userGroup03, size: 24),
          title: Text("Users", style: AppTheme.textLabel(context)),
          onTap: () {},
        ),
        Divider(height: 1, color: AppTheme.dividerBg(context)),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(HugeIconsStroke.messageMultiple02, size: 24),
          title: Text("Messages", style: AppTheme.textLabel(context)),
          onTap: () {},
        ),
        Divider(thickness: 30, height: 30, color: AppTheme.dividerBg(context)),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? HugeIconsStroke.moon02
                : HugeIconsStroke.sun02,
            size: 24,
          ),
          title: Text(
            Theme.of(context).brightness == Brightness.dark
                ? "Dark Mode"
                : "Light Mode",
            style: AppTheme.textLabel(context),
          ),
          trailing: Switch(
            value: ThemeController.themeNotifier.value == ThemeMode.dark,
            onChanged: (value) {
              ThemeController.setTheme(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
          onTap: () {
            final isDark =
                ThemeController.themeNotifier.value == ThemeMode.dark;
            ThemeController.setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
          },
        ),
        Divider(height: 1, color: AppTheme.dividerBg(context)),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(HugeIconsStroke.crown03, size: 24),
          title: Text("Subscription", style: AppTheme.textLabel(context)),
          onTap: () {},
        ),
        Divider(height: 1, color: AppTheme.dividerBg(context)),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(HugeIconsStroke.note, size: 24),
          title: Text("Privacy Policy", style: AppTheme.textLabel(context)),
          onTap: () {},
        ),
        Divider(height: 1, color: AppTheme.dividerBg(context)),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(HugeIconsStroke.headset, size: 24),
          title: Text("Help Center", style: AppTheme.textLabel(context)),
          onTap: () {},
        ),
        Divider(height: 1, color: AppTheme.dividerBg(context)),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(HugeIconsStroke.chartBreakoutCircle, size: 24),
          title: Text(
            "About Y2K Solutions",
            style: AppTheme.textLabel(context),
          ),
          onTap: () {},
        ),
        Divider(height: 1, color: AppTheme.dividerBg(context)),
        const SizedBox(height: 50),
        ListTile(
          title: OutlineErrorButton(
            text: 'Log Out',
            onPressed: () {
              DialogLogout().showDialog(context, _logout);
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _ledgersPage() {
    final Map<String, List<dynamic>> groupedLedgers = {};

    for (var ledger in _allLedgers) {
      final formattedDate = DateFormat(
        'MMMM dd, yyyy',
      ).format(DateTime.parse(ledger.Date));
      groupedLedgers.putIfAbsent(formattedDate, () => []);
      groupedLedgers[formattedDate]!.add(ledger);
    }
    double grandCreditTotal = _allLedgers.fold(
      0.0,
      (prev, l) => prev + l.Credit,
    );
    double grandDebitTotal = _allLedgers.fold(0.0, (prev, l) => prev + l.Debit);

    final formattedCreditGrandTotal = NumberFormat(
      '#,###.00',
    ).format(grandCreditTotal);
    final formattedDebitGrandTotal = NumberFormat(
      '#,###.00',
    ).format(grandDebitTotal);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomerSearchField(
                customers: _allCustomers,
                onSelected: (customer) {
                  setState(() => _selectedCustomerId = customer);
                  _loadLedgers();
                },
                onDateRangeTap: () => _selectDateRangeLedger(context),
                ledgerLength: _allLedgers.length,
                onWhatsappTap: () {
                  PdfBottomSheet.showPdfPreview(
                    context,
                    "https://y2ksolutions.com/Logbook/LedgerPrint?UserId=${_selectedCustomerId?.UserId}&OrganizationId=${user?["OrganizationId"]}&FromDate=${DateFormat('yyyy-MM-dd').format(_fromDateLedger)}&ToDate=${DateFormat('yyyy-MM-dd').format(_toDateLedger)}", // API URL
                    "${_selectedCustomerId?.UserName}-Ledger Reciept-${DateFormat('yyyy-MM-dd').format(_fromDateLedger)}-${DateFormat('yyyy-MM-dd').format(_toDateLedger)}",
                    "${_selectedCustomerId?.PhoneNo}",
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    HugeIconsSolid.calendar02,
                    size: 18,
                    color: AppTheme.iconColor(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "From: ${DateFormat('yyyy-MM-dd').format(_fromDateLedger)}  -  To: ${DateFormat('yyyy-MM-dd').format(_toDateLedger)}",
                    style: AppTheme.textLabel(context).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoadingLedgers
              ? const Center(child: LoadingLogo())
              : RefreshIndicator(
                  onRefresh: _refreshLedgers,
                  child: _allLedgers.isEmpty
                      ? NotFoundWidget(
                          title: "No Ledgers Found",
                          message:
                              "No ledgers found for the selected date range & user",
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: groupedLedgers.keys.length,
                          itemBuilder: (context, index) {
                            final dateKey = groupedLedgers.keys.elementAt(
                              index,
                            );
                            final ledgersForDate = groupedLedgers[dateKey]!;

                            return Card(
                              margin: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: index == 0 ? 0 : 2,
                                bottom: index == groupedLedgers.keys.length - 1
                                    ? 0
                                    : 8,
                              ),
                              color: AppTheme.customListBg(context),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 15,
                                  right: 15,
                                  top: 15,
                                  bottom: 5,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateKey,
                                      style: AppTheme.textLabel(context)
                                          .copyWith(
                                            fontFamily:
                                                AppFontFamily.poppinsSemiBold,
                                            fontSize: 16,
                                          ),
                                    ),
                                    const SizedBox(height: 8),

                                    // 🔁 Nested list of ledgers for this date
                                    ...ledgersForDate.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final ledger = entry.value;
                                      final formattedCreditAmount =
                                          NumberFormat(
                                            '#,##0.00',
                                          ).format(ledger.Credit.toInt());
                                      final formattedDebitAmount = NumberFormat(
                                        '#,##0.00',
                                      ).format(ledger.Debit.toInt());
                                      final checkLedgerType =
                                          ledger.Credit.toInt() == 0;

                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom:
                                                index ==
                                                    ledgersForDate.length - 1
                                                ? BorderSide.none
                                                : BorderSide(
                                                    color: AppTheme.dividerBg(
                                                      context,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          onTap: () {
                                            if (ledger.SourceType.contains(
                                                  'Sale',
                                                ) ||
                                                ledger.SourceType.contains(
                                                  'Purchase',
                                                )) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      OrderDetailScreen(
                                                        orderId: ledger.Id,
                                                      ),
                                                ),
                                              );
                                            } else {
                                              AppSnackBar.show(
                                                context,
                                                message:
                                                    'No details available for this ledger',
                                                type: AppSnackBarType.warning,
                                              );
                                            }
                                          },

                                          title: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    "Source",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontFamily: AppFontFamily
                                                          .poppinsMedium,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: checkLedgerType
                                                          ? Colors.blue
                                                                .withOpacity(
                                                                  0.15,
                                                                )
                                                          : Colors.green
                                                                .withOpacity(
                                                                  0.15,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          checkLedgerType
                                                              ? HugeIconsStroke
                                                                    .chartIncrease
                                                              : HugeIconsStroke
                                                                    .chartDecrease,
                                                          size: 10,
                                                          color: checkLedgerType
                                                              ? Colors.blue
                                                              : Colors.green,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          ledger.SourceType,
                                                          style:
                                                              AppTheme.textLink(
                                                                context,
                                                              ).copyWith(
                                                                fontSize: 8,
                                                                color:
                                                                    checkLedgerType
                                                                    ? Colors
                                                                          .blue
                                                                    : Colors
                                                                          .green,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    "Type",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontFamily: AppFontFamily
                                                          .poppinsMedium,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${(ledger.SourceType.contains('Sale') || ledger.SourceType.contains('Purchase')) ? 'Id#${ledger.Id} - Ref#' : ''}${ledger.RefOrPaymentType}",
                                                    style:
                                                        AppTheme.textSearchInfoLabeled(
                                                          context,
                                                        ).copyWith(
                                                          fontSize: 13,
                                                          fontFamily:
                                                              AppFontFamily
                                                                  .poppinsBold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    checkLedgerType
                                                        ? "Debit"
                                                        : "Credit",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontFamily: AppFontFamily
                                                          .poppinsMedium,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Rs ${checkLedgerType ? formattedDebitAmount : formattedCreditAmount}",
                                                    style:
                                                        AppTheme.textSearchInfoLabeled(
                                                          context,
                                                        ).copyWith(
                                                          fontSize: 13,
                                                          fontFamily:
                                                              AppFontFamily
                                                                  .poppinsBold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    "Balance",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontFamily: AppFontFamily
                                                          .poppinsMedium,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Rs ${ledger.Balance}",
                                                    style:
                                                        AppTheme.textSearchInfoLabeled(
                                                          context,
                                                        ).copyWith(
                                                          fontSize: 13,
                                                          fontFamily:
                                                              AppFontFamily
                                                                  .poppinsBold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),

        // 💰 Totals
        if (_allLedgers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildTotalRow(
                  context,
                  'Total Credit:',
                  formattedCreditGrandTotal,
                  HugeIconsStroke.moneySend01,
                ),
                const SizedBox(height: 6),
                _buildTotalRow(
                  context,
                  'Total Debit:',
                  formattedDebitGrandTotal,
                  HugeIconsStroke.moneyReceive01,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTotalRow(
    BuildContext context,
    String label,
    String amount,
    IconData icon,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.textSearchInfo(context).copyWith(fontSize: 14),
        ),
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.iconColor(context)),
            const SizedBox(width: 6),
            Text(
              "Rs $amount",
              style: AppTheme.textSearchInfoLabeled(
                context,
              ).copyWith(fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages();
    return Scaffold(
      body: ZoomDrawer(
        controller: _drawerController,
        menuScreen: MenuDrawer(
          currentIndex: _currentIndex,
          onItemSelected: (index) {
            setState(() => _currentIndex = index);
            _drawerController.toggle!();
          },
        ),
        mainScreen: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(HugeIconsStroke.menu02, size: 22),
                      onPressed: () => _drawerController.toggle!(),
                    ),
                    const SizedBox(width: 5),
                    Image.asset(
                      AppTheme.appLogo(context),
                      height: 120,
                      width: 60,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "My",
                      style: AppTheme.textTitle(context).copyWith(
                        fontSize: 20,
                        fontFamily: AppFontFamily.poppinsBold,
                      ),
                    ),
                    Text(
                      menus[_currentIndex],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.textTitle(context).copyWith(
                        fontSize: 20,
                        fontFamily: AppFontFamily.poppinsLight,
                      ),
                    ),
                    Text(
                      ".",
                      style: AppTheme.textTitleActive(
                        context,
                      ).copyWith(fontSize: 30),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (_currentIndex == 1) ...[
                IconButton(
                  icon: const Icon(HugeIconsStroke.refresh, size: 20),
                  onPressed: _refreshOrders,
                ),
                IconButton(
                  icon: const Icon(HugeIconsStroke.filterHorizontal, size: 20),
                  onPressed: _showFilterSheet,
                ),
              ],
              if (_currentIndex == 2)
                IconButton(
                  icon: const Icon(HugeIconsStroke.refresh, size: 20),
                  onPressed: () {
                    _refreshLedgers();
                  },
                ),
              IconButton(
                onPressed: () {
                  DialogLogout().showDialog(context, _logout);
                },
                icon: const Icon(HugeIconsStroke.logout02, size: 20),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: user == null
              ? const Center(child: LoadingLogo())
              : IndexedStack(index: _currentIndex, children: _pages()),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            elevation: 0,
            iconSize: 24,
            landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
            selectedLabelStyle: AppTheme.textLabel(
              context,
            ).copyWith(fontSize: 12),
            unselectedLabelStyle: AppTheme.textLabel(
              context,
            ).copyWith(fontSize: 11),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            selectedItemColor: AppTheme.onBoardingDotActive(context),
            unselectedItemColor: AppTheme.onBoardingDot(context),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(HugeIconsStroke.home11),
                activeIcon: Icon(HugeIconsSolid.home11),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(HugeIconsStroke.shoppingBasket01),
                activeIcon: Icon(HugeIconsSolid.shoppingBasket01),
                label: "Orders",
              ),
              BottomNavigationBarItem(
                icon: Icon(HugeIconsStroke.userMultiple02),
                activeIcon: Icon(HugeIconsSolid.userMultiple02),
                label: "Ledgers",
              ),
              BottomNavigationBarItem(
                icon: Icon(HugeIconsStroke.user03),
                activeIcon: Icon(HugeIconsSolid.user03),
                label: "Accounts",
              ),
            ],
          ),
        ),
        borderRadius: 24.0,
        showShadow: true,
        angle: -8.0,
        mainScreenScale: 0.05, // slightly more zoom-in effect
        shadowLayer1Color: AppTheme.customListBg(context).withOpacity(0.5),
        shadowLayer2Color: AppTheme.customListBg(context).withOpacity(1.0),
        mainScreenTapClose: true,
        // overlayBlur: 0.8,
        slideWidth: MediaQuery.of(context).size.width * 0.85,
        menuBackgroundColor: Colors.transparent,
        openCurve: Curves.fastOutSlowIn,
        closeCurve: Curves.easeInBack,
      ),
    );
  }
}
