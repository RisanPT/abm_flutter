class AccountSummary {
  const AccountSummary({
    required this.studentId,
    required this.fullName,
    required this.admissionNumber,
    required this.classroom,
    required this.guardianName,
    required this.currentMonth,
    required this.totalDue,
    required this.totalPaid,
    required this.balance,
    required this.status,
    this.photoUrl,
  });

  final String studentId;
  final String fullName;
  final String admissionNumber;
  final String classroom;
  final String guardianName;
  final String? currentMonth;
  final double totalDue;
  final double totalPaid;
  final double balance;
  final String status;
  final String? photoUrl;

  factory AccountSummary.fromJson(Map<String, dynamic> json) => AccountSummary(
        studentId: json['studentId'] as String,
        fullName: json['fullName'] as String,
        admissionNumber: json['admissionNumber'] as String,
        classroom: json['classroom'] as String,
        guardianName: json['guardianName'] as String? ?? 'Unknown',
        currentMonth: json['currentMonth'] as String?,
        totalDue: (json['totalDue'] as num?)?.toDouble() ?? 0,
        totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'Pending',
        photoUrl: json['photoUrl'] as String?,
      );
}

class AccountLineItem {
  const AccountLineItem({
    required this.title,
    required this.amount,
    this.months = const [],
  });

  final String title;
  final double amount;

  /// Month-based billing (1 = Jan … 12 = Dec). Empty = a recurring item billed
  /// every month (waived during vacation months). When set, the item is billed
  /// only in these months (and still charged even during vacation).
  final List<int> months;

  bool get isRecurring => months.isEmpty;

  AccountLineItem copyWith({String? title, double? amount, List<int>? months}) =>
      AccountLineItem(
        title: title ?? this.title,
        amount: amount ?? this.amount,
        months: months ?? this.months,
      );

  factory AccountLineItem.fromJson(Map<String, dynamic> json) => AccountLineItem(
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        months: ((json['months'] as List?) ?? [])
            .map((m) => (m as num).toInt())
            .toList(),
      );
}

class ReceiptHistoryItem {
  const ReceiptHistoryItem({
    required this.id,
    required this.monthLabel,
    required this.totalDue,
    required this.totalPaid,
    required this.status,
    this.lineItems = const [],
    this.receiptNumber,
    this.paidOn,
  });

  final String id;
  final String monthLabel;
  final double totalDue;
  final double totalPaid;
  final String status;
  final List<AccountLineItem> lineItems;
  final String? receiptNumber;
  final DateTime? paidOn;

  factory ReceiptHistoryItem.fromJson(Map<String, dynamic> json) =>
      ReceiptHistoryItem(
        id: json['id'] as String,
        monthLabel: json['monthLabel'] as String,
        totalDue: (json['totalDue'] as num?)?.toDouble() ?? 0,
        totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'Pending',
        lineItems: ((json['lineItems'] as List?) ?? [])
            .map((item) => AccountLineItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        receiptNumber: json['receiptNumber'] as String?,
        paidOn: json['paidOn'] != null
            ? DateTime.tryParse(json['paidOn'] as String)
            : null,
      );
}

class StudentAccountDetails {
  const StudentAccountDetails({
    required this.summary,
    required this.monthLabel,
    required this.lineItems,
    required this.totalDue,
    required this.totalPaid,
    required this.balance,
    required this.status,
    required this.history,
    this.receiptNumber,
  });

  final AccountSummary summary;
  final String monthLabel;
  final List<AccountLineItem> lineItems;
  final double totalDue;
  final double totalPaid;
  final double balance;
  final String status;
  final String? receiptNumber;
  final List<ReceiptHistoryItem> history;

  factory StudentAccountDetails.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>;
    final currentDue = json['currentDue'] as Map<String, dynamic>;

    return StudentAccountDetails(
      summary: AccountSummary(
        studentId: student['id'] as String,
        fullName: student['fullName'] as String,
        admissionNumber: student['admissionNumber'] as String,
        classroom: student['classroom'] as String,
        guardianName: student['guardianName'] as String? ?? 'Unknown',
        currentMonth: currentDue['monthLabel'] as String?,
        totalDue: (currentDue['totalDue'] as num?)?.toDouble() ?? 0,
        totalPaid: (currentDue['totalPaid'] as num?)?.toDouble() ?? 0,
        balance: (currentDue['balance'] as num?)?.toDouble() ?? 0,
        status: currentDue['status'] as String? ?? 'Pending',
        photoUrl: student['photoUrl'] as String?,
      ),
      monthLabel: currentDue['monthLabel'] as String? ?? '',
      lineItems: ((currentDue['lineItems'] as List?) ?? [])
          .map((item) => AccountLineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalDue: (currentDue['totalDue'] as num?)?.toDouble() ?? 0,
      totalPaid: (currentDue['totalPaid'] as num?)?.toDouble() ?? 0,
      balance: (currentDue['balance'] as num?)?.toDouble() ?? 0,
      status: currentDue['status'] as String? ?? 'Pending',
      receiptNumber: currentDue['receiptNumber'] as String?,
      history: ((json['history'] as List?) ?? [])
          .map((item) => ReceiptHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FeeStructureModel {
  const FeeStructureModel({
    required this.id,
    required this.instituteId,
    required this.grade,
    required this.totalAmount,
    required this.lineItems,
  });

  final String id;
  final String instituteId;
  final String grade;
  final double totalAmount;
  final List<AccountLineItem> lineItems;

  bool get hasTransport => lineItems.any((item) => 
      item.title.toLowerCase().contains('transport') || 
      item.title.toLowerCase().contains('bus'));

  factory FeeStructureModel.fromJson(Map<String, dynamic> json) => FeeStructureModel(
        id: json['_id'] as String,
        instituteId: json['instituteId'] as String,
        grade: json['grade'] as String,
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        lineItems: ((json['lineItems'] as List?) ?? [])
            .map((item) => AccountLineItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) '_id': id,
        'instituteId': instituteId,
        'grade': grade,
        'totalAmount': totalAmount,
        'lineItems': lineItems
            .map((e) => {'title': e.title, 'amount': e.amount, 'months': e.months})
            .toList(),
      };
}
