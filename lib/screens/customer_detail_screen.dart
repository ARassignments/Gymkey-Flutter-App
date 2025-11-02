import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '/Models/customer_model.dart';
import '/components/appsnackbar.dart';
import '/theme/theme.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
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
    if (number.startsWith("3") || number.startsWith("0")) {
      return "+92 ${number.substring(0, 3)} ${number.substring(3, 7)}${number.substring(7)}";
    }
    return number;
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

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    final formattedBalance = NumberFormat(
      '#,###.00',
    ).format(customer.OpeningBalance);
    final numberCheck =
        customer.PhoneNo.toString() == "00" ||
        customer.PhoneNo.toString() == "0";
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: true,
        title: Text(
          "Customer Detail",
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
          if (!numberCheck)
            PopupMenuButton<String>(
              color: AppTheme.cardDarkBg(context),
              elevation: 10,
              shadowColor: Colors.black26,
              icon: const Icon(HugeIconsStroke.moreVerticalCircle01, size: 20),
              onSelected: (value) {
                if (value == "call") {
                  _makePhoneCall(customer.PhoneNo, context);
                } else if (value == "whatsapp") {
                  _openWhatsApp(customer.PhoneNo, context);
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  "User ID# ${customer.UserId.toString().padLeft(2, '0')}",
                                  style: AppTheme.textLabel(
                                    context,
                                  ).copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          customer.UserName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.textTitle(
                            context,
                          ).copyWith(fontSize: 20),
                        ),
                        SizedBox(height: 10),
                        if (!customer.CityName.toString().contains("Null"))
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
                                  customer.CityName,
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDarkBg(context),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Opening Balance",
                                style: AppTheme.textSearchInfo(
                                  context,
                                ).copyWith(fontSize: 12),
                              ),
                              Text(
                                "Rs ${NumberFormat('#,###.##').format(customer.OpeningBalance)}",
                                style: AppTheme.textTitle(context).copyWith(
                                  fontSize: 22,
                                  fontFamily: AppFontFamily.poppinsMedium,
                                ),
                              ),
                              // if (!customer.BankName.toString().contains("N/A"))
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    HugeIconsStroke.bank,
                                    size: 20,
                                    color: AppTheme.iconColor(context),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Bank Name",
                                      style: AppTheme.textLabel(context),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      customer.BankName,
                                      style: AppTheme.textLabel(context),
                                    ),
                                  ),
                                ],
                              ),
                              // if (!customer.BankAccount.toString().contains(
                              //   "N/A",
                              // ))
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    HugeIconsStroke.smsCode,
                                    size: 20,
                                    color: AppTheme.iconColor(context),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Bank Account No",
                                      style: AppTheme.textLabel(context),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      customer.BankAccount,
                                      style: AppTheme.textLabel(context),
                                    ),
                                  ),
                                ],
                              ),
                              // if (!customer.BankBranchCode.toString().contains(
                              //   "N/A",
                              // ))
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    HugeIconsStroke.binaryCode,
                                    size: 20,
                                    color: AppTheme.iconColor(context),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Bank Branch Code",
                                      style: AppTheme.textLabel(context),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      customer.BankBranchCode,
                                      style: AppTheme.textLabel(context),
                                    ),
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
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(HugeIconsStroke.userAccount, size: 24),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "User Name",
                            style: AppTheme.textLabel(context),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            customer.UserName,
                            style: AppTheme.textLabel(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppTheme.dividerBg(context)),
                  if (!customer.Email.toString().contains("N/A")) ...[
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(HugeIconsStroke.mail02, size: 24),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Email Address",
                              style: AppTheme.textLabel(context),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              customer.Email,
                              style: AppTheme.textLabel(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                  ],
                  if (!numberCheck) ...[
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(HugeIconsStroke.call, size: 24),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Phone Number",
                              style: AppTheme.textLabel(context),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              formatInternationalPhone(customer.PhoneNo),
                              style: AppTheme.textLabel(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                  ],
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(HugeIconsStroke.building03, size: 24),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "City Name",
                            style: AppTheme.textLabel(context),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            customer.CityName,
                            style: AppTheme.textLabel(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppTheme.dividerBg(context)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(HugeIconsStroke.mapPin, size: 24),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "State Name",
                            style: AppTheme.textLabel(context),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            customer.StateName,
                            style: AppTheme.textLabel(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppTheme.dividerBg(context)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(HugeIconsStroke.mapsLocation02, size: 24),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Address",
                            style: AppTheme.textLabel(context),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            customer.Address,
                            style: AppTheme.textLabel(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppTheme.dividerBg(context)),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
