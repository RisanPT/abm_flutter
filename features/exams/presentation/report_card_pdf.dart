import 'package:abm_madrasa/features/exams/data/exam_repository.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Generates and previews/prints a branded report card for one student's exam.
Future<void> printReportCard({
  required Exam exam,
  required ExamResult result,
  required String studentName,
  String admissionNumber = '',
}) async {
  const green = PdfColor.fromInt(0xFF1B3D2F);
  const gold = PdfColor.fromInt(0xFFB8860B);
  final doc = pw.Document();

  final maxBySubject = {for (final s in exam.subjects) s.name: s.maxMarks};

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(color: green),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Anas Bin Malik Madrasa',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Report Card', style: const pw.TextStyle(color: PdfColor.fromInt(0xFFE2B961), fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _kv('Student', studentName),
              if (admissionNumber.isNotEmpty) _kv('ID', admissionNumber),
              _kv('Class', result.classroom.isEmpty ? exam.classroom : result.classroom),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _kv('Exam', exam.name),
              if (exam.term.isNotEmpty) _kv('Term', exam.term),
              _kv('Date', exam.date != null ? DateFormat('dd MMM yyyy').format(exam.date!) : DateFormat('dd MMM yyyy').format(DateTime.now())),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: green),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {1: pw.Alignment.center, 2: pw.Alignment.center},
            headers: ['Subject', 'Marks', 'Max'],
            data: result.marks
                .map((m) => [m.subject, m.score.toString(), (maxBySubject[m.subject] ?? '').toString()])
                .toList(),
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: gold, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _big('Total', '${result.total} / ${result.maxTotal}'),
                _big('Percentage', '${result.percentage}%'),
                _big('Grade', result.grade),
              ],
            ),
          ),
          if (result.remarks.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Remarks: ${result.remarks}', style: const pw.TextStyle(fontSize: 11)),
          ],
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Class Teacher', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text('Head Master', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
        ],
      ),
    ),
  );

  await Printing.layoutPdf(onLayout: (_) => doc.save());
}

pw.Widget _kv(String k, String v) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(k, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.Text(v, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );

pw.Widget _big(String k, String v) => pw.Column(
      children: [
        pw.Text(v, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1B3D2F))),
        pw.Text(k, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ],
    );
