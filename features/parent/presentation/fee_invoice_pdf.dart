import 'package:abm_madrasa/features/accounts/data/finance_repository.dart' show LedgerMonth;
import 'package:abm_madrasa/features/parent/data/parent_repository.dart' show ParentChild;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const _green = PdfColor.fromInt(0xFF1B3D2F);
const _greenLight = PdfColor.fromInt(0xFFE8F3EE);
const _cream = PdfColor.fromInt(0xFFFBF3DE);
const _line = PdfColor.fromInt(0xFFE0E2DD);

pw.Document buildFeeInvoiceDoc({
  required ParentChild child,
  required LedgerMonth month,
}) {
  final pdf = pw.Document();
  final receiptNo = (month.receiptNumber != null && month.receiptNumber!.isNotEmpty)
      ? month.receiptNumber!
      : 'RCPT-${child.admissionNumber}-${month.monthLabel.replaceAll(' ', '')}';
  final dateStr = month.paidOn != null
      ? DateFormat('dd MMMM yyyy').format(month.paidOn!)
      : DateFormat('dd MMMM yyyy').format(DateTime.now());

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Header Banner ────────────────────────────────────────────────
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: _green,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ANAS BIN MALIK MADRASA',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Official Fee Payment Invoice & Receipt',
                      style: const pw.TextStyle(color: _cream, fontSize: 12),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    month.status.toUpperCase(),
                    style: pw.TextStyle(
                      color: _green,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 22),

          // ── Invoice Metadata Row ──────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _greenLight,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.TableBorder.all(color: _line, width: 0.8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('INVOICE / RECEIPT NUMBER',
                        style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9)),
                    pw.SizedBox(height: 2),
                    pw.Text(receiptNo,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: _green)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('PAYMENT DATE',
                        style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9)),
                    pw.SizedBox(height: 2),
                    pw.Text(dateStr,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Student & Parent Details ──────────────────────────────────────
          pw.Text('Student & Family Details',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _green)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.TableBorder.all(color: _line, width: 0.8),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _detailRow('Student Name', child.fullName, 'Admission No.', '#${child.admissionNumber}'),
                pw.SizedBox(height: 8),
                _detailRow('Class / Grade', child.grade, 'Shift', child.shift.isNotEmpty ? child.shift : 'Regular'),
                pw.SizedBox(height: 8),
                _detailRow(
                  'Guardian Name',
                  child.guardianName.isNotEmpty ? child.guardianName : 'Parent',
                  'Parent Contact',
                  child.parentContact.isNotEmpty ? child.parentContact : '-',
                ),
                pw.SizedBox(height: 8),
                _detailRow('Billing Period', month.monthLabel, 'Status', month.status),
              ],
            ),
          ),
          pw.SizedBox(height: 22),

          // ── Particulars / Line Items Table ────────────────────────────────
          pw.Text('Fee Particulars',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _green)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: _line, width: 0.8),
            columnWidths: const {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _greenLight),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: pw.Text('Description',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: _green)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: pw.Text('Amount (SAR)',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: _green),
                        textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              // Line items
              ..._buildLineItemRows(month),
              // Subtotal
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: pw.Text('Total Due For ${month.monthLabel}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: pw.Text('SAR ${month.totalDue.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              // Total Paid
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _cream),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: pw.Text('Total Paid Amount',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: _green)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: pw.Text('SAR ${month.totalPaid.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: _green),
                        textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              // Balance if any
              if (month.balance > 0)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: pw.Text('Remaining Balance',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.red800)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: pw.Text('SAR ${month.balance.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.red800),
                          textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 24),

          // ── Payment Stamp & Acknowledgement ──────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.TableBorder.all(color: _line, width: 0.8),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: _green,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text('✓ PAID',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Payment Verified & Credited to Student Account',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Thank you for your timely contribution. May Allah accept your good deeds and grant success to the student.',
                        style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.Spacer(),

          // ── Footer ───────────────────────────────────────────────────────
          pw.Divider(color: _line),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Anas Bin Malik Madrasa • Computer Generated Official Invoice',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8.5)),
              pw.Text('Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8.5)),
            ],
          ),
        ],
      ),
    ),
  );

  return pdf;
}

List<pw.TableRow> _buildLineItemRows(LedgerMonth month) {
  if (month.lineItems.isNotEmpty) {
    return month.lineItems.map((item) {
      String title = 'Tuition & Madrasa Fee';
      num amount = month.totalDue;
      if (item is Map) {
        title = (item['title'] ?? item['name'] ?? item['description'] ?? title).toString();
        amount = (item['amount'] as num?) ?? amount;
      } else if (item is String) {
        title = item;
      }
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: pw.Text(title, style: const pw.TextStyle(fontSize: 10.5)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: pw.Text('SAR ${amount.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 10.5), textAlign: pw.TextAlign.right),
          ),
        ],
      );
    }).toList();
  }

  return [
    pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text('Monthly Madrasa Tuition & Curriculum Fee',
              style: const pw.TextStyle(fontSize: 10.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text('SAR ${month.totalDue.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 10.5), textAlign: pw.TextAlign.right),
        ),
      ],
    ),
  ];
}

pw.Widget _detailRow(String l1, String v1, String l2, String v2) {
  return pw.Row(
    children: [
      pw.Expanded(
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 90,
              child: pw.Text('$l1:', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
            ),
            pw.Expanded(
              child: pw.Text(v1,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  maxLines: 1),
            ),
          ],
        ),
      ),
      pw.SizedBox(width: 14),
      pw.Expanded(
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 90,
              child: pw.Text('$l2:', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
            ),
            pw.Expanded(
              child: pw.Text(v2,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  maxLines: 1),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Download / Print or view the official PDF invoice on any device.
Future<void> printOrDownloadFeeInvoice({
  required ParentChild child,
  required LedgerMonth month,
}) async {
  final doc = buildFeeInvoiceDoc(child: child, month: month);
  final filename = 'Invoice-${month.monthLabel.replaceAll(' ', '_')}-${child.admissionNumber}.pdf';
  await Printing.layoutPdf(
    name: filename,
    onLayout: (format) async => doc.save(),
  );
}

/// Share the official PDF invoice (WhatsApp, Save to Files, Email).
Future<void> shareFeeInvoicePdf({
  required ParentChild child,
  required LedgerMonth month,
}) async {
  final doc = buildFeeInvoiceDoc(child: child, month: month);
  final filename = 'Invoice-${month.monthLabel.replaceAll(' ', '_')}-${child.admissionNumber}.pdf';
  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: filename,
  );
}
