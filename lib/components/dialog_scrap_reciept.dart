import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:pdfx/pdfx.dart';
import '/Models/scrap_model.dart';
import '/Models/customer_single_model.dart';
import '/components/appsnackbar.dart';
import '/theme/theme.dart';
import '/components/loading_screen.dart';
import '/utils/whatsapp_helper.dart';

class ScrapReceiptBottomSheet {
  static Future<bool> _requestPermission() async {
    if (await Permission.storage.isGranted) return true;
    final result = await Permission.storage.request();
    return result.isGranted;
  }

  static Future<void> showRecieptPreview(
    BuildContext context,
    ScrapModel scrap,
    String apiUrl,
    String fileName,
    CustomerSingleModel? customer,
  ) async {
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
                                await imageFile.writeAsBytes(pageImage.bytes);

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
