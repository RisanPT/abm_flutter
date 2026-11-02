import 'package:abm_madrasa/core/utils/money.dart';
import 'package:abm_madrasa/core/utils/web_download.dart';
import 'package:abm_madrasa/features/books/domain/book_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BookPdfExporter {
  static Future<pw.Document> generateDocument({
    required List<BookModel> books,
    required String instituteName,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(now);

    int totalCopies = 0;
    double totalValuation = 0.0;
    int lowStock = 0;
    int outOfStock = 0;

    for (final b in books) {
      totalCopies += b.stockQuantity;
      totalValuation += b.totalValue;
      if (b.isOutOfStock) {
        outOfStock++;
      } else if (b.isLowStock) {
        lowStock++;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        header: (context) => _buildHeader(
          instituteName: instituteName,
          dateStr: dateStr,
          context: context,
        ),
        footer: (context) => _buildFooter(context: context),
        build: (context) => [
          pw.SizedBox(height: 12),
          // Metric Summary Cards
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('Total Titles', '${books.length}'),
                _buildSummaryStat('Total Copies', number(totalCopies)),
                _buildSummaryStat('Total Valuation', sar(totalValuation, decimals: 2)),
                _buildSummaryStat('Low / Out of Stock', '$lowStock / $outOfStock'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Table
          pw.TableHelper.fromTextArray(
            headers: [
              '#',
              'Code',
              'Book Title',
              'Subject',
              'Grade',
              'Price',
              'Stock',
              'Total Value',
              'Status',
            ],
            data: books.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final b = entry.value;
              return [
                '$idx',
                b.bookCode.isNotEmpty ? b.bookCode : '-',
                b.title,
                b.subject,
                b.grade,
                sar(b.price, decimals: 2),
                '${b.stockQuantity}',
                sar(b.totalValue, decimals: 2),
                b.status,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF0F4A3A),
            ),
            headerHeight: 24,
            cellHeight: 20,
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.center,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.center,
              7: pw.Alignment.centerRight,
              8: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF9FAFB),
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader({
    required String instituteName,
    required String dateStr,
    required pw.Context context,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  instituteName.isNotEmpty ? instituteName.toUpperCase() : 'ANAS BIN MALIK MADRASA',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF0F4A3A),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Books Management & Curriculum Inventory Report',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Generated: $dateStr', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Currency: SAR', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
        pw.Divider(color: const PdfColor.fromInt(0xFF0F4A3A), thickness: 1.5),
      ],
    );
  }

  static pw.Widget _buildFooter({required pw.Context context}) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400, thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Confidential - Anas Bin Malik Madrasa ERP System',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryStat(String title, String val) {
    return pw.Column(
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(
          val,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF0F4A3A),
          ),
        ),
      ],
    );
  }

  static Future<void> printOrPreview({
    required List<BookModel> books,
    required String instituteName,
  }) async {
    final pdf = await generateDocument(books: books, instituteName: instituteName);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'madrasa_books_report.pdf',
    );
  }

  static Future<void> downloadDirect({
    required List<BookModel> books,
    required String instituteName,
    required BuildContext context,
  }) async {
    try {
      final pdf = await generateDocument(books: books, instituteName: instituteName);
      final bytes = await pdf.save();
      final dateStamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filename = 'books_inventory_$dateStamp.pdf';

      if (kIsWeb) {
        triggerBrowserDownload(bytes, filename, 'application/pdf');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded $filename'),
              backgroundColor: const Color(0xFF0F4A3A),
            ),
          );
        }
      } else {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download PDF: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}
