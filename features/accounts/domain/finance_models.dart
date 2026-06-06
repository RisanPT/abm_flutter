class FinanceSummary {
  const FinanceSummary({
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

  factory FinanceSummary.fromJson(Map<String, dynamic> json) => FinanceSummary(
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

class FinanceLineItem {
  const FinanceLineItem({required this.title, required this.amount});

  final String title;
  final double amount;

  factory FinanceLineItem.fromJson(Map<String, dynamic> json) => FinanceLineItem(
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
}

class PaymentHistoryItem {
  const PaymentHistoryItem({
    required this.id,
    required this.monthLabel,
    required this.totalDue,
    required this.totalPaid,
    required this.status,
    this.receiptNumber,
    this.paidOn,
  });

  final String id;
  final String monthLabel;
  final double totalDue;
  final double totalPaid;
  final String status;
  final String? receiptNumber;
  final DateTime? paidOn;

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) =>
      PaymentHistoryItem(
        id: json['id'] as String,
        monthLabel: json['monthLabel'] as String,
        totalDue: (json['totalDue'] as num?)?.toDouble() ?? 0,
        totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'Pending',
        receiptNumber: json['receiptNumber'] as String?,
        paidOn: json['paidOn'] != null
            ? DateTime.tryParse(json['paidOn'] as String)
            : null,
      );
}

class StudentFinanceDetails {
  const StudentFinanceDetails({
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

  final FinanceSummary summary;
  final String monthLabel;
  final List<FinanceLineItem> lineItems;
  final double totalDue;
  final double totalPaid;
  final double balance;
  final String status;
  final String? receiptNumber;
  final List<PaymentHistoryItem> history;

  factory StudentFinanceDetails.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>;
    final currentDue = json['currentDue'] as Map<String, dynamic>;

    return StudentFinanceDetails(
      summary: FinanceSummary(
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
          .map((item) => FinanceLineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalDue: (currentDue['totalDue'] as num?)?.toDouble() ?? 0,
      totalPaid: (currentDue['totalPaid'] as num?)?.toDouble() ?? 0,
      balance: (currentDue['balance'] as num?)?.toDouble() ?? 0,
      status: currentDue['status'] as String? ?? 'Pending',
      receiptNumber: currentDue['receiptNumber'] as String?,
      history: ((json['history'] as List?) ?? [])
          .map((item) => PaymentHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
