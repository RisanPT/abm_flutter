/// Result of a bulk student import (spreadsheet grid or CSV upload).
/// The backend creates each row independently, so a batch can partially succeed.
class BulkImportResult {
  const BulkImportResult({
    required this.createdCount,
    required this.errorCount,
    required this.errors,
  });

  final int createdCount;
  final int errorCount;
  final List<BulkRowError> errors;

  factory BulkImportResult.fromJson(Map<String, dynamic> json) => BulkImportResult(
        createdCount: (json['createdCount'] as num?)?.toInt() ?? 0,
        errorCount: (json['errorCount'] as num?)?.toInt() ?? 0,
        errors: ((json['errors'] as List?) ?? const [])
            .map((e) => BulkRowError.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BulkRowError {
  const BulkRowError({required this.row, required this.name, required this.message});

  /// 1-based position of the row within the submitted batch.
  final int row;
  final String name;
  final String message;

  factory BulkRowError.fromJson(Map<String, dynamic> json) => BulkRowError(
        row: (json['row'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        message: json['message'] as String? ?? 'Unknown error',
      );
}
