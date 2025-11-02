import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import '/Models/customer_model.dart';
import '/components/loading_screen.dart';
import '/components/not_found.dart';
import '/responses/customer_response.dart';
import '/screens/customer_detail_screen.dart';
import '/services/api_service.dart';
import '/theme/theme.dart';
import '/utils/session_manager.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String? token;
  Map<String, dynamic>? user;

  //Customers Screen
  late Future<CustomerResponse> _futureCustomers;
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSessionAndCustomers();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
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
    _applySorting();
  }

  void _applySorting() {
    setState(() {
      _filteredCustomers.sort((a, b) {
        final comp = a.UserName.toLowerCase().compareTo(
          b.UserName.toLowerCase(),
        );
        return _isAscending ? comp : -comp;
      });
    });
  }

  void _toggleSorting() {
    setState(() {
      _isAscending = !_isAscending;
    });
    _applySorting();
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

  Widget _customersPage() {
    double grandTotal = _filteredCustomers.fold(
      0.0,
      (previousValue, customer) => previousValue + customer.OpeningBalance,
    );
    final formattedGrandTotal = NumberFormat('#,###.00').format(grandTotal);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              TextFormField(
                controller: _searchController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'Search Here',
                  hintText: 'Search by name or city',
                  counter: const SizedBox.shrink(),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Icon(HugeIconsSolid.search01),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(HugeIconsStroke.cancel02),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: Icon(
                            _isAscending
                                ? HugeIconsSolid.sortByDown01
                                : HugeIconsSolid.sortByUp01,
                          ),
                          tooltip: _isAscending ? "Sort Z → A" : "Sort A → Z",
                          onPressed: _toggleSorting,
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
                  } else if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                    return 'Must contain only letters';
                  }
                  return null;
                },
                maxLength: 20,
              ),
              if (_searchController.text.trim().isNotEmpty) ...[
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        style: AppTheme.textSearchInfo(context),
                        children: [
                          TextSpan(text: 'Result for "'),
                          TextSpan(
                            text: _searchController.text,
                            style: AppTheme.textSearchInfoLabeled(context),
                          ),
                          TextSpan(text: '"'),
                        ],
                      ),
                    ),
                    RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        style: AppTheme.textSearchInfoLabeled(context),
                        children: [
                          TextSpan(text: _filteredCustomers.length.toString()),
                          TextSpan(text: ' found'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _isRefreshing
              ? const Center(child: LoadingLogo())
              : RefreshIndicator(
                  onRefresh: _refreshCustomers,
                  backgroundColor: Colors.transparent,
                  child: _filteredCustomers.isEmpty
                      ? NotFoundWidget(
                          title: "No Customers Found",
                          message:
                              "Sorry, the keyword you entered cannot be found, please check again or search wit another keyword.",
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            final formattedBalance = NumberFormat(
                              '#,###.00',
                            ).format(customer.OpeningBalance);

                            return Card(
                              margin: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: index == 0 ? 0 : 2,
                                bottom: index == _filteredCustomers.length - 1
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
                                      builder: (context) =>
                                          CustomerDetailScreen(
                                            customer: customer,
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
                                title: Text(
                                  customer.UserName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.textLabel(context).copyWith(
                                    fontFamily: AppFontFamily.poppinsSemiBold,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(
                                      HugeIconsStroke.mapsLocation02,
                                      size: 14,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      customer.CityName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily:
                                            AppFontFamily.poppinsRegular,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  "Rs $formattedBalance",
                                  style: AppTheme.textSearchInfoLabeled(context)
                                      .copyWith(
                                        fontFamily: AppFontFamily.poppinsBold,
                                      ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
        if (_filteredCustomers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 10,
              bottom: 20,
            ),
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
                        text: 'Total Balance:',
                      ),
                    ),
                    RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        style: AppTheme.textSearchInfoLabeled(
                          context,
                        ).copyWith(fontSize: 14),
                        text: "Rs $formattedGrandTotal",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: true,
        title: Text(
          "Customers",
          style: AppTheme.textTitle(
            context,
          ).copyWith(fontSize: 20, fontFamily: AppFontFamily.poppinsLight),
        ),
        leading: IconButton(
          icon: const Icon(HugeIconsStroke.arrowLeft01, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(HugeIconsStroke.refresh, size: 20),
            onPressed: () {
              _refreshCustomers();
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: LoadingLogo())
          : _customersPage(),
    );
  }
}
