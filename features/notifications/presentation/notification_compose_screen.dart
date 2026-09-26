import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/utils/class_sort.dart';
import 'package:abm_madrasa/features/notifications/data/notification_repository.dart';
import 'package:abm_madrasa/features/notifications/presentation/notifications_screen.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/features/teachers/domain/teacher_model.dart';
import 'package:abm_madrasa/features/teachers/presentation/teacher_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum NotificationTarget { broadcast, teacher, student }

/// Admin/staff screen to compose a broadcast notification or 1-to-1 message.
class NotificationComposeScreen extends ConsumerStatefulWidget {
  const NotificationComposeScreen({super.key});

  @override
  ConsumerState<NotificationComposeScreen> createState() => _NotificationComposeScreenState();
}

class _NotificationComposeScreenState extends ConsumerState<NotificationComposeScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  static const _types = ['Announcement', 'General', 'Event', 'Holiday'];
  static const _audiences = [('all', 'Everyone'), ('students', 'Students'), ('teachers', 'Teachers')];

  NotificationTarget _target = NotificationTarget.broadcast;
  String _type = 'Announcement';
  String _audience = 'all';
  String _grade = ''; // '' = all grades
  bool _important = false;
  bool _sending = false;

  // 1-to-1 state
  TeacherModel? _selectedTeacher;
  String _selectedClassForStudent = '';
  StudentModel? _selectedStudent;
  List<StudentModel> _studentsInClass = [];
  bool _loadingStudents = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _onClassForStudentChanged(String className) async {
    setState(() {
      _selectedClassForStudent = className;
      _selectedStudent = null;
      _studentsInClass = [];
      _loadingStudents = className.isNotEmpty;
    });

    if (className.isEmpty) return;

    try {
      final list = await ref.read(studentRepositoryProvider).getStudents(classroom: className);
      if (!mounted) return;
      setState(() {
        _studentsInClass = list;
        _loadingStudents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStudents = false);
    }
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A title or subject is required.')));
      return;
    }

    if (_target == NotificationTarget.teacher && _selectedTeacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a teacher.')));
      return;
    }

    if (_target == NotificationTarget.student && _selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a student.')));
      return;
    }

    setState(() => _sending = true);
    try {
      if (_target == NotificationTarget.teacher) {
        await ref.read(notificationRepositoryProvider).sendDirect(
              recipientType: 'teacher',
              recipientId: _selectedTeacher!.id,
              title: title,
              body: _bodyCtrl.text.trim(),
              priority: _important ? 'Important' : 'Normal',
            );
      } else if (_target == NotificationTarget.student) {
        await ref.read(notificationRepositoryProvider).sendDirect(
              recipientType: 'student',
              recipientId: _selectedStudent!.id,
              title: title,
              body: _bodyCtrl.text.trim(),
              priority: _important ? 'Important' : 'Normal',
            );
      } else {
        await ref.read(notificationRepositoryProvider).compose(
              title: title,
              body: _bodyCtrl.text.trim(),
              type: _type,
              priority: _important ? 'Important' : 'Normal',
              audienceRole: _audience,
              grade: _audience == 'students' ? _grade : '',
            );
      }

      ref.invalidate(adminNotificationsProvider);
      ref.invalidate(myNotificationsProvider);
      if (!mounted) return;
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() {
        _important = false;
        _sending = false;
        _selectedTeacher = null;
        _selectedStudent = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_target == NotificationTarget.broadcast ? 'Notification sent.' : 'Direct message sent.'),
          backgroundColor: const Color(0xFF2F855A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send. ${friendlyErrorMessage(e)}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final recent = ref.watch(adminNotificationsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const ABMPageHeader(
            title: 'Compose & Send Messages',
            subtitle: 'Broadcast notices or send one-to-one direct messages.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _card(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Target Type Selector
                      _label(context, 'Send To'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _targetChoice(context, LucideIcons.megaphone, 'Broadcast Notice', NotificationTarget.broadcast),
                          _targetChoice(context, LucideIcons.userCheck, 'Specific Teacher', NotificationTarget.teacher),
                          _targetChoice(context, LucideIcons.graduationCap, 'Specific Student', NotificationTarget.student),
                        ],
                      ),
                      const Gap(18),

                      // If Specific Teacher
                      if (_target == NotificationTarget.teacher) ...[
                        _label(context, 'Select Teacher'),
                        _teacherDropdown(context),
                        const Gap(18),
                      ],

                      // If Specific Student
                      if (_target == NotificationTarget.student) ...[
                        _label(context, '1. Select Class'),
                        _studentClassDropdown(context),
                        const Gap(14),
                        _label(context, '2. Select Student'),
                        _studentDropdown(context),
                        const Gap(18),
                      ],

                      _label(context, _target == NotificationTarget.broadcast ? 'Notice Title' : 'Subject'),
                      TextField(
                        controller: _titleCtrl,
                        decoration: _dec(
                          context,
                          _target == NotificationTarget.broadcast
                              ? 'e.g. Parent meeting on Friday'
                              : 'e.g. Directive regarding Qur’an class attendance',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const Gap(18),

                      _label(context, 'Message Content'),
                      TextField(
                        controller: _bodyCtrl,
                        decoration: _dec(context, 'Write your message details here…'),
                        minLines: 3,
                        maxLines: 6,
                      ),

                      // Broadcast options (Type & Audience)
                      if (_target == NotificationTarget.broadcast) ...[
                        const Gap(18),
                        _label(context, 'Type'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final ty in _types) _choice(context, ty, _type == ty, () => setState(() => _type = ty)),
                          ],
                        ),
                        const Gap(18),
                        _label(context, 'Audience'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final a in _audiences) _choice(context, a.$2, _audience == a.$1, () => setState(() => _audience = a.$1)),
                          ],
                        ),
                        if (_audience == 'students') ...[
                          const Gap(18),
                          _label(context, 'Class (optional)'),
                          _gradeDropdown(context),
                        ],
                      ],

                      const Gap(14),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Mark as Important / Urgent', style: t.bodyMediumSemiBold),
                        subtitle: Text(
                          _target == NotificationTarget.broadcast
                              ? 'Highlights the notice with high priority.'
                              : 'Delivers as an urgent direct notification to the recipient.',
                          style: t.bodySmall.copyWith(color: colors.textSecondary),
                        ),
                        value: _important,
                        activeThumbColor: colors.primary,
                        onChanged: (v) => setState(() => _important = v),
                      ),
                      const Gap(14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(LucideIcons.send, size: 18),
                          label: Text(
                            _sending
                                ? 'Sending…'
                                : (_target == NotificationTarget.broadcast
                                    ? 'Send Broadcast Notice'
                                    : (_target == NotificationTarget.teacher
                                        ? 'Send Direct to Teacher'
                                        : 'Send Direct to Student')),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(20),
                Row(
                  children: [
                    Icon(LucideIcons.history, size: 18, color: colors.primary),
                    const Gap(8),
                    Text('Recently sent', style: t.bodyLargeSemiBold),
                  ],
                ),
                const Gap(12),
                recent.when(
                  loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Text('Couldn’t load recent notices.', style: t.bodySmall.copyWith(color: colors.textSecondary)),
                  data: (items) => items.isEmpty
                      ? _card(context, child: Row(children: [
                          Icon(LucideIcons.inbox, size: 18, color: colors.textSecondary),
                          const Gap(10),
                          Text('Nothing sent yet.', style: t.bodyMedium.copyWith(color: colors.textSecondary)),
                        ]))
                      : Column(children: [for (final n in items) _recentTile(context, n)]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: child,
      );

  Widget _targetChoice(BuildContext context, IconData icon, String label, NotificationTarget target) {
    final colors = context.colors;
    final selected = _target == target;
    return Material(
      color: selected ? colors.primary.withValues(alpha: 0.12) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? colors.primary : colors.border, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _target = target),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? colors.primary : colors.textSecondary),
              const Gap(8),
              Text(
                label,
                style: context.typography.bodySmall.copyWith(
                  color: selected ? colors.primary : colors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teacherDropdown(BuildContext context) {
    final colors = context.colors;
    final teachersAsync = ref.watch(teacherListProvider(''));
    return teachersAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
      error: (e, _) => Text('Failed to load teachers: $e', style: TextStyle(color: colors.red, fontSize: 12)),
      data: (teachers) {
        if (teachers.isEmpty) {
          return Text('No teachers found.', style: TextStyle(color: colors.textSecondary, fontSize: 13));
        }
        return DropdownButtonFormField<TeacherModel>(
          initialValue: _selectedTeacher,
          decoration: _dec(context, 'Choose a teacher to message'),
          isExpanded: true,
          items: [
            for (final t in teachers)
              DropdownMenuItem(
                value: t,
                child: Text(
                  '${t.fullName} (${t.employeeId})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) => setState(() => _selectedTeacher = v),
        );
      },
    );
  }

  Widget _studentClassDropdown(BuildContext context) {
    final colors = context.colors;
    final classes = ref.watch(classroomControllerProvider);
    return classes.maybeWhen(
      data: (list) {
        final names = sortClassNames(list.map((c) => c.name).toSet());
        return DropdownButtonFormField<String>(
          initialValue: _selectedClassForStudent.isEmpty ? null : _selectedClassForStudent,
          decoration: _dec(context, 'Choose classroom first'),
          items: [
            for (final n in names) DropdownMenuItem(value: n, child: Text(n)),
          ],
          onChanged: (v) {
            if (v != null) _onClassForStudentChanged(v);
          },
        );
      },
      orElse: () => Text('Loading classes…', style: context.typography.bodySmall.copyWith(color: colors.textSecondary)),
    );
  }

  Widget _studentDropdown(BuildContext context) {
    final colors = context.colors;
    if (_selectedClassForStudent.isEmpty) {
      return Text('Please select a class above first to see students.',
          style: TextStyle(color: colors.textSecondary, fontSize: 12));
    }
    if (_loadingStudents) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_studentsInClass.isEmpty) {
      return Text('No students found in this class.', style: TextStyle(color: colors.textSecondary, fontSize: 12));
    }

    return DropdownButtonFormField<StudentModel>(
      key: ValueKey('students_in_$_selectedClassForStudent'),
      initialValue: _selectedStudent,
      decoration: _dec(context, 'Choose a student'),
      isExpanded: true,
      items: [
        for (final s in _studentsInClass)
          DropdownMenuItem(
            value: s,
            child: Text(
              '${s.fullName}${s.admissionNumber.isNotEmpty ? ' (${s.admissionNumber})' : ''}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) => setState(() => _selectedStudent = v),
    );
  }

  Widget _choice(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.primary.withValues(alpha: 0.12) : Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: selected ? colors.primary : colors.border, width: selected ? 1.4 : 1)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(label,
              style: context.typography.bodySmall.copyWith(
                color: selected ? colors.primary : colors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              )),
        ),
      ),
    );
  }

  Widget _gradeDropdown(BuildContext context) {
    final colors = context.colors;
    final classes = ref.watch(classroomControllerProvider);
    return classes.maybeWhen(
      data: (list) {
        final names = sortClassNames(list.map((c) => c.name).toSet());
        return DropdownButtonFormField<String>(
          initialValue: _grade,
          decoration: _dec(context, 'All classes'),
          items: [
            const DropdownMenuItem(value: '', child: Text('All classes')),
            for (final n in names) DropdownMenuItem(value: n, child: Text(n)),
          ],
          onChanged: (v) => setState(() => _grade = v ?? ''),
        );
      },
      orElse: () => Text('Loading classes…', style: context.typography.bodySmall.copyWith(color: colors.textSecondary)),
    );
  }

  Widget _recentTile(BuildContext context, NotificationItem n) {
    final colors = context.colors;
    final t = context.typography;
    final v = notificationVisual(context, n.type);
    
    String recipientLabel;
    if (n.isDirectMessage) {
      if (n.recipientType == 'teacher') {
        recipientLabel = n.teacherName.isNotEmpty ? 'Ustadh ${n.teacherName}' : 'Teacher (Direct)';
      } else if (n.recipientType == 'student') {
        recipientLabel = n.studentName.isNotEmpty ? '${n.studentName} (Student)' : 'Student (Direct)';
      } else {
        recipientLabel = 'Direct Message';
      }
    } else {
      recipientLabel = n.audienceRole == 'students'
          ? (n.grade.isEmpty ? 'All Students' : n.grade)
          : n.audienceRole == 'teachers'
              ? 'All Teachers'
              : 'Everyone';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
      child: Row(
        children: [
          Icon(v.icon, size: 18, color: v.color),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title, style: t.bodyMediumSemiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (n.isDirectMessage) ...[
                      const Gap(6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B46C1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '1-to-1',
                          style: TextStyle(color: Color(0xFF6B46C1), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(2),
                Text(
                  [
                    'To: $recipientLabel',
                    if (n.createdAt != null) DateFormat('dd MMM').format(n.createdAt!.toLocal()),
                    if (n.readCount > 0) 'Seen (${n.readCount})',
                  ].join('  ·  '),
                  style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2, size: 18, color: colors.red),
            tooltip: 'Delete notification',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok = await confirmActionDialog(
                context,
                title: 'Delete Notification',
                message: 'Delete "${n.title}"? This cannot be undone.',
                icon: LucideIcons.trash2,
              );
              if (!ok) return;
              try {
                await ref.read(notificationRepositoryProvider).delete(n.id);
                ref.invalidate(adminNotificationsProvider);
                ref.invalidate(myNotificationsProvider);
                messenger.showSnackBar(const SnackBar(content: Text('Notification deleted.')));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s, style: context.typography.bodyMediumSemiBold),
      );

  InputDecoration _dec(BuildContext context, String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
