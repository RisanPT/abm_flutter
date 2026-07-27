class StaffCheckin {
  const StaffCheckin({required this.date, required this.status, this.name = '', this.note = ''});

  final DateTime date;
  final String status;
  final String name;
  final String note;

  factory StaffCheckin.fromJson(Map<String, dynamic> j) => StaffCheckin(
        date: j['date'] != null ? DateTime.parse(j['date'] as String) : DateTime.now(),
        status: j['status']?.toString() ?? 'Present',
        name: j['name']?.toString() ?? '',
        note: j['note']?.toString() ?? '',
      );
}

class MyCheckinSummary {
  const MyCheckinSummary({
    required this.month,
    required this.checkedInToday,
    this.todayStatus,
    required this.presentDays,
    required this.records,
  });

  final String month;
  final bool checkedInToday;
  final String? todayStatus;
  final int presentDays;
  final List<StaffCheckin> records;

  factory MyCheckinSummary.fromJson(Map<String, dynamic> j) => MyCheckinSummary(
        month: j['month']?.toString() ?? '',
        checkedInToday: j['checkedInToday'] == true,
        todayStatus: j['todayStatus']?.toString(),
        presentDays: (j['presentDays'] as num?)?.toInt() ?? 0,
        records: (j['records'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(StaffCheckin.fromJson)
            .toList(),
      );
}
