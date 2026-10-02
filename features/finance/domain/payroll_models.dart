/// Breakdown for a specific shift worked by a teacher in a month.
class PayrollShiftBreakdown {
  const PayrollShiftBreakdown({
    required this.shift,
    required this.gross,
    required this.expected,
    required this.attended,
    required this.missed,
    this.onLeave = 0,
    required this.deduction,
    required this.net,
  });

  final String shift;
  final num gross;
  final int expected;
  final int attended;
  final int missed;
  final int onLeave;
  final num deduction;
  final num net;

  factory PayrollShiftBreakdown.fromJson(Map<String, dynamic> j) => PayrollShiftBreakdown(
        shift: j['shift']?.toString() ?? '',
        gross: (j['gross'] as num?) ?? 0,
        expected: (j['expected'] as num?)?.toInt() ?? 0,
        attended: (j['attended'] as num?)?.toInt() ?? 0,
        missed: (j['missed'] as num?)?.toInt() ?? 0,
        onLeave: (j['onLeave'] as num?)?.toInt() ?? 0,
        deduction: (j['deduction'] as num?) ?? 0,
        net: (j['net'] as num?) ?? 0,
      );
}

/// One teacher's attendance-driven salary breakdown for a month.
class PayrollRow {
  const PayrollRow({
    required this.teacherId,
    required this.teacherName,
    this.employeeId = '',
    this.shifts = const [],
    this.isDualShift = false,
    this.shiftsBreakdown = const [],
    required this.gross,
    required this.expected,
    required this.attended,
    required this.missed,
    required this.onLeave,
    required this.deduction,
    required this.net,
    required this.alreadyPaid,
    required this.fullyAttended,
    this.basis = 'classes',
    this.presentDays,
  });

  final String teacherId;
  final String teacherName;
  final String employeeId;
  final List<String> shifts;
  final bool isDualShift;
  final List<PayrollShiftBreakdown> shiftsBreakdown;
  final num gross;
  final int expected;
  final int attended;
  final int missed;
  final int onLeave;
  final num deduction;
  final num net;
  final bool alreadyPaid;
  final bool fullyAttended;
  final String basis; // 'classes' | 'checkin'
  final int? presentDays; // self check-in present days (non-teaching staff)

  static int _int(dynamic v) => (v as num?)?.toInt() ?? 0;
  static num _num(dynamic v) => (v as num?) ?? 0;

  factory PayrollRow.fromJson(Map<String, dynamic> j) {
    final rawShifts = (j['shifts'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    final rawBreakdowns = (j['shiftsBreakdown'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PayrollShiftBreakdown.fromJson)
        .toList();

    return PayrollRow(
      teacherId: j['teacherId']?.toString() ?? '',
      teacherName: j['teacherName']?.toString() ?? '',
      employeeId: j['employeeId']?.toString() ?? '',
      shifts: rawShifts,
      isDualShift: j['isDualShift'] == true || rawShifts.length > 1,
      shiftsBreakdown: rawBreakdowns,
      gross: _num(j['gross']),
      expected: _int(j['expected']),
      attended: _int(j['attended']),
      missed: _int(j['missed']),
      onLeave: _int(j['onLeave']),
      deduction: _num(j['deduction']),
      net: _num(j['net']),
      alreadyPaid: j['alreadyPaid'] == true,
      fullyAttended: j['fullyAttended'] == true,
      basis: j['basis']?.toString() ?? 'classes',
      presentDays: (j['presentDays'] as num?)?.toInt(),
    );
  }
}

/// The whole payroll preview for a month.
class PayrollPreview {
  const PayrollPreview({
    required this.month,
    required this.rows,
    required this.grossTotal,
    required this.deductionTotal,
    required this.netTotal,
  });

  final String month;
  final List<PayrollRow> rows;
  final num grossTotal;
  final num deductionTotal;
  final num netTotal;

  factory PayrollPreview.fromJson(Map<String, dynamic> j) {
    final rows = (j['teachers'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PayrollRow.fromJson)
        .toList();
    final totals = (j['totals'] as Map<String, dynamic>?) ?? const {};
    return PayrollPreview(
      month: j['month']?.toString() ?? '',
      rows: rows,
      grossTotal: (totals['gross'] as num?) ?? 0,
      deductionTotal: (totals['deduction'] as num?) ?? 0,
      netTotal: (totals['net'] as num?) ?? 0,
    );
  }
}
