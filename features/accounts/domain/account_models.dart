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
    this.monthsCount,
  });

  final String id;
  final String monthLabel;
  final double totalDue;
  final double totalPaid;
  final String status;
  final List<AccountLineItem> lineItems;
  final String? receiptNumber;
  final DateTime? paidOn;
  final int? monthsCount;

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
        monthsCount: (json['monthsCount'] as num?)?.toInt(),
      );
}

class MonthPreviewItem {
  const MonthPreviewItem({
    required this.monthLabel,
    required this.lineItems,
    required this.totalDue,
    required this.totalPaid,
    required this.balance,
    required this.status,
    required this.waived,
  });

  final String monthLabel;
  final List<AccountLineItem> lineItems;
  final double totalDue;
  final double totalPaid;
  final double balance;
  final String status;
  final bool waived;

  factory MonthPreviewItem.fromJson(Map<String, dynamic> j) => MonthPreviewItem(
        monthLabel: (j['monthLabel'] ?? '').toString(),
        lineItems: ((j['lineItems'] as List?) ?? [])
            .map((e) => AccountLineItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        totalDue: (j['totalDue'] as num?)?.toDouble() ?? 0,
        totalPaid: (j['totalPaid'] as num?)?.toDouble() ?? 0,
        balance: (j['balance'] as num?)?.toDouble() ?? 0,
        status: (j['status'] ?? 'Pending').toString(),
        waived: j['waived'] == true,
      );
}

class MultiMonthPreview {
  const MultiMonthPreview({
    required this.studentId,
    required this.months,
    required this.totalDue,
    required this.totalPaid,
    required this.totalBalance,
    required this.monthsCount,
  });

  final String studentId;
  final List<MonthPreviewItem> months;
  final double totalDue;
  final double totalPaid;
  final double totalBalance;
  final int monthsCount;

  factory MultiMonthPreview.fromJson(Map<String, dynamic> j) => MultiMonthPreview(
        studentId: (j['studentId'] ?? '').toString(),
        months: ((j['months'] as List?) ?? [])
            .map((e) => MonthPreviewItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        totalDue: (j['totalDue'] as num?)?.toDouble() ?? 0,
        totalPaid: (j['totalPaid'] as num?)?.toDouble() ?? 0,
        totalBalance: (j['totalBalance'] as num?)?.toDouble() ?? 0,
        monthsCount: (j['monthsCount'] as num?)?.toInt() ?? 0,
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

// ── Family / sibling combined fee collection ─────────────────────────────────

/// A parent (guardian) with all their enrolled children and the family's total
/// outstanding balance, as shown in the Family Fees list.
class FamilySummary {
  const FamilySummary({
    required this.key,
    required this.guardianName,
    required this.parentContact,
    required this.parentIqamaId,
    required this.childCount,
    required this.totalBalance,
    required this.children,
  });

  final String key;
  final String guardianName;
  final String parentContact;
  final String parentIqamaId;
  final int childCount;
  final double totalBalance;
  final List<FamilyChildSummary> children;

  factory FamilySummary.fromJson(Map<String, dynamic> j) => FamilySummary(
        key: (j['key'] ?? '').toString(),
        guardianName: (j['guardianName'] ?? 'Unknown').toString(),
        parentContact: (j['parentContact'] ?? '').toString(),
        parentIqamaId: (j['parentIqamaId'] ?? '').toString(),
        childCount: (j['childCount'] as num?)?.toInt() ?? 0,
        totalBalance: (j['totalBalance'] as num?)?.toDouble() ?? 0,
        children: ((j['children'] as List?) ?? [])
            .map((e) => FamilyChildSummary.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class FamilyChildSummary {
  const FamilyChildSummary({
    required this.studentId,
    required this.fullName,
    required this.admissionNumber,
    required this.classroom,
    required this.balance,
    required this.status,
    this.photoUrl,
  });

  final String studentId;
  final String fullName;
  final String admissionNumber;
  final String classroom;
  final double balance;
  final String status;
  final String? photoUrl;

  factory FamilyChildSummary.fromJson(Map<String, dynamic> j) => FamilyChildSummary(
        studentId: (j['studentId'] ?? '').toString(),
        fullName: (j['fullName'] ?? '').toString(),
        admissionNumber: (j['admissionNumber'] ?? '').toString(),
        classroom: (j['classroom'] ?? '').toString(),
        balance: (j['balance'] as num?)?.toDouble() ?? 0,
        status: (j['status'] ?? 'Pending').toString(),
        photoUrl: j['photoUrl'] as String?,
      );
}

/// Full detail for one family: each child's current-month bill + ledger totals,
/// plus the institute's sibling-discount configuration.
class FamilyDetail {
  const FamilyDetail({
    required this.key,
    required this.guardianName,
    required this.parentContact,
    required this.parentIqamaId,
    required this.childCount,
    required this.siblingDiscount,
    required this.totalOutstanding,
    required this.totalCurrentDue,
    required this.totalArrears,
    required this.totalAdvance,
    required this.children,
  });

  final String key;
  final String guardianName;
  final String parentContact;
  final String parentIqamaId;
  final int childCount;
  final SiblingDiscountInfo siblingDiscount;
  final double totalOutstanding;
  final double totalCurrentDue;
  final double totalArrears;
  final double totalAdvance;
  final List<FamilyChildDetail> children;

  factory FamilyDetail.fromJson(Map<String, dynamic> j) {
    final totals = Map<String, dynamic>.from(j['totals'] as Map? ?? {});
    return FamilyDetail(
      key: (j['key'] ?? '').toString(),
      guardianName: (j['guardianName'] ?? 'Unknown').toString(),
      parentContact: (j['parentContact'] ?? '').toString(),
      parentIqamaId: (j['parentIqamaId'] ?? '').toString(),
      childCount: (j['childCount'] as num?)?.toInt() ?? 0,
      siblingDiscount: SiblingDiscountInfo.fromJson(
          Map<String, dynamic>.from(j['siblingDiscount'] as Map? ?? {})),
      totalOutstanding: (totals['totalOutstanding'] as num?)?.toDouble() ?? 0,
      totalCurrentDue: (totals['totalCurrentDue'] as num?)?.toDouble() ?? 0,
      totalArrears: (totals['totalArrears'] as num?)?.toDouble() ?? 0,
      totalAdvance: (totals['totalAdvance'] as num?)?.toDouble() ?? 0,
      children: ((j['children'] as List?) ?? [])
          .map((e) => FamilyChildDetail.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class SiblingDiscountInfo {
  const SiblingDiscountInfo({
    required this.enabled,
    required this.fromChild,
    required this.amount,
  });
  final bool enabled;
  final int fromChild;
  final double amount;

  factory SiblingDiscountInfo.fromJson(Map<String, dynamic> j) => SiblingDiscountInfo(
        enabled: j['enabled'] == true,
        fromChild: (j['fromChild'] as num?)?.toInt() ?? 3,
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
      );
}

class FamilyChildDetail {
  const FamilyChildDetail({
    required this.studentId,
    required this.fullName,
    required this.admissionNumber,
    required this.classroom,
    required this.currentMonth,
    required this.lineItems,
    required this.currentBalance,
    required this.arrears,
    required this.advanceBalance,
    required this.totalOutstanding,
    required this.status,
    this.photoUrl,
  });

  final String studentId;
  final String fullName;
  final String admissionNumber;
  final String classroom;
  final String currentMonth;
  final List<AccountLineItem> lineItems;
  final double currentBalance;
  final double arrears;
  final double advanceBalance;
  final double totalOutstanding;
  final String status;
  final String? photoUrl;

  factory FamilyChildDetail.fromJson(Map<String, dynamic> j) => FamilyChildDetail(
        studentId: (j['studentId'] ?? '').toString(),
        fullName: (j['fullName'] ?? '').toString(),
        admissionNumber: (j['admissionNumber'] ?? '').toString(),
        classroom: (j['classroom'] ?? '').toString(),
        currentMonth: (j['currentMonth'] ?? '').toString(),
        lineItems: ((j['lineItems'] as List?) ?? [])
            .map((e) => AccountLineItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        currentBalance: (j['currentBalance'] as num?)?.toDouble() ?? 0,
        arrears: (j['arrears'] as num?)?.toDouble() ?? 0,
        advanceBalance: (j['advanceBalance'] as num?)?.toDouble() ?? 0,
        totalOutstanding: (j['totalOutstanding'] as num?)?.toDouble() ?? 0,
        status: (j['status'] ?? 'Pending').toString(),
        photoUrl: j['photoUrl'] as String?,
      );
}

/// Result of a combined family collection — one receipt covering every child.
class FamilyReceipt {
  const FamilyReceipt({
    required this.receiptNumber,
    required this.guardianName,
    required this.parentContact,
    required this.totalCollected,
    required this.paidOn,
    required this.children,
  });

  final String receiptNumber;
  final String guardianName;
  final String parentContact;
  final double totalCollected;
  final DateTime paidOn;
  final List<FamilyReceiptChild> children;

  factory FamilyReceipt.fromJson(Map<String, dynamic> j) => FamilyReceipt(
        receiptNumber: (j['receiptNumber'] ?? '').toString(),
        guardianName: (j['guardianName'] ?? '').toString(),
        parentContact: (j['parentContact'] ?? '').toString(),
        totalCollected: (j['totalCollected'] as num?)?.toDouble() ?? 0,
        paidOn: j['collectedAt'] != null
            ? (DateTime.tryParse(j['collectedAt'].toString()) ?? DateTime.now())
            : DateTime.now(),
        children: ((j['children'] as List?) ?? [])
            .map((e) => FamilyReceiptChild.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class FamilyReceiptChild {
  const FamilyReceiptChild({
    required this.studentId,
    required this.fullName,
    required this.admissionNumber,
    required this.classroom,
    required this.monthLabel,
    required this.amountPaid,
    required this.balance,
    required this.status,
    required this.lineItems,
  });

  final String studentId;
  final String fullName;
  final String admissionNumber;
  final String classroom;
  final String monthLabel;
  final double amountPaid;
  final double balance;
  final String status;
  final List<AccountLineItem> lineItems;

  factory FamilyReceiptChild.fromJson(Map<String, dynamic> j) => FamilyReceiptChild(
        studentId: (j['studentId'] ?? '').toString(),
        fullName: (j['fullName'] ?? '').toString(),
        admissionNumber: (j['admissionNumber'] ?? '').toString(),
        classroom: (j['classroom'] ?? '').toString(),
        monthLabel: (j['monthLabel'] ?? '').toString(),
        amountPaid: (j['amountPaid'] as num?)?.toDouble() ?? 0,
        balance: (j['balance'] as num?)?.toDouble() ?? 0,
        status: (j['status'] ?? 'Paid').toString(),
        lineItems: ((j['lineItems'] as List?) ?? [])
            .map((e) => AccountLineItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
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
