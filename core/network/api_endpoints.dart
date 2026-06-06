class ApiEndpoints {
  static const String baseUrl = 'https://api.abm-madrasa.edu/v1'; // Placeholder

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  // Students
  static const String students = '/students';
  static String studentDetail(String id) => '/students/$id';

  // Attendance
  static const String attendance = '/attendance';
  static String classAttendance(String classId, String date) => '/attendance/$classId?date=$date';

  // Timetable
  static const String timetable = '/timetable';
  static String classTimetable(String classId) => '/timetable/$classId';

  // Fees
  static const String fees = '/fees';
  static String studentFees(String studentId) => '/fees/student/$studentId';

  // Finance
  static const String transactions = '/finance/transactions';
  static const String financeSummary = '/finance/summary';
}
