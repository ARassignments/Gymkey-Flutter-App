import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:pdfx/pdfx.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:pdf/widgets.dart' as pw;
import '/components/dashed_divider.dart';
import '/utils/session_manager.dart';
import '/Models/customer_single_model.dart';
import '/Models/payment_model.dart';
import '/components/appsnackbar.dart';
import '/theme/theme.dart';
import '/components/loading_screen.dart';
import '/utils/whatsapp_helper.dart';

class PaymentReceiptBottomSheet {
  static Future<bool> _requestPermission() async {
    if (await Permission.storage.isGranted) return true;
    final result = await Permission.storage.request();
    return result.isGranted;
  }

  static Future<void> showRecieptPreview(
    BuildContext context,
    PaymentModel payment,
    String apiUrl,
    String fileName,
    CustomerSingleModel? customer,
    bool reciptPreview,
  ) async {
    if (reciptPreview) {
      Map<String, dynamic>? user = await SessionManager.getUser();
      final WidgetsToImageController imageController =
          WidgetsToImageController();
      if (kIsWeb) {
        try {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            builder: (context) {
              final date = DateFormat(
                'dd MMM yyyy',
              ).format(payment.PaymentDate);
              final amount = NumberFormat('#,###.00').format(payment.Payment);
              return Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Wrap(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        /// Main Receipt Box
                        WidgetsToImage(
                          controller: imageController,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.screenBg(
                                    context,
                                  ).withAlpha(0),
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    image: AssetImage(
                                      AppTheme.recieptBgImage(context),
                                    ),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.bottomCenter.add(
                                      const Alignment(0, -0.2),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    /// Header with logo & date
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Image.asset(
                                                AppTheme.appLogo(context),
                                                width: 60,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                "Y2K",
                                                style:
                                                    AppTheme.textTitleActiveTwo(
                                                      context,
                                                    ).copyWith(
                                                      fontSize: 20,
                                                      fontFamily: AppFontFamily
                                                          .poppinsBold,
                                                    ),
                                              ),
                                              Text(
                                                "Solutions",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    AppTheme.textTitleActiveTwo(
                                                      context,
                                                    ).copyWith(
                                                      fontSize: 20,
                                                      fontFamily: AppFontFamily
                                                          .poppinsLight,
                                                    ),
                                              ),
                                              Text(
                                                ".",
                                                style: AppTheme.textTitleActive(
                                                  context,
                                                ).copyWith(fontSize: 22),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          date,
                                          style:
                                              AppTheme.textSearchInfoLabeled(
                                                context,
                                              ).copyWith(
                                                fontSize: 13,
                                                fontFamily:
                                                    AppFontFamily.poppinsMedium,
                                              ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "${DateFormat('MMMM').format(payment.PaymentDate)} ${payment.PaymentMode} Bill",
                                      style: AppTheme.textTitle(
                                        context,
                                      ).copyWith(fontSize: 15),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    _infoRow(
                                      context,
                                      "Name",
                                      "${payment.UserName}",
                                    ),
                                    _infoRow(
                                      context,
                                      "Phone Number",
                                      "${customer!.PhoneNo}",
                                    ),
                                    _infoRow(
                                      context,
                                      "Address",
                                      "${customer!.Address}, ${customer!.CityName}, ${customer!.StateName}",
                                    ),
                                    _infoRow(
                                      context,
                                      "Payment Type",
                                      payment.PaymentType,
                                    ),
                                    _infoRow(
                                      context,
                                      "Payment Mode",
                                      payment.PaymentMode,
                                    ),
                                    _infoRow(context, "Amount", "Rs. $amount"),
                                    _infoRow(
                                      context,
                                      "Remarks",
                                      "${payment.Remarks.isEmpty ? "N/A" : payment.Remarks}",
                                    ),
                                    const SizedBox(height: 16),
                                    DashedDivider(
                                      color: AppTheme.dividerBg(context),
                                      height: 2,
                                      dashWidth: 6,
                                      dashSpace: 3,
                                    ),
                                    const SizedBox(height: 16),
                                    _amountRow(
                                      context,
                                      "Total Amount",
                                      "Rs. $amount",
                                    ),
                                  ],
                                ),
                              ),

                              /// Watermark “PAID”
                              Opacity(
                                opacity: 0.05,
                                child: Image.asset(
                                  payment.PaymentMode.toString().contains(
                                        "Paid",
                                      )
                                      ? AppTheme.paidRecieptImage(context)
                                      : AppTheme.receivedRecieptImage(context),
                                  width: 220,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.screenBg(context),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 10,
                            children: [
                              FlatButton(
                                text: "Share Bill",
                                icon: HugeIconsSolid.linkSquare01,
                                onPressed: () async {
                                  final message = Uri.encodeComponent(
                                    "*🗒 Payment Receipt*\n"
                                    "----------------------------------\n"
                                    "🆔 *Reciept#:* ${payment.Id}\n"
                                    "🪪 *Name:* ${payment.UserName}\n"
                                    "📞 *Phone:* ${customer!.PhoneNo}\n"
                                    "📍 *Address:* ${customer!.Address}, ${customer!.CityName}, ${customer!.StateName}\n"
                                    "💳 *Payment Type:* ${payment.PaymentType}\n"
                                    "🪙 *Payment Mode:* ${payment.PaymentMode}\n"
                                    "💰 *Amount:* Rs $amount\n"
                                    "📓 *Remarks:* ${payment.Remarks.isEmpty ? 'N/A' : payment.Remarks}\n"
                                    "🗓 *Date:* $date\n"
                                    "----------------------------------\n"
                                    "Thank you for your payment!\n\n"
                                    "👇 *Here is your payment reciept* 👇\n"
                                    "$apiUrl",
                                  );
                                  String formatted = customer!.PhoneNo
                                      .toString()
                                      .replaceAll(" ", "");
                                  if (formatted.startsWith("0")) {
                                    formatted = formatted.substring(1);
                                  }
                                  final url = Uri.parse(
                                    "https://wa.me/92$formatted?text=$message",
                                  );
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    AppSnackBar.show(
                                      context,
                                      message: "Unable to open WhatsApp",
                                      type: AppSnackBarType.error,
                                    );
                                  }
                                },
                              ),
                              OutlineButton(
                                text: "Download Bill",
                                icon: HugeIconsSolid.download03,
                                onPressed: () async {
                                  try {
                                    final Uint8List? capturedImage =
                                        await imageController.capture();
                                    if (capturedImage == null) {
                                      AppSnackBar.show(
                                        context,
                                        message:
                                            "Failed to capture receipt image",
                                        type: AppSnackBarType.error,
                                      );
                                      return;
                                    }

                                    final blob = html.Blob([capturedImage]);
                                    final url =
                                        html.Url.createObjectUrlFromBlob(blob);
                                    final anchor = html.AnchorElement(href: url)
                                      ..setAttribute(
                                        "download",
                                        "$fileName.png",
                                      )
                                      ..click();
                                    html.Url.revokeObjectUrl(url);

                                    AppSnackBar.show(
                                      context,
                                      message:
                                          "Receipt downloaded successfully",
                                      type: AppSnackBarType.success,
                                    );
                                  } catch (e) {
                                    AppSnackBar.show(
                                      context,
                                      message: "Error saving receipt: $e",
                                      type: AppSnackBarType.error,
                                    );
                                  }
                                },
                              ),
                              GhostButton(
                                text: "Download PDF Bill",
                                icon: HugeIconsSolid.pdf01,
                                onPressed: () async {
                                  try {
                                    final Uint8List? capturedImage =
                                        await imageController.capture();

                                    if (capturedImage == null) {
                                      AppSnackBar.show(
                                        context,
                                        message:
                                            "Failed to capture receipt image",
                                        type: AppSnackBarType.error,
                                      );
                                      return;
                                    }

                                    final img = await decodeImageFromList(
                                      capturedImage,
                                    );
                                    final width = img.width.toDouble();
                                    final height = img.height.toDouble();

                                    const screenDpi = 96.0;
                                    const pdfDpi = 72.0;
                                    final pdfWidth =
                                        width * (pdfDpi / screenDpi);
                                    final pdfHeight =
                                        height * (pdfDpi / screenDpi);

                                    final pdf = pw.Document();
                                    final image = pw.MemoryImage(capturedImage);
                                    final fileNamePdf = "$fileName.pdf";

                                    pdf.addPage(
                                      pw.Page(
                                        pageFormat: PdfPageFormat(
                                          pdfWidth,
                                          pdfHeight,
                                        ),
                                        margin: pw.EdgeInsets.zero,
                                        build: (pw.Context context) {
                                          return pw.Image(
                                            image,
                                            fit: pw.BoxFit.contain,
                                          );
                                        },
                                      ),
                                    );

                                    final pdfBytes = await pdf.save();

                                    if (kIsWeb) {
                                      // 🟢 WEB MODE: Create and download the PDF
                                      final blob = html.Blob([
                                        pdfBytes,
                                      ], 'application/pdf');
                                      final url = html
                                          .Url.createObjectUrlFromBlob(blob);

                                      final anchor =
                                          html.AnchorElement(href: url)
                                            ..setAttribute(
                                              "download",
                                              fileNamePdf,
                                            )
                                            ..click();

                                      html.Url.revokeObjectUrl(url);

                                      AppSnackBar.show(
                                        context,
                                        message:
                                            "Receipt PDF downloaded successfully",
                                        type: AppSnackBarType.success,
                                      );
                                    } else {
                                      // 📱 MOBILE MODE
                                      final directory =
                                          await getApplicationDocumentsDirectory();
                                      final path =
                                          "${directory.path}/$fileNamePdf";
                                      final file = File(path);
                                      await file.writeAsBytes(pdfBytes);
                                      if (await Permission.storage
                                          .request()
                                          .isGranted) {
                                        final downloadsPath =
                                            await ExternalPath.getExternalStoragePublicDirectory(
                                              ExternalPath.DIRECTORY_DOWNLOAD,
                                            );
                                        final newPath =
                                            "$downloadsPath/$fileNamePdf";
                                        await file.copy(newPath);

                                        AppSnackBar.show(
                                          context,
                                          message:
                                              "PDF saved to Downloads successfully",
                                          type: AppSnackBarType.success,
                                        );
                                      } else {
                                        AppSnackBar.show(
                                          context,
                                          message: "Storage permission denied",
                                          type: AppSnackBarType.error,
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    AppSnackBar.show(
                                      context,
                                      message: "Error creating receipt PDF: $e",
                                      type: AppSnackBarType.error,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        } catch (e) {
          AppSnackBar.show(
            context,
            message: "Web error: $e",
            type: AppSnackBarType.error,
          );
        }
        return;
      }
    } else {
      if (kIsWeb) {
        try {
          showModalBottomSheet(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Wrap(
                  children: [
                    Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Reciept Generated in PDF",
                          textAlign: TextAlign.center,
                          style: AppTheme.textLabel(context).copyWith(
                            fontSize: 16,
                            fontFamily: AppFontFamily.poppinsBold,
                          ),
                        ),
                        Divider(color: AppTheme.dividerBg(context)),
                        FlatButton(
                          text: "Open Reciept",
                          icon: HugeIconsSolid.linkSquare01,
                          onPressed: () {
                            html.window.open(apiUrl, "_blank");
                          },
                        ),
                        OutlineButton(
                          text: "Download Reciept",
                          icon: HugeIconsSolid.download03,
                          onPressed: () {
                            html.AnchorElement(href: apiUrl)
                              ..setAttribute("download", "$fileName.pdf")
                              ..click();
                          },
                        ),
                        CustomButton(
                          text: "Share to WhatsApp",
                          icon: HugeIconsSolid.whatsapp,
                          color: Colors.green.shade500,
                          onPressed: () {
                            String formatted = customer!.PhoneNo
                                .toString()
                                .replaceAll(" ", "");
                            if (formatted.startsWith("0")) {
                              formatted = formatted.substring(1);
                            }
                            final whatsappUrl =
                                "https://wa.me/92$formatted?text=Here%20is%20your%20payment%20receipt:%20$apiUrl";
                            html.window.open(whatsappUrl, "_blank");
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        } catch (e) {
          AppSnackBar.show(
            context,
            message: "Web error: $e",
            type: AppSnackBarType.error,
          );
        }
        return;
      }
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Container(
            color: AppTheme.screenBg(context),
            child: const Center(child: LoadingLogo()),
          ),
        );

        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode != 200) {
          Navigator.pop(context);
          throw Exception("Failed to load PDF.");
        }

        final dir = await getTemporaryDirectory();
        final filePath = "${dir.path}/$fileName.pdf";
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        Navigator.pop(context);
        if (await _requestPermission()) {
          showModalBottomSheet(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            enableDrag: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Wrap(
                  children: [
                    Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Reciept Generated in PDF",
                          textAlign: TextAlign.center,
                          style: AppTheme.textLabel(context).copyWith(
                            fontSize: 16,
                            fontFamily: AppFontFamily.poppinsBold,
                          ),
                        ),
                        Divider(color: AppTheme.dividerBg(context)),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SizedBox(
                              height:
                                  MediaQuery.of(context).size.height *
                                  0.5, // adjust height
                              child: PDFView(
                                filePath: file.path,
                                fitEachPage: true,
                              ),
                            ),
                          ),
                        ),

                        FlatButton(
                          text: "Share Reciept",
                          icon: HugeIconsSolid.share01,
                          onPressed: () async {
                            await Share.shareXFiles([
                              XFile(file.path),
                            ], text: "Here is your PDF file");
                          },
                        ),
                        OutlineButton(
                          text: "Download Receipt",
                          icon: HugeIconsSolid.download03,
                          onPressed: () async {
                            if (await _requestPermission()) {
                              // ✅ Public Downloads directory
                              final downloadsDir =
                                  await ExternalPath.getExternalStoragePublicDirectory(
                                    ExternalPath.DIRECTORY_DOWNLOAD,
                                  );

                              final newPath = "$downloadsDir/$fileName.pdf";

                              try {
                                final newFile = await file.copy(newPath);

                                AppSnackBar.show(
                                  context,
                                  message: "PDF saved: ${newFile.path}",
                                  type: AppSnackBarType.success,
                                );
                              } catch (e) {
                                AppSnackBar.show(
                                  context,
                                  message: "Error saving file: $e",
                                  type: AppSnackBarType.error,
                                );
                              }
                            } else {
                              AppSnackBar.show(
                                context,
                                message: "Permission denied",
                                type: AppSnackBarType.error,
                              );
                            }
                          },
                        ),
                        Row(
                          spacing: 6,
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: "Share PDF",
                                icon: HugeIconsSolid.whatsapp,
                                color: Colors.green.shade500,
                                onPressed: () async {
                                  String formatted = customer!.PhoneNo
                                      .toString()
                                      .replaceAll(" ", "");
                                  if (formatted.startsWith("0")) {
                                    formatted = formatted.substring(1);
                                  }
                                  final whatsappUrl = Uri.parse(
                                    "https://wa.me/+92$formatted",
                                  );

                                  if (await canLaunchUrl(whatsappUrl)) {
                                    await WhatsAppHelper.sendPdfToWhatsApp(
                                      file.path,
                                      "92$formatted",
                                    );
                                  } else {
                                    AppSnackBar.show(
                                      context,
                                      message: "WhatsApp not available",
                                      type: AppSnackBarType.error,
                                    );
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: CustomButton(
                                text: "Share Image",
                                icon: HugeIconsSolid.whatsapp,
                                color: Colors.green.shade500,
                                onPressed: () async {
                                  final pdfDoc = await PdfDocument.openFile(
                                    file.path,
                                  );
                                  final page = await pdfDoc.getPage(1);

                                  const scale = 3.5;
                                  final pageImage = await page.render(
                                    width: (page.width * scale).toDouble(),
                                    height: (page.height * scale).toDouble(),
                                    format: PdfPageImageFormat.png,
                                    backgroundColor: '#FFFFFF',
                                  );

                                  if (pageImage != null) {
                                    final imageFile = File(
                                      "${dir.path}/$fileName.png",
                                    );
                                    await imageFile.writeAsBytes(
                                      pageImage.bytes,
                                    );

                                    String formatted = customer!.PhoneNo
                                        .toString()
                                        .replaceAll(" ", "");
                                    if (formatted.startsWith("0")) {
                                      formatted = formatted.substring(1);
                                    }

                                    await WhatsAppHelper.sendImageToWhatsApp(
                                      imageFile.path,
                                      "92$formatted",
                                    );
                                  }

                                  await page.close();
                                  await pdfDoc.close();
                                },
                              ),
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
        } else {
          AppSnackBar.show(
            context,
            message: "Storage permission denied",
            type: AppSnackBarType.error,
          );
        }
      } catch (e) {
        Navigator.pop(context);
        AppSnackBar.show(
          context,
          message: "Error: $e",
          type: AppSnackBarType.error,
        );
      }
    }
  }

  static Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.textSearchInfoLabeled(
              context,
            ).copyWith(fontSize: 13, fontFamily: AppFontFamily.poppinsMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.textTitle(
                context,
              ).copyWith(fontSize: 13, fontFamily: AppFontFamily.poppinsMedium),
              textAlign: TextAlign.right,
              softWrap: true,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _amountRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.textTitleActive(context).copyWith(fontSize: 14),
          ),
          Text(
            value,
            style: AppTheme.textTitleActive(context).copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
