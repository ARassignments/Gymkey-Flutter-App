import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '/components/appsnackbar.dart';
import '/components/dialog_orderdetail_pdf.dart';
import '/utils/session_manager.dart';
import '/theme/theme.dart';
import '../components/loading_screen.dart';
import '../responses/order_detail_response.dart';
import '../services/api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String? token;
  Map<String, dynamic>? user;
  final GlobalKey _screenshotKey = GlobalKey();
  bool _isDownloading = false;

  late Future<OrderDetailResponse> _futureDetail;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _futureDetail = ApiService.getOrderDetail(widget.orderId);
  }

  Future<void> _loadSession() async {
    final t = await SessionManager.getUserToken();
    final u = await SessionManager.getUser();
    setState(() {
      token = t;
      user = u;
    });
  }

  String _formatDate(String dateString) {
    try {
      final inputFormat = DateFormat("dd/MMM/yyyy");
      final dateTime = inputFormat.parse(dateString);
      final outputFormat = DateFormat("MMMM dd, yyyy");
      return outputFormat.format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  String formatInternationalPhone(String number) {
    if (number.startsWith("0")) {
      number = number.substring(1);
    }
    return "+92 ${number.substring(0, 3)} ${number.substring(3, 7)}${number.substring(7)}";
  }

  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      AppSnackBar.show(
        context,
        message: "Cannot launch dialer",
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, BuildContext context) async {
    final String formattedNumber = phoneNumber
        .replaceAll("+", "")
        .replaceAll(" ", "");
    final Uri whatsappUri = Uri.parse("https://wa.me/$formattedNumber");

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      AppSnackBar.show(
        context,
        message: "Cannot open WhatsApp",
        type: AppSnackBarType.error,
      );
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderDetailResponse>(
      future: _futureDetail,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: LoadingLogo()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        final detail = snapshot.data!;
        final order = detail.orderDetails.first;
        final items = detail.orderItems;
        final numberCheck =
            order.Contact.toString() == "00" || order.Contact.toString() == "0";
        final checkOrderType = items.first.OrderType.contains("Credit");

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            centerTitle: true,
            title: Text(
              "Order Detail",
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
                onPressed: () {
                  PdfBottomSheet.showPdfPreview(
                    context,
                    "https://y2ksolutions.com/Order/OrderInvoiceView/${order.Id}", // API URL
                    "${order.UserName}-${user!["FullName"]}-Order Reciept-${_formatDate(order.OrderDate)}-ID_${order.Id}",
                    order.Contact,
                  );
                },
                icon: const Icon(HugeIconsStroke.pdf01, size: 20),
              ),
              if (!numberCheck)
                PopupMenuButton<String>(
                  color: AppTheme.cardDarkBg(context),
                  elevation: 10,
                  shadowColor: Colors.black26,
                  icon: const Icon(
                    HugeIconsStroke.moreVerticalCircle01,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == "call") {
                      _makePhoneCall(order.Contact, context);
                    } else if (value == "whatsapp") {
                      _openWhatsApp(order.Contact, context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: "call",
                      child: Row(
                        children: [
                          Icon(HugeIconsStroke.call02, size: 18),
                          SizedBox(width: 8),
                          Text("Call", style: AppTheme.textLabel(context)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "whatsapp",
                      child: Row(
                        children: [
                          Icon(
                            HugeIconsStroke.whatsapp,
                            size: 18,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Call via WhatsApp",
                            style: AppTheme.textLabel(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: _screenshotKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg(context),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            boxShadow: null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        HugeIconsStroke.userAccount,
                                        size: 18,
                                        color: AppTheme.iconColor(context),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "ID# ${order.Id}",
                                        style: AppTheme.textLabel(
                                          context,
                                        ).copyWith(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        order.OrderStatus,
                                      ).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getStatusIcon(order.OrderStatus),
                                          size: 12,
                                          color: _getStatusColor(
                                            order.OrderStatus,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          order.OrderStatus,
                                          style: AppTheme.textLink(context)
                                              .copyWith(
                                                fontSize: 10,
                                                color: _getStatusColor(
                                                  order.OrderStatus,
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order.UserName,
                                // maxLines: 1,
                                // overflow: TextOverflow.ellipsis,
                                style: AppTheme.textTitle(
                                  context,
                                ).copyWith(fontSize: 20),
                              ),
                              SizedBox(height: 10),
                              if (!numberCheck)
                                Row(
                                  children: [
                                    Icon(
                                      HugeIconsStroke.call02,
                                      size: 15,
                                      color: AppTheme.iconColorTwo(context),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatInternationalPhone(order.Contact),
                                      style: AppTheme.textSearchInfoLabeled(
                                        context,
                                      ).copyWith(fontSize: 14),
                                    ),
                                  ],
                                ),
                              if (!order.Address.toString().contains("Null"))
                                Row(
                                  children: [
                                    Icon(
                                      HugeIconsStroke.mapsLocation02,
                                      size: 15,
                                      color: AppTheme.iconColorTwo(context),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        order.Address,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.textSearchInfoLabeled(
                                          context,
                                        ).copyWith(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              // White Card for Amount + Date
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDarkBg(context),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Total Due",
                                          style: AppTheme.textSearchInfo(
                                            context,
                                          ).copyWith(fontSize: 12),
                                        ),
                                        Text(
                                          "Rs ${NumberFormat('#,###.##').format(order.TotalAmount)}",
                                          style: AppTheme.textTitle(context)
                                              .copyWith(
                                                fontSize: 22,
                                                fontFamily:
                                                    AppFontFamily.poppinsMedium,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatDate(order.OrderDate),
                                          style: AppTheme.textSearchInfoLabeled(
                                            context,
                                          ).copyWith(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        // 🔹 Order Items + Charges
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: List.generate(items.length, (index) {
                              final item = items[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Text(
                                    (index + 1).toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontFamily: AppFontFamily.poppinsMedium,
                                    ),
                                  ),
                                  title: Text(
                                    item.ProductName,
                                    // maxLines: 1,
                                    // overflow: TextOverflow.ellipsis,
                                    style: AppTheme.textLabel(context).copyWith(
                                      fontFamily: AppFontFamily.poppinsSemiBold,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      const Icon(
                                        HugeIconsStroke.package,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Qty: ${item.Quantity.toString().padLeft(2, '0')}",
                                        style: const TextStyle(
                                          fontFamily:
                                              AppFontFamily.poppinsRegular,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        HugeIconsStroke.money01,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Rate: Rs ${NumberFormat('#,###.##').format(item.Price)}",
                                        style: const TextStyle(
                                          fontFamily:
                                              AppFontFamily.poppinsRegular,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    "Rs ${NumberFormat('#,###.##').format(item.TotalPrice)}",
                                    style:
                                        AppTheme.textSearchInfoLabeled(
                                          context,
                                        ).copyWith(
                                          fontSize: 12,
                                          fontFamily: AppFontFamily.poppinsBold,
                                        ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              Divider(color: AppTheme.dividerBg(context)),
                              _buildSummaryRow(
                                "Subtotal",
                                order.SubTotal,
                                HugeIconsStroke.nodeAdd,
                              ),
                              _buildSummaryRow(
                                "Sales Tax",
                                order.SalesTax,
                                HugeIconsStroke.saleTag02,
                              ),
                              _buildSummaryRow(
                                "Discount",
                                order.Discount,
                                HugeIconsStroke.discountTag02,
                              ),
                              Divider(color: AppTheme.dividerBg(context)),
                              _buildSummaryRow(
                                "Total Amount",
                                order.TotalAmount,
                                HugeIconsStroke.moneyAdd02,
                                isBold: true,
                              ),
                              if(!checkOrderType)...[
                                _buildSummaryRow(
                                  "Paid",
                                  order.Paid,
                                  HugeIconsStroke.notebook01,
                                ),
                                _buildSummaryRow(
                                  "Balance",
                                  order.Balance,
                                  HugeIconsStroke.invoice03,
                                  isBold: true,
                                ),
                              ],
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String title,
    double value,
    IconData icon, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.iconColor(context)),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTheme.textLabel(context).copyWith(
                  fontFamily: isBold
                      ? AppFontFamily.poppinsSemiBold
                      : AppFontFamily.poppinsRegular,
                ),
              ),
            ],
          ),
          Text(
            "Rs ${NumberFormat('#,###.##').format(value).toString().padRight(1, '0')}",
            style: AppTheme.textLabel(context).copyWith(
              fontFamily: isBold
                  ? AppFontFamily.poppinsSemiBold
                  : AppFontFamily.poppinsRegular,
            ),
          ),
        ],
      ),
    );
  }
}
