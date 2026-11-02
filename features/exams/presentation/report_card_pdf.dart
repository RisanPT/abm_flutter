import 'package:abm_madrasa/features/exams/data/exam_repository.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
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
              _kv('Shift', exam.shift.isEmpty ? 'Shift-1' : exam.shift),
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
          pw.TableHelper.fromTextArray(
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

/// Generates and previews/prints a full class result gazette / master marks sheet.
Future<void> printClassResultGazette({
  required Exam exam,
  required List<ExamResult> results,
  required List<StudentModel> students,
}) async {
  const green = PdfColor.fromInt(0xFF1B3D2F);
  final doc = pw.Document();

  final resultsByStudent = {for (final r in results) r.studentId: r};

  // Sort students by result rank/percentage (highest first), then by name
  final sortedStudents = List<StudentModel>.from(students);
  sortedStudents.sort((a, b) {
    final ra = resultsByStudent[a.id];
    final rb = resultsByStudent[b.id];
    if (ra != null && rb != null) {
      return rb.percentage.compareTo(ra.percentage);
    }
    if (ra != null) return -1;
    if (rb != null) return 1;
    return a.fullName.compareTo(b.fullName);
  });

  // KPI Calculations
  final gradedResults = results.where((r) => r.maxTotal > 0).toList();
  final classAvg = gradedResults.isNotEmpty
      ? (gradedResults.map((r) => r.percentage).reduce((a, b) => a + b) / gradedResults.length).toStringAsFixed(1)
      : '0.0';
  final highestScore = gradedResults.isNotEmpty
      ? gradedResults.map((r) => r.percentage).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)
      : '0.0';
  final passedCount = gradedResults.where((r) => r.percentage >= 40).length;
  final passRate = gradedResults.isNotEmpty
      ? ((passedCount / gradedResults.length) * 100).toStringAsFixed(1)
      : '0.0';

  // Build table headers and rows
  final headers = <String>[
    '#',
    'Student Name',
    ...exam.subjects.map((s) => '${s.name} (${s.maxMarks})'),
    'Total',
    '%',
    'Grade',
    'Status',
  ];

  final rows = <List<String>>[];
  for (int i = 0; i < sortedStudents.length; i++) {
    final s = sortedStudents[i];
    final r = resultsByStudent[s.id];
    final marksMap = {for (final m in (r?.marks ?? const <ExamMark>[])) m.subject: m.score};

    final subjectCells = exam.subjects.map((subj) {
      final score = marksMap[subj.name];
      return score != null ? score.toString() : '-';
    }).toList();

    rows.add([
      '${i + 1}',
      s.fullName,
      ...subjectCells,
      r != null ? '${r.total}/${r.maxTotal}' : '-',
      r != null ? '${r.percentage}%' : '-',
      r?.grade.isNotEmpty == true ? r!.grade : '-',
      r != null ? (r.percentage >= 40 ? 'PASS' : 'FAIL') : 'PENDING',
    ]);
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const pw.BoxDecoration(color: green),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ANAS BIN MALIK MADRASA',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('EXAMINATION RESULT GAZETTE',
                        style:  pw.TextStyle(color: PdfColor.fromInt(0xFFE2B961), fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Exam: ${exam.name}',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Class: ${exam.classroom} · ${exam.shift}',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _kv('Total Students', '${students.length} (${gradedResults.length} Graded)'),
              _kv('Class Average', '$classAvg%'),
              _kv('Top Score', '$highestScore%'),
              _kv('Pass Rate', '$passRate% ($passedCount Passed)'),
              if (exam.assignedTeacher.isNotEmpty) _kv('Teacher', exam.assignedTeacher),
              _kv('Date', exam.date != null ? DateFormat('dd MMM yyyy').format(exam.date!) : DateFormat('dd MMM yyyy').format(DateTime.now())),
            ],
          ),
          pw.SizedBox(height: 12),
        ],
      ),
      build: (_) => [
        pw.TableHelper.fromTextArray(
          headerDecoration: const pw.BoxDecoration(color: green),
          headerStyle: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8.5),
          cellAlignment: pw.Alignment.centerLeft,
          headers: headers,
          data: rows,
        ),
        pw.SizedBox(height: 24),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 140, height: 1, color: PdfColors.grey500),
                pw.SizedBox(height: 4),
                pw.Text('Assigned Class Teacher', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 140, height: 1, color: PdfColors.grey500),
                pw.SizedBox(height: 4),
                pw.Text('Examination Controller', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(width: 140, height: 1, color: PdfColors.grey500),
                pw.SizedBox(height: 4),
                pw.Text('Head Master / Principal', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
          ],
        ),
      ],
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
