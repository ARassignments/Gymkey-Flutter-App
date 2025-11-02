import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import '/components/appsnackbar.dart';
import '/components/dialog_scrap_reciept.dart';
import '/Models/customer_single_model.dart';
import '/Models/scrap_model.dart';
import '/components/loading_screen.dart';
import '/components/not_found.dart';
import '/services/api_service.dart';
import '/theme/theme.dart';
import '/utils/session_manager.dart';

class ScrapsScreen extends StatefulWidget {
  const ScrapsScreen({super.key});

  @override
  State<ScrapsScreen> createState() => _ScrapsScreenState();
}

class _ScrapsScreenState extends State<ScrapsScreen> {
  String? token;
  Map<String, dynamic>? user;
  CustomerSingleModel? _customer;

  //Customers Screen
  late List<ScrapModel> _allScraps = [];
  List<ScrapModel> _filteredScraps = [];
  bool _isLoadingScraps = true;
  bool _isRefreshingScraps = false;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSession();
    _loadScraps();
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

  Future<void> _loadScraps() async {
    setState(() => _isLoadingScraps = true);
    try {
      final fromDateFormatted = DateFormat('yyyy-MM-dd').format(_fromDate);
      final toDateFormatted = DateFormat('yyyy-MM-dd').format(_toDate);
      final response = await ApiService.getAllScraps(
        fromDate: fromDateFormatted,
        toDate: toDateFormatted,
      );

      setState(() {
        _allScraps = response.scraps;
        _filteredScraps = List.from(_allScraps);
      });
    } catch (e) {
      debugPrint("❌ Error fetching scraps: $e");
    } finally {
      setState(() => _isLoadingScraps = false);
    }
  }

  Future<void> fetchCustomer(ScrapModel scrap) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Container(
        color: AppTheme.screenBg(context),
        child: const Center(child: LoadingLogo()),
      ),
    );
    try {
      final id = scrap.UserAccountId;
      final customer = await ApiService.getSingleCustomer(id);
      if (!mounted) return;

      Navigator.pop(context);
      setState(() {
        _customer = customer;
        ScrapReceiptBottomSheet.showRecieptPreview(
          context,
          scrap,
          "https://www.y2ksolutions.com/Scrap/ScrapPrint/${scrap.Id}",
          "${scrap.UserName}-${user!["FullName"]}-Scrap Reciept-${scrap.CreatedAt}-ID_${scrap.Id}",
          customer,
        );
      });
    } catch (e) {
      debugPrint("❌ Error fetching customer: $e");
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _refreshScraps() async {
    setState(() {
      _isRefreshingScraps = true;
      _resetFilters(); // ✅ reset filters & search before reload
    });
    await _loadScraps();
    setState(() => _isRefreshingScraps = false);
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

      await _loadScraps();
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredScraps = _allScraps.where((scrap) {
        final searchMatch =
            _searchController.text.trim().isEmpty ||
            scrap.UserName.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            scrap.Id.toString().contains(_searchController.text.toLowerCase());

        return searchMatch;
      }).toList();
    });
  }

  void _resetFilters() {
    _searchController.clear();
    _filteredScraps = List.from(_allScraps);
  }

  Widget _scrapPage() {
    double paidTotal = _filteredScraps
        .where((p) => p.OrderType.toString().toLowerCase().contains("Sale"))
        .fold(0.0, (sum, p) => sum + p.TotalPrice);

    double unpaidTotal = _filteredScraps
        .where((p) => !p.OrderType.toString().toLowerCase().contains("Sale"))
        .fold(0.0, (sum, p) => sum + p.TotalPrice);
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
                          TextSpan(text: _filteredScraps.length.toString()),
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
          child: _isLoadingScraps
              ? const Center(child: LoadingLogo())
              : RefreshIndicator(
                  onRefresh: () => _refreshScraps(),
                  child: _filteredScraps.isEmpty
                      ? NotFoundWidget(
                          title: "No Scraps Found",
                          message:
                              "No scraps found for the selected date range.",
                        )
                      : SlidableAutoCloseBehavior(
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _filteredScraps.length,
                            itemBuilder: (context, index) {
                              final scrap = _filteredScraps[index];
                              final formattedDate = DateFormat(
                                'MMMM dd, yyyy',
                              ).format(scrap.CreatedAt);
                              final formattedAmount = NumberFormat(
                                '#,###.00',
                              ).format(scrap.TotalPrice);

                              return Padding(
                                padding: EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: index == 0 ? 0 : 2,
                                  bottom: index == _filteredScraps.length - 1
                                      ? 0
                                      : 2,
                                ),
                                child: Slidable(
                                  key: ValueKey(scrap.Id),
                                  endActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    extentRatio: 0.2,
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            Slidable.of(context)?.close();
                                            fetchCustomer(scrap);
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.cardBg(context),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            height: double.infinity,
                                            child: const Icon(
                                              HugeIconsSolid.navigation03,
                                              color: Color(0xFF4facfe),
                                              size: 24,
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
                                                      scrap.Id.toString(),
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
                                                      scrap.UserName,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      softWrap: true,

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
                                                      "Qty: ${scrap.Items}",
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
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          HugeIconsStroke
                                                              .moneyBag02,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          "${NumberFormat('#,###.00').format(scrap.Price)} X ${scrap.Quantity}Kg",
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
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
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
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
                                              SizedBox(height: 5),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      scrap.OrderType.toString()
                                                          .contains("Purchase")
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
                                                      scrap.OrderType.toString()
                                                              .contains(
                                                                "Purchase",
                                                              )
                                                          ? HugeIconsStroke
                                                                .chartIncrease
                                                          : HugeIconsStroke
                                                                .chartDecrease,
                                                      size: 10,
                                                      color:
                                                          scrap.OrderType.toString()
                                                              .contains(
                                                                "Purchase",
                                                              )
                                                          ? Colors.green
                                                          : Colors.blue,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      scrap.OrderType,
                                                      style:
                                                          AppTheme.textLink(
                                                            context,
                                                          ).copyWith(
                                                            fontSize: 8,
                                                            color:
                                                                scrap.OrderType.toString()
                                                                    .contains(
                                                                      "Purchase",
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

        SizedBox(height: 20),
        // if (_filteredScraps.isNotEmpty)
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //   child: Column(
        //     children: [
        //       Row(
        //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //         children: [
        //           RichText(
        //             textAlign: TextAlign.start,
        //             maxLines: 1,
        //             overflow: TextOverflow.ellipsis,
        //             text: TextSpan(
        //               style: AppTheme.textSearchInfo(
        //                 context,
        //               ).copyWith(fontSize: 14),
        //               text: 'Total Sale:',
        //             ),
        //           ),
        //           Row(
        //             children: [
        //               Icon(
        //                 HugeIconsStroke.moneySend01,
        //                 size: 14,
        //                 color: AppTheme.iconColor(context),
        //               ),
        //               const SizedBox(width: 6),
        //               RichText(
        //                 textAlign: TextAlign.end,
        //                 text: TextSpan(
        //                   style: AppTheme.textSearchInfoLabeled(
        //                     context,
        //                   ).copyWith(fontSize: 14),
        //                   text: "Rs $formattedPaidTotal",
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ],
        //       ),
        //       Row(
        //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //         children: [
        //           RichText(
        //             textAlign: TextAlign.start,
        //             maxLines: 1,
        //             overflow: TextOverflow.ellipsis,
        //             text: TextSpan(
        //               style: AppTheme.textSearchInfo(
        //                 context,
        //               ).copyWith(fontSize: 14),
        //               text: 'Total Purchase:',
        //             ),
        //           ),
        //           Row(
        //             children: [
        //               Icon(
        //                 HugeIconsStroke.moneyReceive01,
        //                 size: 14,
        //                 color: AppTheme.iconColor(context),
        //               ),
        //               const SizedBox(width: 6),
        //               RichText(
        //                 textAlign: TextAlign.end,
        //                 text: TextSpan(
        //                   style: AppTheme.textSearchInfoLabeled(
        //                     context,
        //                   ).copyWith(fontSize: 14),
        //                   text: "Rs $formattedUnPaidTotal",
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ],
        //       ),
        //     ],
        //   ),
        // ),
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
          "Scraps",
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
              _refreshScraps();
            },
          ),
        ],
      ),
      body: user == null ? const Center(child: LoadingLogo()) : _scrapPage(),
    );
  }
}
