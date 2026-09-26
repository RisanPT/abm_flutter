import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/timetable/data/planner_repository.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// Admin / principal screen to set the auto-absent cut-off time per shift + weekday.
/// If a scheduled teacher isn't marked present by this time, the teacher report
/// auto-marks them Absent. A weekday with no time set has no cut-off.
class AttendanceCutoffScreen extends ConsumerStatefulWidget {
  const AttendanceCutoffScreen({super.key});

  @override
  ConsumerState<AttendanceCutoffScreen> createState() => _AttendanceCutoffScreenState();
}

class _AttendanceCutoffScreenState extends ConsumerState<AttendanceCutoffScreen> {
  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _shifts = ['Shift-1', 'Shift-2'];

  bool _loading = true;
  bool _saving = false;
  String? _error;
  // shift -> weekday(0-6) -> 'HH:mm'
  final Map<String, Map<int, String>> _cutoffs = {'Shift-1': {}, 'Shift-2': {}};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final id = ref.read(selectedInstituteProvider).id;
      final list = await ref.read(plannerRepositoryProvider).getAttendanceCutoffs(id);
      for (final e in list) {
        final shift = e['shift']?.toString();
        final weekday = (e['weekday'] as num?)?.toInt();
        final time = e['time']?.toString();
        if (shift != null && weekday != null && time != null && time.isNotEmpty && _cutoffs.containsKey(shift)) {
          _cutoffs[shift]![weekday] = time;
        }
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = friendlyErrorMessage(e); });
    }
  }

  TimeOfDay? _parse(String? hhmm) {
    if (hhmm == null) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hhmm.trim());
    if (m == null) return null;
    return TimeOfDay(hour: int.parse(m.group(1)!), minute: int.parse(m.group(2)!));
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(String shift, int weekday) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parse(_cutoffs[shift]?[weekday]) ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _cutoffs[shift]![weekday] = _fmt(picked));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final id = ref.read(selectedInstituteProvider).id;
      final payload = <Map<String, dynamic>>[];
      for (final shift in _shifts) {
        _cutoffs[shift]!.forEach((weekday, time) {
          payload.add({'shift': shift, 'weekday': weekday, 'time': time});
        });
      }
      await ref.read(plannerRepositoryProvider).setAttendanceCutoffs(id, payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cut-off times saved'), backgroundColor: Color(0xFF2F855A)),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text('Attendance Cut-off Times', style: typography.h3.copyWith(color: colors.primary))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Set the time by which a scheduled teacher must be marked present. After this time, teachers still not marked are automatically shown as Absent in the report. Leave a day blank for no cut-off.',
                      style: typography.bodySmall.copyWith(color: colors.textSecondary),
                    ),
                    const Gap(16),
                    for (final shift in _shifts) _shiftSection(shift, colors, typography),
                    const Gap(24),
                    ABMButton(text: 'Save', isLoading: _saving, onPressed: _saving ? null : _save),
                    const Gap(24),
                  ],
                ),
    );
  }

  Widget _shiftSection(String shift, ColorExtension colors, TypographyExtension typography) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(shift, style: typography.bodyLargeSemiBold.copyWith(color: colors.primary)),
          const Gap(8),
          for (int wd = 0; wd < 7; wd++) _weekdayRow(shift, wd, colors, typography),
        ],
      ),
    );
  }

  Widget _weekdayRow(String shift, int weekday, ColorExtension colors, TypographyExtension typography) {
    final time = _cutoffs[shift]?[weekday];
    final tod = _parse(time);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text(_weekdays[weekday], style: typography.bodyMedium.copyWith(color: colors.textPrimary))),
          const Spacer(),
          if (tod != null) ...[
            InkWell(
              onTap: () => _pickTime(shift, weekday),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
                ),
                child: Text(tod.format(context), style: typography.bodyMediumSemiBold.copyWith(color: colors.primary)),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: colors.textSecondary),
              tooltip: 'Remove cut-off',
              onPressed: () => setState(() => _cutoffs[shift]!.remove(weekday)),
            ),
          ] else
            TextButton.icon(
              onPressed: () => _pickTime(shift, weekday),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Set time'),
            ),
        ],
      ),
    );
  }
}
