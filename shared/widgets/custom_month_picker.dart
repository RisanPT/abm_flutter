import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CustomMonthPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const CustomMonthPicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => CustomMonthPicker(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }

  @override
  State<CustomMonthPicker> createState() => _CustomMonthPickerState();
}

class _CustomMonthPickerState extends State<CustomMonthPicker> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  void _changeYear(int offset) {
    final newYear = _selectedYear + offset;
    if (newYear >= widget.firstDate.year && newYear <= widget.lastDate.year) {
      setState(() {
        _selectedYear = newYear;
        // Adjust month if it falls out of bounds for the new year
        if (_selectedYear == widget.firstDate.year && _selectedMonth < widget.firstDate.month) {
          _selectedMonth = widget.firstDate.month;
        } else if (_selectedYear == widget.lastDate.year && _selectedMonth > widget.lastDate.month) {
          _selectedMonth = widget.lastDate.month;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colors.background,
      elevation: 10,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Year Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _selectedYear > widget.firstDate.year ? () => _changeYear(-1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: colors.textSecondary,
                ),
                Text(
                  _selectedYear.toString(),
                  style: typography.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _selectedYear < widget.lastDate.year ? () => _changeYear(1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: colors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Grid: Months
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthNum = index + 1;
                final isSelected = monthNum == _selectedMonth;
                
                // Determine if this month is selectable based on min/max dates
                bool isDisabled = false;
                if (_selectedYear == widget.firstDate.year && monthNum < widget.firstDate.month) {
                  isDisabled = true;
                }
                if (_selectedYear == widget.lastDate.year && monthNum > widget.lastDate.month) {
                  isDisabled = true;
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isDisabled
                        ? null
                        : () {
                            setState(() {
                              _selectedMonth = monthNum;
                            });
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primary
                            : (isDisabled ? colors.border.withValues(alpha: 0.3) : colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? colors.primary : colors.border,
                          width: isSelected ? 0 : 1,
                        ),
                      ),
                      child: Text(
                        months[index],
                        style: typography.bodyMediumSemiBold.copyWith(
                          color: isSelected
                              ? Colors.white
                              : (isDisabled ? colors.textSecondary.withValues(alpha: 0.5) : colors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(DateTime(_selectedYear, _selectedMonth, 1));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
