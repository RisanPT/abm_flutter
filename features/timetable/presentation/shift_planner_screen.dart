import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/timetable/presentation/shift_planner_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_pattern_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

class ShiftPlannerScreen extends ConsumerStatefulWidget {
  const ShiftPlannerScreen({super.key});

  @override
  ConsumerState<ShiftPlannerScreen> createState() => _ShiftPlannerScreenState();
}

class _ShiftPlannerScreenState extends ConsumerState<ShiftPlannerScreen> {
  String _selectedShift = 'Shift-1';
  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDates = {};

  @override
  void initState() {
    super.initState();
    // Load dates for the initial month and shift
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlan();
    });
  }

  void _loadPlan() async {
    final dates = await ref.read(
        shiftPlannerControllerProvider(_selectedShift, _focusedDay.year, _focusedDay.month).future);
    setState(() {
      _selectedDates.clear();
      for (var date in dates) {
        // normalize to UTC midnight
        _selectedDates.add(DateTime.utc(date.year, date.month, date.day));
      }
    });
  }

  void _savePlan() async {
    try {
      await ref.read(
          shiftPlannerControllerProvider(_selectedShift, _focusedDay.year, _focusedDay.month)
              .notifier)
          .savePlan(_selectedDates.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Shift plan saved successfully'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save plan: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isMobile = context.isMobile;

    final isLoading = ref.watch(
        shiftPlannerControllerProvider(_selectedShift, _focusedDay.year, _focusedDay.month)).isLoading;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0F4A3A),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: AbmPatternPainter(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const BackButton(color: Colors.white),
                            const Gap(8),
                            Text(
                              'Shift Planner',
                              style: typography.h3.copyWith(
                                color: Colors.white,
                                fontSize: isMobile ? 20 : 24,
                              ),
                            ),
                          ],
                        ),
                        const Gap(24),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (_selectedShift != 'Shift-1') {
                                      setState(() {
                                        _selectedShift = 'Shift-1';
                                      });
                                      _loadPlan();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedShift == 'Shift-1'
                                          ? const Color(0xFFE8EFEA)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Shift-1',
                                      style: typography.bodyMediumSemiBold.copyWith(
                                        color: _selectedShift == 'Shift-1'
                                            ? const Color(0xFF163D32)
                                            : const Color(0xFF8A8A81),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (_selectedShift != 'Shift-2') {
                                      setState(() {
                                        _selectedShift = 'Shift-2';
                                      });
                                      _loadPlan();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedShift == 'Shift-2'
                                          ? const Color(0xFFE8EFEA)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Shift-2',
                                      style: typography.bodyMediumSemiBold.copyWith(
                                        color: _selectedShift == 'Shift-2'
                                            ? const Color(0xFF163D32)
                                            : const Color(0xFF8A8A81),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colors.border),
                          ),
                          child: TableCalendar(
                            firstDay: DateTime(2020),
                            lastDay: DateTime(2100),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) {
                              return _selectedDates.contains(DateTime.utc(day.year, day.month, day.day));
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              final normDay = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
                              setState(() {
                                if (_selectedDates.contains(normDay)) {
                                  _selectedDates.remove(normDay);
                                } else {
                                  _selectedDates.add(normDay);
                                }
                                _focusedDay = focusedDay;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
                              });
                              _loadPlan();
                            },
                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: typography.bodyLargeSemiBold.copyWith(
                                color: const Color(0xFF163D32),
                              ),
                            ),
                            calendarStyle: CalendarStyle(
                              selectedDecoration: const BoxDecoration(
                                color: Color(0xFFD6B64C),
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: const Color(0xFFD6B64C).withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const Gap(24),
                        Row(
                          children: [
                            const Icon(LucideIcons.info, size: 20, color: Color(0xFF8A8A81)),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                'Select the dates when classes will be held for $_selectedShift in ${DateFormat.MMMM().format(_focusedDay)}. Attendance can only be marked on these dates.',
                                style: typography.bodySmall.copyWith(
                                  color: const Color(0xFF8A8A81),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(32),
                        ABMButton(
                          text: 'Save Shift Plan',
                          onPressed: _savePlan,
                          icon: LucideIcons.save,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
