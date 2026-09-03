import 'package:abm_madrasa/features/students/data/student_portal_repository.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const _green = PdfColor.fromInt(0xFF0E5B43);
const _gold = PdfColor.fromInt(0xFFC2A14D);
const _cream = PdfColor.fromInt(0xFFEADFBE);
const _muted = PdfColor.fromInt(0xFF566A5F);
const _line = PdfColor.fromInt(0xFFE0E2DD);

/// Builds and opens (print / save-as-PDF on web, share sheet on mobile) a
/// one-page report card for a single term.
Future<void> shareReportCard(PortalProfile p, ReportRow r) async {
  final doc = pw.Document();
  final total = r.grades.fold<num>(0, (s, g) => s + g.mark);
  final avg = r.grades.isNotEmpty ? total / r.grades.length : 0;

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(34),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header banner
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(color: _green, borderRadius: pw.BorderRadius.circular(10)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Anas Bin Malik Madrasa',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text('Student Progress Report Card', style: const pw.TextStyle(color: _cream, fontSize: 12)),
              ]),
              pw.Text('*', style: const pw.TextStyle(color: _gold, fontSize: 30)),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Student details
        _infoRow('Student Name', p.fullName, 'Admission No.', p.admissionNumber),
        _infoRow('Class', p.grade, 'Shift', p.shift ?? '-'),
        _infoRow('Term', r.term.isEmpty ? '-' : r.term, 'Academic Year', r.academicYear.isEmpty ? '-' : r.academicYear),
        pw.SizedBox(height: 20),

        // Marks table
        pw.Text('Subject Marks', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _green, fontSize: 13)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: _line, width: .8),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F4EF)),
              children: [_th('Subject'), _th('Marks', center: true), _th('Grade', center: true)],
            ),
            if (r.grades.isEmpty)
              pw.TableRow(children: [_td('No subjects recorded'), _td('-', center: true), _td('-', center: true)]),
            for (final g in r.grades)
              pw.TableRow(children: [
                _td(g.subject),
                _td('${g.mark}', center: true),
                _td(g.grade, center: true, bold: true),
              ]),
          ],
        ),
        pw.SizedBox(height: 18),

        // Summary strip
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _stat('Average', avg.toStringAsFixed(1)),
            _stat('Attendance', '${r.attendanceRate.toStringAsFixed(0)}%'),
            _stat('Subjects', '${r.grades.length}'),
          ],
        ),
        pw.SizedBox(height: 20),

        if (r.remarks.isNotEmpty) ...[
          pw.Text('Remarks', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _green, fontSize: 13)),
          pw.SizedBox(height: 5),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFF7F8F5), borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Text(r.remarks, style: pw.TextStyle(color: _muted, fontStyle: pw.FontStyle.italic)),
          ),
        ],

        pw.Spacer(),
        pw.Divider(color: _line),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated from the Student Portal', style: const pw.TextStyle(fontSize: 9, color: _muted)),
            pw.Text('Head Master: ______________________', style: const pw.TextStyle(fontSize: 9, color: _muted)),
          ],
        ),
      ],
    ),
  ));

  final safeTerm = r.term.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  await Printing.layoutPdf(
    onLayout: (_) => doc.save(),
    name: 'ReportCard_${p.admissionNumber}_$safeTerm.pdf',
  );
}

pw.Widget _infoRow(String l1, String v1, String l2, String v2) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(children: [pw.Expanded(child: _kv(l1, v1)), pw.Expanded(child: _kv(l2, v2))]),
    );

pw.Widget _kv(String k, String v) => pw.RichText(
      text: pw.TextSpan(children: [
        pw.TextSpan(text: '$k:  ', style: const pw.TextStyle(color: _muted, fontSize: 11)),
        pw.TextSpan(text: v, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
      ]),
    );

pw.Widget _th(String t, {bool center = false}) => pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(t,
          textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
    );

pw.Widget _td(String t, {bool center = false, bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(t,
          textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
          style: pw.TextStyle(fontSize: 11, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );

pw.Widget _stat(String l, String v) => pw.Column(children: [
      pw.Text(v, style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: _green)),
      pw.SizedBox(height: 2),
      pw.Text(l, style: const pw.TextStyle(fontSize: 9, color: _muted)),
    ]);
