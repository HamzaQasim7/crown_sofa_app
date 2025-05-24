import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_order_app/data/models/order_model.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../core/permissions_utils.dart';

class PdfService {
  // Generate PDF document for an order
  Future<File> generateOrderPdf(OrderModel order) async {
    final pdf = pw.Document();

    // Load a font
    final font = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
    final ttf = pw.Font.ttf(font);

    // Add company logo if available
    pw.MemoryImage? logoImage;
    try {
      final ByteData logoData = await rootBundle.load(
        'assets/images/app_logo.jpg',
      );
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (e) {
      print('Logo image not found: $e');
    }

    // Format dates
    final dateFormat = DateFormat('dd MMM yyyy');
    final orderDate =
        order.orderBookingDate != null
            ? dateFormat.format(
              DateTime.parse(order.orderBookingDate!.toString()),
            )
            : 'N/A';
    final deliveryDate =
        order.deliveryDate != null
            ? dateFormat.format(DateTime.parse(order.deliveryDate!.toString()))
            : 'N/A';
    // Try to download order images if available
    List<pw.MemoryImage> orderImages = [];
    if (order.imageUrls != null && order.imageUrls!.isNotEmpty) {
      try {
        // Limit to first 3 images to keep PDF size reasonable
        final imagesToDownload = order.imageUrls!.take(3).toList();
        for (final imageUrl in imagesToDownload) {
          try {
            final response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              orderImages.add(pw.MemoryImage(response.bodyBytes));
            }
          } catch (e) {
            print('Error downloading image $imageUrl: $e');
          }
        }
      } catch (e) {
        print('Error processing order images: $e');
      }
    }
    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header with logo
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Crown Sofa & Bed',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Order #: ${order.id}',
                      style: pw.TextStyle(font: ttf, fontSize: 14),
                    ),
                  ],
                ),
                if (logoImage != null)
                  pw.Image(logoImage, width: 80, height: 80),
              ],
            ),

            pw.SizedBox(height: 20),

            // Order Info
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Order Date: $orderDate',
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Delivery Date: $deliveryDate',
                        style: pw.TextStyle(font: ttf),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Seller: ${order.sellerName ?? "N/A"}',
                        style: pw.TextStyle(font: ttf),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Customer Info
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CUSTOMER INFORMATION',
                    style: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Name: ${order.customerName ?? "N/A"}',
                    style: pw.TextStyle(font: ttf),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Phone: ${order.phoneNumber ?? "N/A"}',
                    style: pw.TextStyle(font: ttf),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Address: ${order.customerAddress ?? "N/A"}',
                    style: pw.TextStyle(font: ttf),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Postcode: ${order.postcode ?? "N/A"}',
                    style: pw.TextStyle(font: ttf),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Product Info
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PRODUCT INFORMATION',
                    style: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Design: ${order.designName ?? "N/A"}',
                    style: pw.TextStyle(font: ttf),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Color & Fabric: ${order.colorFabric ?? "N/A"}',
                    style: pw.TextStyle(font: ttf),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Combination: ${order.combination ?? "N/A"}',
                    style: pw.TextStyle(font: ttf),
                  ),
                ],
              ),
            ),

            // Order Images (if available)
            if (orderImages.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ORDER IMAGES',
                      style: pw.TextStyle(
                        font: ttf,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Divider(),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children:
                          orderImages
                              .map(
                                (img) => pw.Expanded(
                                  child: pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Image(
                                      img,
                                      height: 100,
                                      fit: pw.BoxFit.contain,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    if (order.imageUrls!.length > orderImages.length)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 5),
                        child: pw.Text(
                          '+ ${order.imageUrls!.length - orderImages.length} more images',
                          style: pw.TextStyle(
                            font: ttf,
                            color: PdfColors.grey700,
                            fontSize: 10,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Order Details
            if (order.orderDetails != null &&
                order.orderDetails!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Sale Price: RS${order.salePrice?.toStringAsFixed(2) ?? "N/A"}',
                      style: pw.TextStyle(
                        font: ttf,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'ADDITIONAL NOTES',
                      style: pw.TextStyle(
                        font: ttf,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Divider(),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      order.orderDetails!,
                      style: pw.TextStyle(font: ttf),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      font: ttf,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Address: Unit 2, Bold Street, Preston PR1 7JT',
                    style: pw.TextStyle(
                      font: ttf,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Generated on ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ];
        },
      ),
    );

    // Save the PDF file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/order_${order.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Share the PDF file
  Future<void> sharePdf(File pdfFile) async {
    await Share.shareXFiles([XFile(pdfFile.path)], text: 'Order Receipt');
  }

  // Save PDF to gallery
  // Save PDF to gallery with permission handling
  Future<bool> savePdfToGallery(File pdfFile, BuildContext context) async {
    try {
      // Check and request permissions
      final hasPermission = await PermissionUtils.checkAndRequestPermissions(
        skipIfExists: false,
      );

      if (!hasPermission) {
        // Show permission explanation dialog
        await PermissionUtils.showPermissionExplanationDialog(
          context: context,
          onRetry: () async {
            // Try requesting permission again
            final retryPermission =
                await PermissionUtils.checkAndRequestPermissions(
                  skipIfExists: false,
                );

            if (!retryPermission) {
              // If still denied, prompt to open settings
              await PermissionUtils.openAppSettings(context);
              return false;
            } else {
              // Permission granted on retry, save the file
              return await _saveFileToGallery(pdfFile);
            }
          },
          onCancel: () {
            return false;
          },
        );
        return false;
      }

      // Permission granted, save the file
      return await _saveFileToGallery(pdfFile);
    } catch (e) {
      print('Error saving to gallery: $e');
      return false;
    }
  }
  // Future<bool> savePdfToGallery(File pdfFile) async {
  //   try {
  //     // Request storage permission
  //     final status = await Permission.storage.request();
  //     if (!status.isGranted) {
  //       print('Storage permission denied');
  //       return false;
  //     }
  //     final result = await SaverGallery.saveFile(
  //       filePath: pdfFile.path,
  //       fileName: pdfFile.path.split('/').last,
  //       skipIfExists: false,
  //     );
  //     return result.isSuccess ?? false;
  //   } catch (e) {
  //     print('Error saving to gallery: $e');
  //     return false;
  //   }
  // }

  // Private method to save file to gallery
  Future<bool> _saveFileToGallery(File pdfFile) async {
    try {
      final result = await SaverGallery.saveFile(
        filePath: pdfFile.path,
        fileName: pdfFile.path.split('/').last,
        skipIfExists: false,
      );
      return result.isSuccess ?? false;
    } catch (e) {
      print('Error in _saveFileToGallery: $e');
      return false;
    }
  }
}
