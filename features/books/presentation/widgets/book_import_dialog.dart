import 'dart:convert';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/money.dart';
import 'package:abm_madrasa/features/books/presentation/book_controller.dart';
import 'package:abm_madrasa/features/books/presentation/widgets/book_csv_exporter.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BookImportDialog extends ConsumerStatefulWidget {
  const BookImportDialog({super.key});

  @override
  ConsumerState<BookImportDialog> createState() => _BookImportDialogState();
}

class _BookImportRow {
  _BookImportRow({
    required this.title,
    this.bookCode = '',
    this.isbn = '',
    this.subject = 'General',
    this.grade = 'All',
    this.price = 0.0,
    this.stockQuantity = 0,
    this.author = '',
    this.publisher = '',
    this.description = '',
    this.isValid = true,
    this.validationError = '',
  });

  String title;
  String bookCode;
  String isbn;
  String subject;
  String grade;
  double price;
  int stockQuantity;
  String author;
  String publisher;
  String description;
  bool isValid;
  String validationError;

  Map<String, dynamic> toMap() => {
        'title': title,
        'bookCode': bookCode,
        'isbn': isbn,
        'subject': subject,
        'grade': grade,
        'price': price,
        'stockQuantity': stockQuantity,
        'author': author,
        'publisher': publisher,
        'description': description,
      };
}

class _BookImportDialogState extends ConsumerState<BookImportDialog> {
  String? _pickedFileName;
  List<_BookImportRow> _parsedRows = [];
  bool _isParsing = false;
  bool _isImporting = false;
  String? _parsingError;

  Future<void> _pickFile() async {
    setState(() {
      _isParsing = true;
      _parsingError = null;
    });

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) {
        setState(() => _isParsing = false);
        return;
      }

      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _isParsing = false;
          _parsingError = 'Failed to read file content.';
        });
        return;
      }

      _pickedFileName = file.name;
      final isXlsx = (file.extension ?? '').toLowerCase().contains('xls') ||
          file.name.toLowerCase().endsWith('.xlsx') ||
          file.name.toLowerCase().endsWith('.xls');

      final List<List<String>> table = isXlsx
          ? _readExcel(bytes)
          : Csv(dynamicTyping: false, skipEmptyLines: true)
              .decode(
                utf8
                    .decode(bytes, allowMalformed: true)
                    .replaceAll('\r\n', '\n')
                    .replaceAll('\r', '\n'),
              )
              .map((row) => row.map((cell) => cell?.toString().trim() ?? '').toList())
              .toList();

      _processTable(table);
    } catch (e) {
      setState(() {
        _isParsing = false;
        _parsingError = 'Could not parse file: $e';
      });
    }
  }

  List<List<String>> _readExcel(List<int> bytes) {
    final excel = xls.Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return const [];
    final sheet = excel.tables[excel.tables.keys.first]!;
    return sheet.rows
        .map((row) => row.map((cell) => cell?.value?.toString().trim() ?? '').toList())
        .toList();
  }

  void _processTable(List<List<String>> table) {
    if (table.length < 2) {
      setState(() {
        _isParsing = false;
        _parsingError = 'The file must contain a header row and at least one data row.';
      });
      return;
    }

    final headerRow = table.first.map(_normalizeHeader).toList();
    final headerIndex = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final key = _headerToKey(headerRow[i]);
      if (key != null && !headerIndex.containsKey(key)) {
        headerIndex[key] = i;
      }
    }

    if (!headerIndex.containsKey('title')) {
      setState(() {
        _isParsing = false;
        _parsingError = 'Could not find a "Title" or "Book Name" column in the header.';
      });
      return;
    }

    final rows = <_BookImportRow>[];

    for (var r = 1; r < table.length; r++) {
      final cells = table[r];
      if (cells.every((c) => c.trim().isEmpty)) continue;

      String getVal(String key) {
        final idx = headerIndex[key];
        if (idx == null || idx >= cells.length) return '';
        return cells[idx].trim();
      }

      final title = getVal('title');
      if (title.isEmpty) continue;

      final rawPrice = getVal('price').replaceAll(RegExp(r'[^0-9.]'), '');
      final price = double.tryParse(rawPrice) ?? 0.0;

      final rawStock = getVal('stockQuantity').replaceAll(RegExp(r'[^0-9]'), '');
      final stock = int.tryParse(rawStock) ?? 0;

      rows.add(
        _BookImportRow(
          title: title,
          bookCode: getVal('bookCode'),
          isbn: getVal('isbn'),
          subject: getVal('subject').isNotEmpty ? getVal('subject') : 'General',
          grade: getVal('grade').isNotEmpty ? getVal('grade') : 'All',
          price: price,
          stockQuantity: stock,
          author: getVal('author'),
          publisher: getVal('publisher'),
          description: getVal('description'),
          isValid: title.isNotEmpty,
          validationError: title.isEmpty ? 'Title is missing' : '',
        ),
      );
    }

    setState(() {
      _isParsing = false;
      _parsedRows = rows;
      if (rows.isEmpty) {
        _parsingError = 'No valid book records could be found in the file.';
      }
    });
  }

  static String _normalizeHeader(String h) =>
      h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static String? _headerToKey(String h) {
    const map = {
      'title': 'title',
      'booktitle': 'title',
      'bookname': 'title',
      'name': 'title',
      'book': 'title',
      'bookcode': 'bookCode',
      'code': 'bookCode',
      'itemcode': 'bookCode',
      'sku': 'bookCode',
      'id': 'bookCode',
      'isbn': 'isbn',
      'subject': 'subject',
      'category': 'subject',
      'grade': 'grade',
      'class': 'grade',
      'classroom': 'grade',
      'standard': 'grade',
      'price': 'price',
      'rate': 'price',
      'cost': 'price',
      'amount': 'price',
      'unitprice': 'price',
      'stock': 'stockQuantity',
      'quantity': 'stockQuantity',
      'stockquantity': 'stockQuantity',
      'qty': 'stockQuantity',
      'count': 'stockQuantity',
      'available': 'stockQuantity',
      'author': 'author',
      'writer': 'author',
      'publisher': 'publisher',
      'publication': 'publisher',
      'description': 'description',
      'notes': 'description',
      'remarks': 'description',
    };
    return map[h];
  }

  Future<void> _commitImport() async {
    final validRows = _parsedRows.where((r) => r.isValid).toList();
    if (validRows.isEmpty) return;

    setState(() => _isImporting = true);

    final classrooms = ref.read(classroomControllerProvider).value ?? [];
    final classMap = {for (final c in classrooms) c.name.toLowerCase().trim(): c.id};

    final payload = validRows.map((r) {
      final map = r.toMap();
      final clsId = classMap[r.grade.toLowerCase().trim()];
      if (clsId != null) map['classroomId'] = clsId;
      return map;
    }).toList();

    final count = await ref.read(bookControllerProvider.notifier).bulkImport(payload);

    if (!mounted) return;
    setState(() => _isImporting = false);

    if (count > 0) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $count books into inventory!'),
          backgroundColor: const Color(0xFF0F4A3A),
        ),
      );
    } else {
      final err = ref.read(bookControllerProvider).errorMessage ?? 'Import failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final validCount = _parsedRows.where((r) => r.isValid).length;
    final totalUnits = _parsedRows.fold<int>(0, (s, r) => s + r.stockQuantity);
    final totalValue = _parsedRows.fold<double>(0.0, (s, r) => s + (r.price * r.stockQuantity));

    return Dialog(
      backgroundColor: colors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4A3A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.fileSpreadsheet, color: Color(0xFF0F4A3A), size: 24),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Import Books from CSV or Excel', style: typography.h4),
                        const Gap(2),
                        Text(
                          'Upload .csv or .xlsx spreadsheet with book titles, pricing, and stock',
                          style: typography.bodySmall.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => BookCsvExporter.downloadSampleTemplate(context),
                    icon: const Icon(LucideIcons.download, size: 16),
                    label: const Text('Sample Template'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0F4A3A),
                    ),
                  ),
                  const Gap(8),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Gap(16),
              Divider(height: 1, color: colors.border),
              const Gap(16),

              // Upload Box
              InkWell(
                onTap: _isParsing || _isImporting ? null : _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0F4A3A).withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_isParsing) ...[
                        const CircularProgressIndicator(color: Color(0xFF0F4A3A)),
                        const Gap(12),
                        Text('Reading & validating file...', style: typography.bodyMediumSemiBold),
                      ] else ...[
                        Icon(
                          _pickedFileName != null ? LucideIcons.checkCircle2 : LucideIcons.uploadCloud,
                          size: 36,
                          color: const Color(0xFF0F4A3A),
                        ),
                        const Gap(10),
                        Text(
                          _pickedFileName ?? 'Click to choose CSV or Excel (.xlsx) file',
                          style: typography.bodyLargeSemiBold.copyWith(
                            color: _pickedFileName != null ? const Color(0xFF0F4A3A) : colors.textPrimary,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'Supported columns: Title, Code, Grade, Subject, Price, Stock, Author, Publisher',
                          style: typography.bodySmall.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (_parsingError != null) ...[
                const Gap(12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 18),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          _parsingError!,
                          style: typography.bodySmall.copyWith(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_parsedRows.isNotEmpty) ...[
                const Gap(16),
                // Summary preview bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4A3A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detected $validCount valid book(s)',
                        style: typography.bodyMediumSemiBold.copyWith(color: const Color(0xFF0F4A3A)),
                      ),
                      Text(
                        'Total Units: $totalUnits  |  Value: ${sar(totalValue, decimals: 2)}',
                        style: typography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),

                // Table preview
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      itemCount: _parsedRows.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: colors.border),
                      itemBuilder: (context, index) {
                        final item = _parsedRows[index];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: item.isValid ? const Color(0xFF0F4A3A) : Colors.red,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(item.title, style: typography.bodyMediumSemiBold),
                          subtitle: Text(
                            'Grade: ${item.grade} • Subject: ${item.subject}${item.bookCode.isNotEmpty ? " • Code: ${item.bookCode}" : ""}',
                            style: typography.bodySmall.copyWith(color: colors.textSecondary),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                sar(item.price, decimals: 2),
                                style: typography.bodyMediumSemiBold.copyWith(color: const Color(0xFF0F4A3A)),
                              ),
                              Text(
                                '${item.stockQuantity} in stock',
                                style: typography.bodySmall.copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ] else if (_parsingError == null && !_isParsing) ...[
                const Spacer(),
              ],

              const Gap(16),
              Divider(height: 1, color: colors.border),
              const Gap(16),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Gap(12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4A3A),
                    ),
                    onPressed: _parsedRows.isEmpty || validCount == 0 || _isImporting
                        ? null
                        : _commitImport,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(LucideIcons.save, size: 16),
                    label: Text(_isImporting ? 'Importing...' : 'Import $validCount Books'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
