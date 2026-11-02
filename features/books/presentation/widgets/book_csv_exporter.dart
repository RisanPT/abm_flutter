import 'dart:convert';
import 'dart:io';

import 'package:abm_madrasa/core/utils/web_download.dart';
import 'package:abm_madrasa/features/books/domain/book_model.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BookCsvExporter {
  static const List<String> csvHeaders = [
    'Book Code',
    'Title',
    'Subject',
    'Grade',
    'Price (SAR)',
    'Stock Quantity',
    'Total Value (SAR)',
    'Status',
    'Author',
    'Publisher',
    'Edition',
    'ISBN',
    'Description',
  ];

  static Future<void> exportBooks(List<BookModel> books, BuildContext context) async {
    try {
      final rows = <List<dynamic>>[];
      rows.add(csvHeaders);

      for (final b in books) {
        rows.add([
          b.bookCode,
          b.title,
          b.subject,
          b.grade,
          b.price.toStringAsFixed(2),
          b.stockQuantity,
          b.totalValue.toStringAsFixed(2),
          b.status,
          b.author,
          b.publisher,
          b.edition,
          b.isbn,
          b.description,
        ]);
      }

      final csvData = Csv().encode(rows);
      final bytes = utf8.encode(csvData);
      final dateStamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filename = 'madrasa_books_$dateStamp.csv';

      if (kIsWeb) {
        triggerBrowserDownload(bytes, filename, 'text/csv;charset=utf-8;');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded $filename'),
              backgroundColor: const Color(0xFF0F4A3A),
            ),
          );
        }
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/csv', name: filename)],
          text: 'Books Inventory Export ($dateStamp)',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  static Future<void> downloadSampleTemplate(BuildContext context) async {
    try {
      final sampleRows = <List<dynamic>>[];
      sampleRows.add([
        'Book Code',
        'Title',
        'Subject',
        'Grade',
        'Price',
        'Stock Quantity',
        'Author',
        'Publisher',
        'Description',
      ]);
      sampleRows.add([
        'BK-101',
        'Noorani Qaida',
        'Quran',
        'STD-1',
        15.00,
        50,
        'Sheikh Noor',
        'Darul Kutub',
        'Basic Quran recitation reader',
      ]);
      sampleRows.add([
        'BK-102',
        'Fiqh Al-Muyassar Part 1',
        'Fiqh',
        'STD-3',
        25.00,
        35,
        'Scholars Panel',
        'Madrasa Press',
        'Islamic jurisprudence textbook',
      ]);
      sampleRows.add([
        'BK-103',
        'Durus Al-Lughah Al-Arabiyyah',
        'Arabic',
        'STD-4',
        30.00,
        20,
        'Dr. V. Abdur Rahim',
        'Islamic Foundation',
        'Arabic grammar and vocabulary',
      ]);

      final csvData = Csv().encode(sampleRows);
      final bytes = utf8.encode(csvData);
      const filename = 'books_import_sample_template.csv';

      if (kIsWeb) {
        triggerBrowserDownload(bytes, filename, 'text/csv;charset=utf-8;');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Downloaded sample template: $filename'),
              backgroundColor: Color(0xFF0F4A3A),
            ),
          );
        }
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/csv', name: filename)],
          text: 'Books Sample Import Template',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download template: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}
