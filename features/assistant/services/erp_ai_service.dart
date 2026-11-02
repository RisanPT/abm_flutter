import 'package:dio/dio.dart';

class AssistantAction {
  final String route;
  final String label;

  const AssistantAction({required this.route, required this.label});
}

class ChatMessage {
  final String id;
  final String role; // 'user' or 'model'
  final String text;
  final DateTime timestamp;
  final List<AssistantAction> actions;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.actions = const [],
    this.isError = false,
  });

  bool get isUser => role == 'user';
}

class ErpAiService {
  static const String _defaultApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String _model = 'gemini-3.5-flash-lite';
  static const String _apiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  final Dio _dio;
  final List<Map<String, dynamic>> _chatHistory = [];

  ErpAiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 12),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  static const String _systemInstruction = '''
You are the intelligent, polite, and helpful AI Support Assistant for the "Anas Bin Malik Madrasa ERP" system.
Your mission is to guide Ustads (teachers), administrators, and staff on how to use every feature of the Madrasa ERP efficiently.

CORE INSTRUCTIONS:
1. Provide concise, clear, step-by-step guidance in friendly English (with Islamic greetings when appropriate like "Assalamu Alaikum").
2. Keep explanations simple, practical, and directly actionable.
3. CRITICAL: Whenever mentioning or recommending an ERP feature or page, ALWAYS include deep-link action tags using this exact format:
   [ACTION:/route_name:Button Label]
   For example:
   - To open Attendance: [ACTION:/attendance:Go to Attendance]
   - To open Student Attendance Report: [ACTION:/attendance-report/student:Student Attendance Report]
   - To open Teacher Attendance Report: [ACTION:/attendance-report/teacher:Teacher Attendance Report]
   - To open Hifz Log: [ACTION:/hifz:Open Hifz Records]
   - To open Homework: [ACTION:/homework:Manage Homework]
   - To open Exams: [ACTION:/exams:View Exams & Marks]
   - To open Progress Reports: [ACTION:/progress-reports:Open Progress Reports]
   - To add Progress Report: [ACTION:/progress-reports/add:New Progress Report]
   - To open Timetable: [ACTION:/timetable:View Timetable]
   - To open Shift Planner: [ACTION:/shift-planner:Open Shift Planner]
   - To open Class Timetable: [ACTION:/class-timetable:Class Timetable]
   - To open Student Directory: [ACTION:/students:Open Students Directory]
   - To add a Student: [ACTION:/add-student:Add New Student]
   - To bulk import Students: [ACTION:/bulk-add-students:Bulk Import Students]
   - To manage Teachers: [ACTION:/teachers:Manage Teachers]
   - To manage Classrooms: [ACTION:/classrooms:Manage Classrooms]
   - To manage Transport: [ACTION:/transport:Transport Management]
   - To manage Student Leaves: [ACTION:/student-leave:Review Leaves]
   - To view Notifications: [ACTION:/notifications:Open Notifications]
   - To compose Notification: [ACTION:/notifications/compose:Compose Notification]
   - To open Finance/Fees: [ACTION:/finance:Go to Finance]
   - To check Outstanding Dues: [ACTION:/outstanding-dues:View Outstanding Dues]
   - To manage Fee Setup: [ACTION:/fee-setup:Fee Setup]
   - To manage Family Discounts: [ACTION:/family-fees:Family Fees]
   - To record Fee Collection: [ACTION:/accounts:Fee Collection]
   - To record Income/Expense: [ACTION:/income-entry:Income & Expense Entry]
   - To manage Payroll: [ACTION:/payroll:Staff Payroll]
   - To open Data Backup: [ACTION:/data-backup:Export / Backup Data]
   - To open Study Materials: [ACTION:/materials:Study Materials]
   - To manage Institutes: [ACTION:/institutes:Institute Branches]
   - To manage Permissions & Roles: [ACTION:/permissions:User Permissions]
   - To manage Website Content: [ACTION:/website-content:Website Content]
   - To open System Settings: [ACTION:/settings:System Settings]

KEY WORKFLOWS IN ANAS BIN MALIK MADRASA ERP:
1. Attendance:
   - Path: /attendance
   - Steps: Select Class, Section, and Date. Students are marked Present by default. Tap to toggle Absent, Late, or Excused. Click Save Attendance. Reports are available at /attendance-report/student and /attendance-report/teacher.
2. Quran Hifz & Revision Tracking:
   - Path: /hifz
   - Tracks 3 core disciplines:
     * Sabaq (daily new lesson: Surah, Ayat from-to, status, rating)
     * Sabqi (recent revisions: past few juz/surahs)
     * Manzil (retaining memorized portions / back revisions)
   - Filter by Class, search student, tap row to log or update entries.
3. Homework & Assignments:
   - Path: /homework
   - Steps: Click "+ New Homework", select Class and Subject, enter title and instructions, set submission due date, optionally attach reference docs, and save.
4. Exams & Grading:
   - Path: /exams
   - Steps: Click "+ New Exam" to schedule an assessment. Tap "Enter Marks" on an exam card to record student scores subject by subject. Percentage and grades are calculated automatically.
5. Progress Reports:
   - Path: /progress-reports
   - Steps: View generated term reports or click "+ New Progress Report" (/progress-reports/add). Select Class and Student, fill academic scores, Quran evaluation, and teacher remarks, then save and print.
6. Shift Planner, Timetable & Class Schedules:
   - Paths: Shift Planner /shift-planner, Timetable /timetable, Class Timetable (view by date) /class-timetable.
   - The madrasa runs on TWO shifts (Shift-1 and Shift-2), and each shift has its own class days. The whole class calendar is built in the Shift Planner, in three stages:
   - STAGE 1 — Plan the class days: in the Shift Planner pick the shift tab (Shift-1 or Shift-2) and the month. Use "Bulk Plan" to mark a weekday pattern (for example every Thursday and Friday) across a month or the whole academic year; or set the "Default Shift Schedule" once and tap "Auto-fill" to apply it. Mark non-class days with "Holiday". Planned days turn into class days; holidays and cancelled days get no classes.
   - STAGE 2 — Build a day's timetable: tap a planned day to open the day editor. Pick a classroom, then add each period with its Subject, Ustad (teacher), start/end time and room. Tap "Save Draft" to keep working, or "Publish" to make it live. Important: students and teachers only see Published classes, and attendance can only be marked for a published class day.
   - STAGE 3 — Make it repeat (so you do not rebuild every week): right after you Publish a day, choose "Repeat weekly" to save it as that class's weekly pattern. It then fills every future same-weekday for the rest of the academic year, AND any new month you Bulk-Plan later inherits the pattern automatically. If you hand-edit one specific day it overrides the pattern and is never overwritten. For a one-off copy instead, use the day menu then "Copy to future weeks".
   - To review: the Timetable (/timetable) shows the month grid of scheduled classes; Class Timetable / View by Date (/class-timetable) shows one date's full schedule.
   - Common fixes: if a future week looks empty, it was Bulk-Planned (days exist) but no timetable was built or repeated yet — open a day, build it, and use "Repeat weekly". If a class has no attendance roster, check it is scheduled on the correct shift and the day is Published.
7. Student Directory & Admission:
   - Path: /students
   - Steps: Filter by class, search by name or admission number. Register a new student via "+ Add Student" (/add-student) or upload an Excel file via "Bulk Import" (/bulk-add-students).
8. Teachers & Faculty:
   - Path: /teachers
   - Steps: View teacher directory, track teacher attendance, assign subjects and classrooms, and view active payroll statuses.
9. Classrooms & Sections:
   - Path: /classrooms
   - Steps: Create classes, add sections (e.g. A, B), set student capacities, and assign class Ustads/mentors.
10. Transport Management:
    - Path: /transport
    - Steps: Manage bus routes, vehicles, driver contact info, and assign students to their designated pickup/drop-off routes.
11. Student Leaves & Absentee Requests:
    - Path: /student-leave
    - Steps: Review pending leave applications submitted by parents or ustads. Approve or reject with remarks. Approved leaves automatically reflect in the attendance register.
12. Notifications & Circulars:
    - Path: /notifications
    - Steps: View incoming notices and urgent circulars. Administrators can tap "+ Compose" (/notifications/compose) to broadcast circulars to teachers, parents, or specific classes.
13. Finance, Fees & Accounts:
    - Path: /finance
    - Steps: Configure grade fees in /fee-setup, record fee collection receipts in /accounts, manage sibling discounts in /family-fees, and track fee arrears in /outstanding-dues.
14. Income & Expense Entry:
    - Path: /income-entry
    - Steps: Record madrasa donations, general income, utilities, and daily operational expenditures with receipt numbers.
15. Data Backup & Export:
    - Path: /data-backup
    - Steps: Export students, fees, attendance, and exam grades to Excel or JSON backups to ensure offline data safety.
16. Study Materials & Library:
    - Path: /materials
    - Steps: Upload subject PDFs, syllabus documents, Arabic worksheets, and audio references for students and teachers.
17. Institutes & Multi-Branch:
    - Path: /institutes
    - Steps: Configure madrasa branches, contact info, logo, and branch-specific academic terms.
18. User Permissions & Roles:
    - Path: /permissions
    - Steps: Manage system roles (Head Master, Teacher, Accountant, Parent) and customize granular access permissions.

Tone: Professional, warm, respectful, concise. Never invent imaginary third-party links. Only use internal app routes described above.
''';

  /// Sends a message to Gemini and returns the assistant's reply.
  Future<ChatMessage> sendMessage(String userMessage) async {
    final now = DateTime.now();
    // Add user message to history
    _chatHistory.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ]
    });

    try {
      final response = await _dio.post(
        '$_apiEndpoint?key=$_defaultApiKey',
        data: {
          'systemInstruction': {
            'parts': [
              {'text': _systemInstruction}
            ]
          },
          'contents': _chatHistory,
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 800,
          },
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final rawText = parts[0]['text']?.toString() ?? '';
            final parsed = _parseResponse(rawText);

            // Record assistant turn in history
            _chatHistory.add({
              'role': 'model',
              'parts': [
                {'text': rawText}
              ]
            });

            return ChatMessage(
              id: 'msg_${now.millisecondsSinceEpoch}',
              role: 'model',
              text: parsed.cleanedText,
              timestamp: DateTime.now(),
              actions: parsed.actions,
            );
          }
        }
      }

      // If response format was unexpected, fall back to offline assistant
      return _generateLocalFallback(userMessage, now);
    } catch (_) {
      // Offline fallback: ensure staff always gets an answer even without internet or on API limits
      return _generateLocalFallback(userMessage, now);
    }
  }

  /// Clears the active conversation context
  void clearHistory() {
    _chatHistory.clear();
  }

  /// Extracts [ACTION:/route:Button Text] tags from AI response
  _ParsedResponse _parseResponse(String raw) {
    final actions = <AssistantAction>[];
    final regex = RegExp(r'\[ACTION:([^:\]]+):([^\]]+)\]');

    final cleaned = raw.replaceAllMapped(regex, (match) {
      final route = match.group(1)?.trim() ?? '';
      final label = match.group(2)?.trim() ?? '';
      if (route.isNotEmpty && label.isNotEmpty) {
        actions.add(AssistantAction(route: route, label: label));
      }
      return ''; // Strip action tags from display text
    }).trim();

    return _ParsedResponse(
      cleanedText: cleaned,
      actions: actions,
    );
  }

  /// Comprehensive local rule-based knowledge base fallback for offline or quota issues
  ChatMessage _generateLocalFallback(String query, DateTime timestamp) {
    final q = query.toLowerCase();

    // 1. Attendance
    if (q.contains('attend') || q.contains('absent') || q.contains('present') || q.contains('roll call')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**How to Mark Daily Attendance:**\n\n1. Open the **Attendance** screen.\n2. Pick the Class, Section, and Date.\n3. Students are marked Present by default. Tap any student to switch to Absent, Late, or Excused.\n4. Click **Save Attendance** to confirm records.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/attendance', label: 'Go to Attendance'),
          const AssistantAction(
              route: '/attendance-report/student', label: 'Student Attendance Report'),
          const AssistantAction(
              route: '/attendance-report/teacher', label: 'Teacher Attendance Report'),
        ],
      );
    }

    // 2. Quran Hifz
    if (q.contains('hifz') ||
        q.contains('quran') ||
        q.contains('sabaq') ||
        q.contains('sabqi') ||
        q.contains('manzil') ||
        q.contains('surah') ||
        q.contains('juz') ||
        q.contains('memoriz')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**How to Log Hifz & Quran Memorization:**\n\n1. Open the **Hifz** module.\n2. Filter by Class and search for the student.\n3. Tap on the student row to log:\n   • **Sabaq** (new daily lesson: Surah & Ayah range)\n   • **Sabqi** (recent revision)\n   • **Manzil** (memorized retention)\n4. Assign a performance grade and tap **Save Entry**.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/hifz', label: 'Open Hifz Records'),
        ],
      );
    }

    // 3. Homework & Assignments
    if (q.contains('homework') || q.contains('assignment') || q.contains('task')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**How to Assign Homework:**\n\n1. Go to the **Homework** screen.\n2. Tap the **+ New Homework** button.\n3. Choose the target Class, Subject, Title, and Instructions.\n4. Set the Due Date and tap **Publish Homework**.\n5. You can track student submissions directly from the homework list.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/homework', label: 'Open Homework'),
        ],
      );
    }

    // 4. Exams & Marks
    if (q.contains('exam') || q.contains('mark') || q.contains('score') || q.contains('result') || q.contains('grade')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**How to Manage Exams & Marks:**\n\n1. Go to **Exams**.\n2. Tap **+ New Exam** to schedule a test or term assessment.\n3. Find the exam card in the list and tap **Enter Marks**.\n4. Record scores for each student. The system will compute percentages and letter grades automatically.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/exams', label: 'Open Exams & Marks'),
        ],
      );
    }

    // 5. Progress Reports
    if (q.contains('progress') || q.contains('report') || q.contains('card') || q.contains('evaluation')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**How to Generate Progress Reports:**\n\n1. Navigate to **Progress Reports**.\n2. Tap **+ New Progress Report**.\n3. Select the Class and Student.\n4. Fill in academic scores, Quran evaluation, and teacher remarks.\n5. Save and preview or download the student's printable report card.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(
              route: '/progress-reports', label: 'View Progress Reports'),
          const AssistantAction(
              route: '/progress-reports/add', label: 'New Progress Report'),
        ],
      );
    }

    // 6. Transport
    if (q.contains('transport') || q.contains('bus') || q.contains('driver') || q.contains('route') || q.contains('vehicle')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**How to Manage Madrasa Transport:**\n\n1. Open the **Transport** section.\n2. Manage bus routes, vehicle details, and driver contact numbers.\n3. Assign students to their respective pickup and drop-off routes.\n4. View student transport lists and driver assignments at a glance.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/transport', label: 'Transport Management'),
        ],
      );
    }

    // 7. Student Leaves
    if (q.contains('leave') || q.contains('sick') || q.contains('permission') || q.contains('absence request')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**How to Manage Student Leaves:**\n\n1. Go to the **Student Leave** screen.\n2. Review pending leave requests submitted by parents or ustads.\n3. Check reason, leave dates, and supporting notes.\n4. Click **Approve** or **Reject** with optional remarks.\n5. Approved leaves automatically reflect in the attendance register.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/student-leave', label: 'Review Student Leaves'),
        ],
      );
    }

    // 8. Notifications & Circulars
    if (q.contains('notification') || q.contains('notice') || q.contains('circular') || q.contains('announcement') || q.contains('message')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**How to View & Send Notifications:**\n\n1. Open **Notifications** from the bell icon or sidebar.\n2. Tap any notice card to view full details.\n3. Administrators can tap **+ Compose** to send a circular to all students, parents, or teachers.\n4. You can also send direct messages to the office administration.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/notifications', label: 'View Notifications'),
          const AssistantAction(route: '/notifications/compose', label: 'Compose Circular'),
        ],
      );
    }

    // 9. Teachers & Ustads
    if (q.contains('teacher') || q.contains('ustad') || q.contains('staff') || q.contains('faculty')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**Managing Teachers & Ustads:**\n\n1. Open the **Teachers** directory.\n2. Browse staff profiles, contact numbers, and subject assignments.\n3. Monitor daily teacher attendance and active payroll statuses.\n4. Assign Ustads to specific class periods in the Timetable / Shift Planner.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/teachers', label: 'Teachers Directory'),
          const AssistantAction(route: '/shift-planner', label: 'Assign in Shift Planner'),
        ],
      );
    }

    // 10. Classrooms & Sections
    if (q.contains('classroom') || q.contains('class') || q.contains('section') || q.contains('grade')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**Managing Classrooms & Sections:**\n\n1. Open **Classrooms** from the sidebar.\n2. Tap **+ Add Class** to create a new class or standard.\n3. Define sections (e.g., Section A, Section B) and student capacities.\n4. Designate the class mentor or primary Ustad.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/classrooms', label: 'Manage Classrooms'),
        ],
      );
    }

    // 11. Students Directory & Admission
    if (q.contains('student') || q.contains('admit') || q.contains('admission') || q.contains('register')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**Managing Students & Admissions:**\n\n1. Open the **Students** directory.\n2. Search by student name, admission number, or filter by Class.\n3. Tap **+ Add Student** for an individual student registration.\n4. Tap **Bulk Import** to upload multiple students at once from an Excel / CSV sheet.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/students', label: 'Student Directory'),
          const AssistantAction(route: '/add-student', label: 'Add New Student'),
          const AssistantAction(route: '/bulk-add-students', label: 'Bulk Import'),
        ],
      );
    }

    // 12. Timetable & Shift Planning
    if (q.contains('timetable') || q.contains('schedule') || q.contains('period') || q.contains('shift')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**Shift Planner & Timetable**\n\nThe madrasa runs two shifts (Shift-1 and Shift-2), each with its own class days. Build the calendar in the **Shift Planner** in 3 stages:\n\n1. **Plan the days** — pick the shift tab and month, then **Bulk Plan** a weekday pattern (e.g. every Thu & Fri) for the month or whole year, or **Auto-fill** from the Default Shift Schedule. Mark non-class days as **Holiday**.\n2. **Build a day** — tap a planned day, choose a classroom, add each period (subject, Ustad, time, room), then **Save Draft** or **Publish**. Only published classes are visible and attendable.\n3. **Repeat weekly** — after publishing, tap **Repeat weekly** to save it as that class's weekly pattern; it fills every future same-weekday and any month you plan later inherits it. Hand-editing one day overrides the pattern.\n\nReview schedules in the **Timetable** (month grid) or **Class Timetable** (by date). Tip: an empty future week means it was planned but no timetable was built/repeated yet.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/timetable', label: 'View Timetable'),
          const AssistantAction(route: '/shift-planner', label: 'Shift Planner'),
          const AssistantAction(route: '/class-timetable', label: 'Class Timetable'),
        ],
      );
    }

    // 13. Fees & Finance
    if (q.contains('fee') ||
        q.contains('due') ||
        q.contains('pay') ||
        q.contains('finance') ||
        q.contains('money') ||
        q.contains('tuition')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**How to Manage Madrasa Fees & Finance:**\n\n1. Go to **Finance**.\n2. Use **Fee Setup** to configure monthly/annual tuition fees per grade.\n3. Record student receipts under **Fee Collection**.\n4. Track unpaid balances under **Outstanding Dues**.\n5. Multi-sibling discounts can be configured under **Family Fees**.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/finance', label: 'Finance Overview'),
          const AssistantAction(
              route: '/outstanding-dues', label: 'Outstanding Dues'),
          const AssistantAction(route: '/fee-setup', label: 'Fee Setup'),
          const AssistantAction(route: '/family-fees', label: 'Family Discounts'),
        ],
      );
    }

    // 14. Accounts, Income & Expenses
    if (q.contains('income') || q.contains('expense') || q.contains('account') || q.contains('donation') || q.contains('receipt')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**Recording Income & Expenses:**\n\n1. Go to **Income & Expense Entry**.\n2. Select whether you are recording Income (donations, sponsorships, grants) or Expense (utilities, maintenance, supplies).\n3. Enter amount, category, date, and receipt number.\n4. Click **Save Entry** to update financial ledgers.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/income-entry', label: 'Income & Expense Entry'),
          const AssistantAction(route: '/accounts', label: 'Accounts Overview'),
        ],
      );
    }

    // 15. Payroll & Salaries
    if (q.contains('payroll') || q.contains('salary') || q.contains('stipend') || q.contains('wage')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**Managing Staff Payroll:**\n\n1. Open **Payroll** from Finance.\n2. Review monthly staff salaries, allowances, and deductions.\n3. Generate payroll sheets for the active month.\n4. Mark payouts as completed upon disbursement.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/payroll', label: 'Staff Payroll'),
        ],
      );
    }

    // 16. Data Backup & Export
    if (q.contains('backup') || q.contains('download') || q.contains('export')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**How to Export System Data & Backups:**\n\n1. Open **Data Backup** from the sidebar or administration.\n2. Choose which data modules to export (Students, Fees, Attendance, or All Records).\n3. Click **Export Excel** or **Download Backup** to securely save the records to your local device.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(
              route: '/data-backup', label: 'Go to Data Backup'),
        ],
      );
    }

    // 17. Study Materials
    if (q.contains('material') || q.contains('book') || q.contains('pdf') || q.contains('syllabus') || q.contains('library')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**Managing Study Materials:**\n\n1. Open the **Study Materials** screen.\n2. Filter by Class and Subject.\n3. Tap **Upload Material** to attach PDF files, worksheets, or notes.\n4. Students and ustads can download the materials directly from their portals.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/materials', label: 'Study Materials'),
        ],
      );
    }

    // 18. User Permissions & Admin
    if (q.contains('permission') || q.contains('role') || q.contains('admin') || q.contains('access') || q.contains('user')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**Managing User Permissions & Roles:**\n\n1. Open **Administration** > **User Permissions**.\n2. Inspect roles (Head Master, Teacher, Accountant, Parent).\n3. Enable or disable specific read/write access privileges per role.\n4. Changes apply across all staff accounts immediately.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/permissions', label: 'User Permissions'),
          const AssistantAction(route: '/admin', label: 'Admin Overview'),
        ],
      );
    }

    // 19. Institutes & Branches
    if (q.contains('institute') || q.contains('branch') || q.contains('campus') || q.contains('profile')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**Managing Institutes & Branches:**\n\n1. Go to **Administration** > **Institutes**.\n2. Configure madrasa branch details, address, logo, and contact info.\n3. Switch active institute context or set branch-specific academic terms.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/institutes', label: 'Institutes & Branches'),
        ],
      );
    }

    // 20. Website Content
    if (q.contains('website') || q.contains('landing') || q.contains('portal') || q.contains('public')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**Managing Website Content:**\n\n1. Go to **Administration** > **Website Content**.\n2. Update public announcements, banners, madrasa introduction, and contact details.\n3. Changes reflect on the public landing page instantly.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/website-content', label: 'Website Content'),
        ],
      );
    }

    // 21. Settings
    if (q.contains('setting') || q.contains('cutoff') || q.contains('time') || q.contains('term')) {
      return ChatMessage(
        id: 'fallback_${timestamp.millisecondsSinceEpoch}',
        role: 'model',
        text:
            "**System Settings:**\n\n1. Open **Settings** from the sidebar.\n2. Configure Attendance Cut-off Times (for automatic late marks).\n3. Set Evaluation Terms and grading scales.\n4. Manage app preferences and notifications.",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/settings', label: 'System Settings'),
        ],
      );
    }

    // Default Fallback
    return ChatMessage(
      id: 'fallback_${timestamp.millisecondsSinceEpoch}',
      role: 'model',
      text:
          "Assalamu Alaikum! I am your Anas Bin Malik Madrasa ERP assistant. You can ask me how to do anything in the ERP:\n\n• **Daily Attendance** & Reports\n• **Quran Hifz** (Sabaq, Sabqi, Manzil)\n• **Homework** & Student Assignments\n• **Exams** & Grade Recording\n• **Progress Reports** & Report Cards\n• **Timetable** & Shift Planning\n• **Transport** & Bus Routes\n• **Student Leaves** & Approvals\n• **Fees, Finance** & Outstanding Dues\n• **Data Backup** & Excel Export\n\nWhat would you like assistance with?",
      timestamp: DateTime.now(),
      actions: [
        const AssistantAction(route: '/dashboard', label: 'Dashboard'),
        const AssistantAction(route: '/attendance', label: 'Attendance'),
        const AssistantAction(route: '/hifz', label: 'Hifz Tracker'),
        const AssistantAction(route: '/homework', label: 'Homework'),
      ],
    );
  }
}

class _ParsedResponse {
  final String cleanedText;
  final List<AssistantAction> actions;

  _ParsedResponse({required this.cleanedText, required this.actions});
}
