import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/settings/presentation/evaluation_terms_screen.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _madrasaGreen = Color(0xFF1B3D2F);
const _madrasaGold = Color(0xFFB8860B);

class ProgressReportUploadScreen extends ConsumerStatefulWidget {
  const ProgressReportUploadScreen({super.key, this.existingReport});

  final Map<String, dynamic>? existingReport;

  @override
  ConsumerState<ProgressReportUploadScreen> createState() => _ProgressReportUploadScreenState();
}

class _ProgressReportUploadScreenState extends ConsumerState<ProgressReportUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  List<StudentModel> _allStudents = [];
  StudentModel? _selectedStudent;
  String? _selectedClass;
  bool _isLoadingStudents = false;

  // Evaluation term
  String _selectedTerm = kDefaultEvaluationTerms.first;
  List<String> _terms = List<String>.from(kDefaultEvaluationTerms);

  String _normalizeTerm(String raw) {
    if (_terms.contains(raw)) return raw;
    String? mapped;
    switch (raw.trim().toLowerCase()) {
      case 'term 1':
      case 'term-1':
        mapped = 'Term-1';
        break;
      case 'term 2':
      case 'term-2':
        mapped = 'Term-2';
        break;
      case 'exam 1':
      case 'exam-1':
        mapped = 'Exam-1';
        break;
      case 'exam 2':
      case 'exam-2':
        mapped = 'Exam-2';
        break;
      case 'final term':
      case 'final':
        mapped = 'Term-2';
        break;
    }
    if (mapped != null && _terms.contains(mapped)) return mapped;
    return _terms.isNotEmpty ? _terms.first : raw;
  }

  late List<Map<String, dynamic>> _subjectScores;
  late final TextEditingController _remarksController;
  bool _isSaving = false;

  final List<String> _commonSubjects = [
    'Arabic Grammar',
    'Quran Hifz',
    'Tajweed',
    'Fiqh',
    'Hadith',
    'Aqeedah',
    'Islamic Studies',
    'English',
  ];

  final List<String> _remarkPresets = [
    'MashaAllah, excellent progress',
    'Good recitation & tajweed',
    'Shows steady improvement',
    'Needs more practice in revision',
    'Well behaved, active and punctual',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.existingReport != null) {
      _selectedTerm = _normalizeTerm((widget.existingReport!['term'] ?? '').toString());
      _remarksController = TextEditingController(text: widget.existingReport!['remarks'] ?? '');

      final grades = widget.existingReport!['grades'] as List<dynamic>? ?? [];
      _subjectScores = grades.map((g) => {
        'subject': g['subject'] ?? '',
        'mark': g['mark'] ?? 0,
      }).toList();
    } else {
      _remarksController = TextEditingController();
      _subjectScores = [
        {'subject': 'Arabic Grammar', 'mark': 85},
        {'subject': 'Quran Hifz', 'mark': 90},
        {'subject': 'Fiqh', 'mark': 75},
      ];
    }

    _loadStudents();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      final list = await ref.read(studentRepositoryProvider).getStudents();
      setState(() {
        _allStudents = list;
        _isLoadingStudents = false;

        if (widget.existingReport != null) {
          final studentData = widget.existingReport!['studentId'];
          final idToMatch = studentData is Map ? studentData['_id'] : studentData;
          try {
            _selectedStudent = list.firstWhere((s) => s.id == idToMatch);
            _selectedClass = _selectedStudent?.classroom;
          } catch (_) {
            // Not found
          }
        }
      });
    } catch (e) {
      setState(() => _isLoadingStudents = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load students: ${friendlyErrorMessage(e)}')),
        );
      }
    }
  }

  void _addSubjectRow([String subjectName = '']) {
    setState(() {
      _subjectScores.add({'subject': subjectName, 'mark': 80});
    });
  }

  void _removeSubjectRow(int index) {
    setState(() {
      _subjectScores.removeAt(index);
    });
  }

  double _calculateAverage() {
    if (_subjectScores.isEmpty) return 0.0;
    double total = 0;
    for (var item in _subjectScores) {
      total += (item['mark'] as num);
    }
    return total / _subjectScores.length;
  }

  String _calculateStatus() {
    if (_subjectScores.isEmpty) return 'Passed';
    return _calculateAverage() >= 50 ? 'Passed' : 'Failed';
  }

  String _resolveGrade(num mark) {
    if (mark >= 85) return 'A';
    if (mark >= 75) return 'B';
    if (mark >= 60) return 'C';
    if (mark >= 50) return 'D';
    return 'F';
  }

  Future<void> _submitReport() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student first')),
      );
      return;
    }

    if (_subjectScores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one subject score')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final dio = ref.read(dioProvider);
    final evaluationStatus = _calculateStatus();

    final formattedGrades = _subjectScores.map((g) {
      final mark = g['mark'] as num;
      return {
        'subject': g['subject'],
        'mark': mark,
        'grade': _resolveGrade(mark),
      };
    }).toList();

    try {
      await dio.post('/progress-reports', data: {
        'studentId': _selectedStudent!.id,
        'term': _selectedTerm,
        'grades': formattedGrades,
        'remarks': _remarksController.text.trim(),
        'evaluationStatus': evaluationStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Academic progress report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: ${friendlyErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final instituteId = ref.watch(selectedInstituteProvider).id;
    ref.listen(evaluationTermsProvider(instituteId), (prev, next) {
      next.whenData((terms) {
        if (terms.isNotEmpty && !listEquals(terms, _terms)) {
          setState(() {
            _terms = List<String>.from(terms);
            _selectedTerm = _normalizeTerm(_selectedTerm);
          });
        }
      });
    });

    // Extract all distinct classes
    final classes = _allStudents
        .map((s) => s.classroom.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // Filter students by selected class
    final filteredStudents = _selectedClass == null
        ? _allStudents
        : _allStudents.where((s) => s.classroom.trim() == _selectedClass).toList();

    final avgScore = _calculateAverage();
    final overallStatus = _calculateStatus();
    final isPassed = overallStatus == 'Passed';

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: widget.existingReport != null ? 'Edit Academic Progress' : 'Academic Progress',
            subtitle: 'Record marks, grades, and behavioral remarks for students',
          ),
          Expanded(
            child: _isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── STEP 1: CLASSROOM SELECTION ──────────────────────────────
                          _buildSectionHeader(
                            stepNumber: '1',
                            title: 'Select Class / Grade',
                            subtitle: 'Filter students by their enrolled madrasa class',
                          ),
                          const Gap(10),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String?>(
                                        initialValue: _selectedClass,
                                        decoration: InputDecoration(
                                          labelText: 'Target Class',
                                          prefixIcon: const Icon(LucideIcons.graduationCap, size: 18),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        ),
                                        items: [
                                          const DropdownMenuItem(value: null, child: Text('All Classes (Show All Students)')),
                                          ...classes.map((c) {
                                            final count = _allStudents.where((s) => s.classroom.trim() == c).length;
                                            return DropdownMenuItem(
                                              value: c,
                                              child: Text('$c ($count students)'),
                                            );
                                          }),
                                        ],
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedClass = val;
                                            // Reset selected student if they aren't in this class
                                            if (_selectedStudent != null && val != null && _selectedStudent!.classroom.trim() != val) {
                                              _selectedStudent = null;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    if (_selectedClass != null) ...[
                                      const Gap(10),
                                      OutlinedButton.icon(
                                        onPressed: () => setState(() {
                                          _selectedClass = null;
                                        }),
                                        icon: const Icon(LucideIcons.x, size: 14),
                                        label: const Text('Clear'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (classes.isNotEmpty) ...[
                                  const Gap(10),
                                  const Text('Quick Class Selection:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const Gap(6),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: classes.map((c) {
                                        final isSel = _selectedClass == c;
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: ChoiceChip(
                                            label: Text(c, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                                            selected: isSel,
                                            selectedColor: _madrasaGreen,
                                            backgroundColor: const Color(0xFFF1F5F9),
                                            onSelected: (_) {
                                              setState(() {
                                                _selectedClass = isSel ? null : c;
                                                if (_selectedStudent != null && _selectedClass != null && _selectedStudent!.classroom.trim() != _selectedClass) {
                                                  _selectedStudent = null;
                                                }
                                              });
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const Gap(24),

                          // ── STEP 2: STUDENT SELECTION ────────────────────────────────
                          _buildSectionHeader(
                            stepNumber: '2',
                            title: 'Select Student',
                            subtitle: _selectedClass != null
                                ? 'Showing students in class $_selectedClass (${filteredStudents.length} enrolled)'
                                : 'Choose a student (${_allStudents.length} total students enrolled)',
                          ),
                          const Gap(10),

                          if (_selectedStudent == null)
                            _buildStudentPickerBox(context, filteredStudents)
                          else
                            _buildSelectedStudentCard(context),

                          const Gap(24),

                          // ── STEP 3: EVALUATION TERM ──────────────────────────────────
                          _buildSectionHeader(
                            stepNumber: '3',
                            title: 'Evaluation Term',
                            subtitle: 'Select the academic exam or grading period',
                          ),
                          const Gap(10),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.border),
                            ),
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('${_terms.join('|')}::$_selectedTerm'),
                              initialValue: _selectedTerm,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(LucideIcons.calendar, size: 18),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              items: _terms.map((term) => DropdownMenuItem(value: term, child: Text(term, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedTerm = val);
                              },
                            ),
                          ),

                          const Gap(24),

                          // ── STEP 4: SUBJECT SCORES ───────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildSectionHeader(
                                  stepNumber: '4',
                                  title: 'Subject Scores & Marks',
                                  subtitle: 'Enter marks (0-100) for each evaluated subject',
                                ),
                              ),
                              const Gap(10),
                              FilledButton.icon(
                                onPressed: () => _addSubjectRow(),
                                icon: const Icon(LucideIcons.plus, size: 15),
                                label: const Text('Add Subject'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _madrasaGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                          const Gap(10),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Common subject chips
                                Row(
                                  children: [
                                    const Icon(LucideIcons.sparkles, size: 14, color: _madrasaGold),
                                    const Gap(6),
                                    const Text('Quick Add Subjects:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  ],
                                ),
                                const Gap(6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _commonSubjects.map((s) {
                                    final alreadyAdded = _subjectScores.any((item) => (item['subject'] as String).toLowerCase() == s.toLowerCase());
                                    return ActionChip(
                                      avatar: Icon(alreadyAdded ? LucideIcons.check : LucideIcons.plus, size: 13, color: alreadyAdded ? Colors.green : Colors.grey[700]),
                                      label: Text(s, style: TextStyle(fontSize: 11, color: alreadyAdded ? Colors.grey : Colors.black87)),
                                      onPressed: alreadyAdded ? null : () => _addSubjectRow(s),
                                      backgroundColor: const Color(0xFFF8FAFC),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    );
                                  }).toList(),
                                ),

                                const Gap(14),
                                const Divider(height: 1),
                                const Gap(14),

                                // Subject rows
                                for (int i = 0; i < _subjectScores.length; i++) ...[
                                  _buildSubjectScoreRow(context, i),
                                  if (i < _subjectScores.length - 1) const Gap(10),
                                ],
                              ],
                            ),
                          ),

                          const Gap(24),

                          // ── STEP 5: TEACHER REMARKS ──────────────────────────────────
                          _buildSectionHeader(
                            stepNumber: '5',
                            title: 'Teacher Remarks & Feedback',
                            subtitle: 'Provide constructive behavioral and academic feedback',
                          ),
                          const Gap(10),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _remarksController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Add behavioral observations, strengths, or areas for improvement...',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: colors.border),
                                    ),
                                    contentPadding: const EdgeInsets.all(14),
                                  ),
                                ),
                                const Gap(10),
                                const Text('Quick Feedback Suggestions:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const Gap(6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _remarkPresets.map((preset) {
                                    return ActionChip(
                                      label: Text(preset, style: const TextStyle(fontSize: 11)),
                                      onPressed: () {
                                        final current = _remarksController.text.trim();
                                        if (current.isEmpty) {
                                          _remarksController.text = preset;
                                        } else if (!current.contains(preset)) {
                                          _remarksController.text = '$current. $preset';
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          const Gap(24),

                          // ── LIVE EVALUATION SUMMARY BANNER ───────────────────────────
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isPassed ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isPassed ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isPassed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPassed ? LucideIcons.award : LucideIcons.alertTriangle,
                                    color: isPassed ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                    size: 24,
                                  ),
                                ),
                                const Gap(14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Overall Result: $overallStatus (${avgScore.toStringAsFixed(1)}%)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isPassed ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                        ),
                                      ),
                                      const Gap(2),
                                      Text(
                                        '${_subjectScores.length} subjects evaluated · Minimum passing grade is 50%',
                                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isPassed ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _resolveGrade(avgScore),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Gap(28),

                          // ── SUBMIT BUTTON ────────────────────────────────────────────
                          ABMButton(
                            text: widget.existingReport != null ? 'Save Changes' : 'Submit Progress Report',
                            isLoading: _isSaving,
                            onPressed: _isSaving ? null : _submitReport,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String stepNumber,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: _madrasaGreen.withValues(alpha: 0.12),
          child: Text(stepNumber, style: const TextStyle(color: _madrasaGreen, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
        const Gap(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentPickerBox(BuildContext context, List<StudentModel> students) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.userCheck, size: 18, color: _madrasaGreen),
              const Gap(8),
              Expanded(
                child: Text(
                  'Choose Student (${students.length} available)',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Gap(8),
              FilledButton.tonalIcon(
                onPressed: () => _openStudentSearchDialog(context, students),
                icon: const Icon(LucideIcons.search, size: 14),
                label: const Text('Search & Select', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const Gap(10),
          DropdownButtonFormField<StudentModel?>(
            initialValue: _selectedStudent,
            hint: Text(students.isEmpty ? 'No students found in this class' : 'Choose a student from dropdown...'),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: students.map((s) {
              return DropdownMenuItem<StudentModel?>(
                value: s,
                child: Text('${s.fullName} · Adm: ${s.admissionNumber} (${s.classroom})', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _selectedStudent = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedStudentCard(BuildContext context) {
    final s = _selectedStudent!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _madrasaGreen.withValues(alpha: 0.15),
            child: Text(
              s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S',
              style: const TextStyle(color: _madrasaGreen, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Gap(3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Text('Class: ${s.classroom}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _madrasaGreen)),
                    ),
                    const Gap(8),
                    Text('Admission No: ${s.admissionNumber}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _selectedStudent = null);
            },
            icon: const Icon(LucideIcons.repeat, size: 14),
            label: const Text('Change', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectScoreRow(BuildContext context, int index) {
    final score = _subjectScores[index];
    final mark = (score['mark'] as num?) ?? 0;
    final grade = _resolveGrade(mark);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Subject Name
          Expanded(
            flex: 4,
            child: TextFormField(
              initialValue: score['subject'],
              decoration: const InputDecoration(
                hintText: 'Subject Name (e.g. Quran)',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              onChanged: (val) {
                score['subject'] = val.trim();
              },
            ),
          ),
          const Gap(10),
          // Mark input
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: score['mark'].toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Mark',
                suffixText: '/100',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                final numVal = num.tryParse(val);
                if (numVal == null || numVal < 0 || numVal > 100) return '0-100';
                return null;
              },
              onChanged: (val) {
                score['mark'] = num.tryParse(val) ?? 0;
                setState(() {}); // update grade badge live
              },
            ),
          ),
          const Gap(10),
          // Grade badge
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mark >= 50 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              grade,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: mark >= 50 ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
              ),
            ),
          ),
          const Gap(6),
          // Trash icon
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
            tooltip: 'Remove subject',
            onPressed: () => _removeSubjectRow(index),
          ),
        ],
      ),
    );
  }

  void _openStudentSearchDialog(BuildContext context, List<StudentModel> students) {
    String search = '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dialogFiltered = students.where((s) {
            return search.isEmpty ||
                s.fullName.toLowerCase().contains(search.toLowerCase()) ||
                s.admissionNumber.toLowerCase().contains(search.toLowerCase()) ||
                s.classroom.toLowerCase().contains(search.toLowerCase());
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(LucideIcons.search, color: _madrasaGreen),
                const Gap(10),
                const Text('Search Student'),
              ],
            ),
            content: SizedBox(
              width: 440,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    onChanged: (val) => setDialogState(() => search = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Type student name or admission number...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const Gap(10),
                  Text('Showing ${dialogFiltered.length} students', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const Gap(8),
                  Expanded(
                    child: dialogFiltered.isEmpty
                        ? const Center(child: Text('No students match your search'))
                        : ListView.separated(
                            itemCount: dialogFiltered.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final st = dialogFiltered[idx];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _madrasaGreen.withValues(alpha: 0.12),
                                  child: Text(st.fullName.isNotEmpty ? st.fullName[0] : 'S', style: const TextStyle(color: _madrasaGreen)),
                                ),
                                title: Text(st.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                subtitle: Text('Adm: ${st.admissionNumber} · Class: ${st.classroom}', style: const TextStyle(fontSize: 11)),
                                trailing: const Icon(LucideIcons.chevronRight, size: 16),
                                onTap: () {
                                  setState(() {
                                    _selectedStudent = st;
                                    _selectedClass = st.classroom;
                                  });
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ],
          );
        },
      ),
    );
  }
}
