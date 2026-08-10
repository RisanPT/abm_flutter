import 'dart:convert';
import 'dart:typed_data';

import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/web_download.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/features/students/presentation/student_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Column definitions for the grid — order matters (also the CSV template order).
class _Col {
  const _Col(this.key, this.label, this.width, {this.required = false});
  final String key;
  final String label;
  final double width;
  final bool required;
}

const List<_Col> _columns = [
  _Col('fullName', 'Full Name', 170, required: true),
  _Col('grade', 'Grade', 130, required: true),
  _Col('gender', 'Gender', 110, required: true),
  _Col('dob', 'Date of Birth', 140, required: true),
  _Col('parentContact', 'Parent Contact', 150, required: true),
  _Col('address', 'Address', 170, required: true),
  _Col('guardianName', 'Guardian Name', 150),
  _Col('studentId', 'Student ID', 120),
  _Col('parentIqamaId', 'Parent Iqama ID', 140),
  _Col('bloodGroup', 'Blood Group', 110),
  _Col('shift', 'Shift', 120),
];

const double _deleteColWidth = 44;
const double _rowNumWidth = 40;

double get _totalWidth =>
    _rowNumWidth + _columns.fold<double>(0, (s, c) => s + c.width) + _deleteColWidth;

/// One editable student row. Owns its text controllers so we can dispose them.
class _StudentRow {
  final Map<String, TextEditingController> text = {
    for (final c in _columns)
      if (c.key != 'gender' && c.key != 'dob' && c.key != 'shift')
        c.key: TextEditingController(),
  };
  Gender? gender;
  DateTime? dob;
  String? shift;

  bool get isEmpty =>
      text.values.every((c) => c.text.trim().isEmpty) &&
      gender == null &&
      dob == null &&
      (shift == null || shift!.isEmpty);

  String _t(String key) => text[key]?.text.trim() ?? '';

  Map<String, dynamic> toPayload(String instituteId) => {
        'fullName': _t('fullName'),
        'grade': _t('grade'),
        'gender': gender == Gender.male
            ? 'Male'
            : gender == Gender.female
                ? 'Female'
                : '',
        'dateOfBirth': dob?.toIso8601String(),
        'parentContact': _t('parentContact'),
        'address': _t('address'),
        if (_t('guardianName').isNotEmpty) 'guardianName': _t('guardianName'),
        if (_t('studentId').isNotEmpty) 'studentId': _t('studentId'),
        if (_t('parentIqamaId').isNotEmpty) 'parentIqamaId': _t('parentIqamaId'),
        if (_t('bloodGroup').isNotEmpty) 'bloodGroup': _t('bloodGroup'),
        if (shift != null && shift!.isNotEmpty) 'shift': shift,
        'instituteId': instituteId,
      };

  void dispose() {
    for (final c in text.values) {
      c.dispose();
    }
  }
}

class BulkAddStudentsScreen extends ConsumerStatefulWidget {
  const BulkAddStudentsScreen({super.key});

  @override
  ConsumerState<BulkAddStudentsScreen> createState() => _BulkAddStudentsScreenState();
}

class _BulkAddStudentsScreenState extends ConsumerState<BulkAddStudentsScreen> {
  List<_StudentRow> _rows = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rows = List.generate(5, (_) => _StudentRow()); // start with a few blank rows
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  // ── Row management ──────────────────────────────────────────────────────────
  void _addRows([int n = 1]) => setState(() {
        for (var i = 0; i < n; i++) {
          _rows.add(_StudentRow());
        }
      });

  void _removeRow(int index) => setState(() {
        _rows.removeAt(index).dispose();
        if (_rows.isEmpty) _rows.add(_StudentRow());
      });

  // ── Import (Excel .xlsx or .csv) ─────────────────────────────────────────────
  Future<void> _importFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        withData: true, // needed on web
      );
      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _snack('Could not read the file.');
        return;
      }

      final isXlsx = (file.extension ?? '').toLowerCase() == 'xlsx' ||
          file.name.toLowerCase().endsWith('.xlsx');

      final List<List<String>> table = isXlsx
          ? _readXlsx(bytes)
          : Csv(dynamicTyping: false, skipEmptyLines: true)
              .decode(utf8
                  .decode(bytes, allowMalformed: true)
                  .replaceAll('\r\n', '\n')
                  .replaceAll('\r', '\n'))
              .map((r) => r.map((c) => c?.toString() ?? '').toList())
              .toList();

      _ingestTable(table, isXlsx ? 'Excel' : 'CSV');
    } catch (e) {
      _snack('Import failed: $e');
    }
  }

  /// Reads the first worksheet of an .xlsx into a plain string table.
  List<List<String>> _readXlsx(List<int> bytes) {
    final book = xls.Excel.decodeBytes(bytes);
    if (book.tables.isEmpty) return const [];
    final sheet = book.tables[book.tables.keys.first]!;
    return sheet.rows
        .map((row) => row.map((cell) => cell?.value?.toString().trim() ?? '').toList())
        .toList();
  }

  /// Shared for Excel + CSV: map header row → fields, then fill the grid.
  void _ingestTable(List<List<String>> table, String sourceLabel) {
    if (table.length < 2) {
      _snack('The $sourceLabel file needs a header row and at least one student row.');
      return;
    }

    // Map header names → column keys (tolerant of spacing/case/synonyms).
    final headers = table.first.map(_normalizeHeader).toList();
    final headerIndex = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final key = _headerToKey(headers[i]);
      if (key != null && !headerIndex.containsKey(key)) headerIndex[key] = i;
    }

    if (!headerIndex.containsKey('fullName')) {
      _snack('Could not find a "Full Name" column in the $sourceLabel header.');
      return;
    }

    final imported = <_StudentRow>[];
    for (var r = 1; r < table.length; r++) {
      final cells = table[r];
      if (cells.every((c) => c.trim().isEmpty)) continue; // skip blank lines
      String val(String key) {
        final idx = headerIndex[key];
        if (idx == null || idx >= cells.length) return '';
        return cells[idx].trim();
      }

      final row = _StudentRow();
      row.text['fullName']!.text = val('fullName');
      row.text['grade']!.text = val('grade');
      row.text['parentContact']!.text = val('parentContact');
      row.text['address']!.text = val('address');
      row.text['guardianName']!.text = val('guardianName');
      row.text['studentId']!.text = val('studentId');
      row.text['parentIqamaId']!.text = val('parentIqamaId');
      row.text['bloodGroup']!.text = val('bloodGroup');
      row.gender = _parseGender(val('gender'));
      row.dob = _parseDate(val('dob'));
      row.shift = _parseShift(val('shift'));
      imported.add(row);
    }

    if (imported.isEmpty) {
      _snack('No student rows found in the $sourceLabel file.');
      return;
    }

    setState(() {
      // If the grid only has blank starter rows, replace them; else append.
      if (_rows.every((r) => r.isEmpty)) {
        for (final r in _rows) {
          r.dispose();
        }
        _rows = imported;
      } else {
        _rows.addAll(imported);
      }
    });
    _snack('Imported ${imported.length} row(s) from $sourceLabel. Review, then Save All.');
  }

  static String _normalizeHeader(String h) =>
      h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static String? _headerToKey(String h) {
    const map = {
      'fullname': 'fullName', 'name': 'fullName', 'studentname': 'fullName',
      'studentid': 'studentId', 'admissionnumber': 'studentId', 'admissionno': 'studentId', 'id': 'studentId',
      'grade': 'grade', 'class': 'grade', 'classroom': 'grade',
      'gender': 'gender', 'sex': 'gender',
      'dateofbirth': 'dob', 'dob': 'dob', 'birthdate': 'dob', 'dateofbirthyyyymmdd': 'dob',
      'parentcontact': 'parentContact', 'contact': 'parentContact', 'phone': 'parentContact',
      'mobile': 'parentContact', 'parentphone': 'parentContact', 'guardiancontact': 'parentContact',
      'guardianname': 'guardianName', 'guardian': 'guardianName', 'parentname': 'guardianName', 'fathername': 'guardianName',
      'address': 'address',
      'parentiqamaid': 'parentIqamaId', 'parentiqama': 'parentIqamaId', 'iqama': 'parentIqamaId', 'iqamaid': 'parentIqamaId',
      'bloodgroup': 'bloodGroup', 'blood': 'bloodGroup',
      'shift': 'shift',
    };
    return map[h];
  }

  static Gender? _parseGender(String v) {
    final s = v.trim().toLowerCase();
    if (s == 'male' || s == 'm') return Gender.male;
    if (s == 'female' || s == 'f') return Gender.female;
    return null;
  }

  static String? _parseShift(String v) {
    final s = v.trim().toLowerCase().replaceAll(' ', '');
    if (s == 'shift1' || s == '1' || s == 'shift-1') return 'Shift-1';
    if (s == 'shift2' || s == '2' || s == 'shift-2') return 'Shift-2';
    return null;
  }

  /// Accepts ISO (YYYY-MM-DD) primarily; falls back to D/M/Y or D-M-Y.
  static DateTime? _parseDate(String v) {
    final s = v.trim();
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final parts = s.split(RegExp(r'[/\-.]')).map((p) => p.trim()).toList();
    if (parts.length == 3) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);
      if (a != null && b != null && c != null) {
        // 4-digit first token → year-first; otherwise day-first (D/M/Y).
        if (parts[0].length == 4) return DateTime(a, b, c);
        return DateTime(c, b, a);
      }
    }
    return null;
  }

  // ── Excel template ───────────────────────────────────────────────────────────
  static const _xlsxMime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  Future<void> _downloadExcelTemplate() async {
    try {
      final book = xls.Excel.createExcel();
      // Rename the default sheet to "Students" so there's a single, clear tab.
      final def = book.getDefaultSheet();
      if (def != null && def != 'Students') book.rename(def, 'Students');

      // Header row.
      book.appendRow('Students', _columns.map((c) => xls.TextCellValue(c.label)).toList());
      // One example row (same column order as the grid).
      book.appendRow('Students', const [
        'Ahmed Ali', 'Grade 1', 'Male', '2015-04-12', '0501234567',
        'King Fahd Road, Riyadh', 'Mohammed Ali', '', '1012345678', 'O+', 'Shift-1',
      ].map((v) => xls.TextCellValue(v)).toList());

      final bytes = book.encode();
      if (bytes == null) {
        _snack('Could not build the Excel file.');
        return;
      }
      await _saveBytes(bytes, 'students_template.xlsx', _xlsxMime);
      if (mounted) {
        _snack('Excel template saved. Fill it in Excel, then tap Import.');
      }
    } catch (e) {
      _snack('Template failed: $e');
    }
  }

  /// Web → browser download; mobile/desktop → native save dialog.
  Future<void> _saveBytes(List<int> bytes, String filename, String mime) async {
    if (kIsWeb) {
      triggerBrowserDownload(bytes, filename, mime);
      return;
    }
    await FilePicker.platform.saveFile(
      dialogTitle: 'Save $filename',
      fileName: filename,
      bytes: Uint8List.fromList(bytes),
      type: FileType.custom,
      allowedExtensions: [filename.split('.').last],
    );
  }

  // ── Save ────────────────────────────────────────────────────────────────────
  Future<void> _saveAll() async {
    final submitted = _rows.where((r) => !r.isEmpty).toList();
    if (submitted.isEmpty) {
      _snack('Add at least one student row.');
      return;
    }

    // Quick client-side check so the user fixes obvious gaps before a round-trip.
    final localProblems = <String>[];
    for (var i = 0; i < submitted.length; i++) {
      final r = submitted[i];
      final miss = <String>[];
      if (r._t('fullName').isEmpty) miss.add('Full Name');
      if (r._t('grade').isEmpty) miss.add('Grade');
      if (r.gender == null) miss.add('Gender');
      if (r.dob == null) miss.add('Date of Birth');
      if (r._t('parentContact').isEmpty) miss.add('Parent Contact');
      if (r._t('address').isEmpty) miss.add('Address');
      if (miss.isNotEmpty) localProblems.add('Row ${i + 1}: ${miss.join(', ')}');
    }
    if (localProblems.isNotEmpty) {
      _showErrorsDialog('Please complete these rows', localProblems);
      return;
    }

    setState(() => _saving = true);
    try {
      final instituteId = ref.read(selectedInstituteProvider).id;
      final payloads = submitted.map((r) => r.toPayload(instituteId)).toList();
      final result = await ref.read(studentRepositoryProvider).bulkAddStudents(payloads);

      if (result.createdCount > 0) {
        ref.read(studentControllerProvider.notifier).refresh();
      }

      if (!mounted) return;

      if (result.errorCount == 0) {
        // All rows created — pop; the widget's dispose() frees the controllers.
        Navigator.of(context).pop();
        _snack('✓ ${result.createdCount} student(s) added successfully.');
        return;
      }

      // Partial success: keep only the rows that failed (1-based row numbers
      // from the server) for correction, and dispose the ones that were created
      // so re-saving can't duplicate them. Kept rows are freed by dispose() later.
      final erroredRowNums = result.errors.map((e) => e.row).toSet();
      final keep = <_StudentRow>[];
      for (var i = 0; i < submitted.length; i++) {
        if (erroredRowNums.contains(i + 1)) {
          keep.add(submitted[i]);
        } else {
          submitted[i].dispose();
        }
      }
      // Any leftover blank rows were never submitted — drop them too.
      for (final r in _rows) {
        if (!submitted.contains(r)) r.dispose();
      }

      setState(() => _rows = keep.isEmpty ? [_StudentRow()] : keep);
      _showErrorsDialog(
        '${result.createdCount} added • ${result.errorCount} failed',
        result.errors.map((e) => 'Row ${e.row}${e.name.isNotEmpty ? " (${e.name})" : ""}: ${e.message}').toList(),
        subtitle: 'The failed rows are still shown below — fix them and Save All again.',
      );
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showErrorsDialog(String title, List<String> lines, {String? subtitle}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null) ...[
                  Text(subtitle, style: TextStyle(color: context.colors.textSecondary)),
                  const Gap(12),
                ],
                ...lines.map((l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 14, color: Colors.red),
                          const Gap(8),
                          Expanded(child: Text(l)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final classrooms = ref.watch(classroomControllerProvider).asData?.value ?? const [];
    final gradeNames = classrooms.map((c) => c.name).toList();
    final filledCount = _rows.where((r) => !r.isEmpty).length;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Bulk Add Students',
            subtitle: 'Enter students in a sheet, or import a CSV file',
          ),
          _toolbar(context, gradeNames),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _totalWidth,
                  child: Column(
                    children: [
                      _headerRow(context),
                      for (var i = 0; i < _rows.length; i++) _dataRow(context, i, gradeNames),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _saveBar(context, filledCount),
        ],
      ),
    );
  }

  Widget _toolbar(BuildContext context, List<String> gradeNames) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _addRows(1),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Row'),
              ),
              OutlinedButton.icon(
                onPressed: () => _addRows(5),
                icon: const Icon(LucideIcons.rows, size: 16),
                label: const Text('+5 Rows'),
              ),
              ElevatedButton.icon(
                onPressed: _importFile,
                icon: const Icon(LucideIcons.upload, size: 16),
                label: const Text('Import Excel / CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _downloadExcelTemplate,
                icon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
                label: const Text('Excel Template'),
              ),
            ],
          ),
          if (gradeNames.isNotEmpty) ...[
            const Gap(6),
            Text(
              'Grades available: ${gradeNames.join(", ")}',
              style: context.typography.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerRow(BuildContext context) {
    final colors = context.colors;
    Widget cell(double w, String label, {bool required = false}) => Container(
          width: w,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Text.rich(
            TextSpan(
              text: label,
              style: context.typography.bodySmall.copyWith(fontWeight: FontWeight.w700),
              children: required
                  ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
                  : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          SizedBox(width: _rowNumWidth, child: cell(_rowNumWidth, '#')),
          for (final c in _columns) cell(c.width, c.label, required: c.required),
          const SizedBox(width: _deleteColWidth),
        ],
      ),
    );
  }

  Widget _dataRow(BuildContext context, int index, List<String> gradeNames) {
    final colors = context.colors;
    final row = _rows[index];

    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? colors.white : colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _rowNumWidth,
            child: Center(
              child: Text('${index + 1}',
                  style: context.typography.bodySmall.copyWith(color: colors.textSecondary)),
            ),
          ),
          for (final c in _columns) _buildCell(context, row, c, gradeNames),
          SizedBox(
            width: _deleteColWidth,
            child: IconButton(
              icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
              tooltip: 'Remove row',
              onPressed: () => _removeRow(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, _StudentRow row, _Col col, List<String> gradeNames) {
    final pad = const EdgeInsets.symmetric(horizontal: 4, vertical: 5);

    if (col.key == 'gender') {
      return Container(
        width: col.width,
        padding: pad,
        child: DropdownButtonFormField<Gender>(
          initialValue: row.gender,
          isExpanded: true,
          isDense: true,
          decoration: _cellDecoration('—'),
          items: const [
            DropdownMenuItem(value: Gender.male, child: Text('Male')),
            DropdownMenuItem(value: Gender.female, child: Text('Female')),
          ],
          onChanged: (g) => setState(() => row.gender = g),
        ),
      );
    }

    if (col.key == 'shift') {
      return Container(
        width: col.width,
        padding: pad,
        child: DropdownButtonFormField<String>(
          initialValue: row.shift,
          isExpanded: true,
          isDense: true,
          decoration: _cellDecoration('—'),
          items: const [
            DropdownMenuItem(value: 'Shift-1', child: Text('Shift-1')),
            DropdownMenuItem(value: 'Shift-2', child: Text('Shift-2')),
          ],
          onChanged: (s) => setState(() => row.shift = s),
        ),
      );
    }

    if (col.key == 'dob') {
      final label = row.dob != null ? DateFormat('yyyy-MM-dd').format(row.dob!) : 'Pick date';
      return Container(
        width: col.width,
        padding: pad,
        child: OutlinedButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: row.dob ?? DateTime(2015),
              firstDate: DateTime(1990),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => row.dob = picked);
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            side: BorderSide(color: context.colors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: row.dob != null ? context.colors.textPrimary : context.colors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    // Plain text cell.
    return Container(
      width: col.width,
      padding: pad,
      child: TextField(
        controller: row.text[col.key],
        style: const TextStyle(fontSize: 13),
        decoration: _cellDecoration(col.key == 'studentId' ? 'auto' : ''),
        keyboardType: col.key == 'parentContact' ? TextInputType.phone : TextInputType.text,
      ),
    );
  }

  InputDecoration _cellDecoration(String hint) => InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: context.colors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.colors.border),
        ),
      );

  Widget _saveBar(BuildContext context, int filledCount) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: colors.white,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Text('$filledCount student(s) ready',
              style: context.typography.bodyMedium.copyWith(color: colors.textSecondary)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _saving ? null : _saveAll,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.check, size: 18),
            label: Text(_saving ? 'Saving...' : 'Save All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
