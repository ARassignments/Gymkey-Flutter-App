import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import '/components/dialog_payment_reciept.dart';
import '/Models/customer_single_model.dart';
import '/components/appsnackbar.dart';
import '/Models/payment_model.dart';
import '/components/loading_screen.dart';
import '/components/not_found.dart';
import '/services/api_service.dart';
import '/theme/theme.dart';
import '/utils/session_manager.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String? token;
  Map<String, dynamic>? user;
  CustomerSingleModel? _customer;

  //Payment Screen
  late List<PaymentModel> _allPayments = [];
  List<PaymentModel> _filteredPayments = [];
  bool _isLoadingPayments = true;
  bool _isRefreshingPayments = false;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSession();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    token = await SessionManager.getUserToken();
    user = await SessionManager.getUser();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoadingPayments = true);
    try {
      final fromDateFormatted = DateFormat('yyyy-MM-dd').format(_fromDate);
      final toDateFormatted = DateFormat('yyyy-MM-dd').format(_toDate);
      final response = await ApiService.getAllPayments(
        fromDate: fromDateFormatted,
        toDate: toDateFormatted,
      );

      setState(() {
        _allPayments = response.payments;
        _filteredPayments = List.from(_allPayments);
      });
    } catch (e) {
      debugPrint("❌ Error fetching payments: $e");
    } finally {
      setState(() => _isLoadingPayments = false);
    }
  }

  Future<void> fetchCustomer(PaymentModel payment, bool reciptPreview) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Container(
        color: AppTheme.screenBg(context),
        child: const Center(child: LoadingLogo()),
      ),
    );
    try {
      final id = payment.UserId;
      final customer = await ApiService.getSingleCustomer(id);
      if (!mounted) return;

      Navigator.pop(context);
      setState(() {
        _customer = customer;
        PaymentReceiptBottomSheet.showRecieptPreview(
          context,
          payment,
          "https://www.y2ksolutions.com/Payment/PaymentPrint/${payment.Id}",
          "${payment.UserName}-${user!["FullName"]}-Payment_Reciept-${DateFormat('dd-MMM-yyyy').format(payment.PaymentDate)}_#${payment.Id}",
          customer,
          reciptPreview,
        );
      });
    } catch (e) {
      debugPrint("❌ Error fetching customer: $e");
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _refreshPayments() async {
    setState(() {
      _isRefreshingPayments = true;
      _resetFilters(); // ✅ reset filters & search before reload
    });
    await _loadPayments();
    setState(() => _isRefreshingPayments = false);
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
        _fromDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _toDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });

      await _loadPayments();
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPayments = _allPayments.where((payment) {
        final searchMatch =
            _searchController.text.trim().isEmpty ||
            payment.UserName.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            payment.Id.toString().contains(
              _searchController.text.toLowerCase(),
            );

        return searchMatch;
      }).toList();
    });
  }

  void _resetFilters() {
    _searchController.clear();
    _filteredPayments = List.from(_allPayments);
  }

  Widget _paymentPage() {
    double paidTotal = _filteredPayments
        .where(
          (p) => p.PaymentMode.toString().toLowerCase().contains("recived"),
        )
        .fold(0.0, (sum, p) => sum + p.Payment);

    double unpaidTotal = _filteredPayments
        .where(
          (p) => !p.PaymentMode.toString().toLowerCase().contains("recived"),
        )
        .fold(0.0, (sum, p) => sum + p.Payment);
    final formattedPaidTotal = NumberFormat('#,###.00').format(paidTotal);
    final formattedUnPaidTotal = NumberFormat('#,###.00').format(unpaidTotal);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _searchController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'Search Here',
                  hintText: 'Search by name or id no',
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

              if (_searchController.text.trim().isNotEmpty) ...[
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
                            text: _searchController.text,
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
                          TextSpan(text: _filteredPayments.length.toString()),
                          const TextSpan(text: ' found'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

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
                    "From: ${DateFormat('yyyy-MM-dd').format(_fromDate)}  -  To: ${DateFormat('yyyy-MM-dd').format(_toDate)}",
                    style: AppTheme.textLabel(context).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingPayments
              ? const Center(child: LoadingLogo())
              : RefreshIndicator(
                  onRefresh: _refreshPayments,
                  child: _filteredPayments.isEmpty
                      ? NotFoundWidget(
                          title: "No Payments Found",
                          message:
                              "No payments found for the selected date range.",
                        )
                      : SlidableAutoCloseBehavior(
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _filteredPayments.length,
                            itemBuilder: (context, index) {
                              final payment = _filteredPayments[index];
                              final formattedDate = DateFormat(
                                'MMMM dd, yyyy',
                              ).format(payment.PaymentDate);
                              final formattedAmount = NumberFormat(
                                '#,###.00',
                              ).format(payment.Payment);

                              return Padding(
                                padding: EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: index == 0 ? 0 : 2,
                                  bottom: index == _filteredPayments.length - 1
                                      ? 0
                                      : 2,
                                ),
                                child: Slidable(
                                  key: ValueKey(payment.Id),
                                  endActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    extentRatio: 0.4,
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            Slidable.of(context)?.close();
                                            fetchCustomer(payment, false);
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.customListBg(
                                                context,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            height: double.infinity,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  HugeIconsSolid.pdf02,
                                                  color: Color(0xFFC41F1F),
                                                  size: 24,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            Slidable.of(context)?.close();
                                            fetchCustomer(payment, true);
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.customListBg(
                                                context,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            height: double.infinity,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  HugeIconsSolid.invoice02,
                                                  color:
                                                      AppTheme.iconColorThree(
                                                        context,
                                                      ),
                                                  size: 24,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  child: Card(
                                    color: AppTheme.customListBg(context),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      onLongPress: () {
                                        AppSnackBar.show(
                                          context,
                                          message: "Hola Bola",
                                          type: AppSnackBarType.error,
                                        );
                                      },
                                      leading: Text(
                                        (index + 1).toString().padLeft(2, '0'),
                                        style: const TextStyle(
                                          fontFamily:
                                              AppFontFamily.poppinsMedium,
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
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .poppinsSemiBold,
                                                            fontSize: 12,
                                                          ),
                                                    ),
                                                    Text(
                                                      payment.Id.toString(),
                                                      style:
                                                          AppTheme.textLabel(
                                                            context,
                                                          ).copyWith(
                                                            fontFamily:
                                                                AppFontFamily
                                                                    .poppinsSemiBold,
                                                            fontSize: 16,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      HugeIconsStroke
                                                          .userAccount,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      payment.UserName,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontFamily:
                                                            AppFontFamily
                                                                .poppinsMedium,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      HugeIconsStroke
                                                          .calendar03,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      formattedDate,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontFamily:
                                                            AppFontFamily
                                                                .poppinsMedium,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      HugeIconsStroke.package,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "Payment Type: ${payment.PaymentType}",
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontFamily:
                                                            AppFontFamily
                                                                .poppinsMedium,
                                                      ),
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      payment
                                                          .PaymentMode.contains(
                                                        "Recived",
                                                      )
                                                      ? Colors.green
                                                            .withOpacity(0.15)
                                                      : Colors.blue.withOpacity(
                                                          0.15,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      payment.PaymentMode.contains(
                                                            "Recived",
                                                          )
                                                          ? HugeIconsStroke
                                                                .chartIncrease
                                                          : HugeIconsStroke
                                                                .chartDecrease,
                                                      size: 10,
                                                      color:
                                                          payment
                                                              .PaymentMode.contains(
                                                            "Recived",
                                                          )
                                                          ? Colors.green
                                                          : Colors.blue,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      payment.PaymentMode,
                                                      style:
                                                          AppTheme.textLink(
                                                            context,
                                                          ).copyWith(
                                                            fontSize: 8,
                                                            color:
                                                                payment
                                                                    .PaymentMode.contains(
                                                                  "Recived",
                                                                )
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
                                                      fontFamily: AppFontFamily
                                                          .poppinsBold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
        ),
        if (_filteredPayments.isNotEmpty)
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
                        text: 'Total Paid:',
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
                            text: "Rs $formattedUnPaidTotal",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                        text: 'Total Recieved:',
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
                            text: "Rs $formattedPaidTotal",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
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
          "Payments",
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
              _refreshPayments();
            },
          ),
        ],
      ),
      body: user == null ? const Center(child: LoadingLogo()) : _paymentPage(),
    );
  }
}
