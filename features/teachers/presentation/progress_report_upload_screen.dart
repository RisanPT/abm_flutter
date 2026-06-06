import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProgressReportUploadScreen extends ConsumerStatefulWidget {
  const ProgressReportUploadScreen({super.key});

  @override
  ConsumerState<ProgressReportUploadScreen> createState() => _ProgressReportUploadScreenState();
}

class _ProgressReportUploadScreenState extends ConsumerState<ProgressReportUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  List<StudentModel> _students = [];
  StudentModel? _selectedStudent;
  bool _isLoadingStudents = false;

  String _selectedTerm = 'Term 1';
  final List<String> _terms = ['Term 1', 'Term 2', 'Final Term'];

  final List<Map<String, dynamic>> _subjectScores = [
    {'subject': 'Arabic Grammar', 'mark': 85},
    {'subject': 'Quran Hifz', 'mark': 90},
    {'subject': 'Fiqh', 'mark': 75},
  ];

  final _remarksController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
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
        _students = list;
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() => _isLoadingStudents = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load students: $e')),
        );
      }
    }
  }

  void _addSubjectRow() {
    setState(() {
      _subjectScores.add({'subject': '', 'mark': 0});
    });
  }

  void _removeSubjectRow(int index) {
    setState(() {
      _subjectScores.removeAt(index);
    });
  }

  String _calculateStatus() {
    if (_subjectScores.isEmpty) return 'Passed';
    double total = 0;
    for (var item in _subjectScores) {
      total += (item['mark'] as num);
    }
    double avg = total / _subjectScores.length;
    return avg >= 50 ? 'Passed' : 'Failed';
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
        const SnackBar(content: Text('Please select a student')),
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
        'remarks': _remarksController.text,
        'evaluationStatus': evaluationStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const ABMPageHeader(
            title: 'Academic Progress',
            subtitle: 'Upload marks, grades, and remarks',
          ),
          Expanded(
            child: _isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Student', style: typography.h4),
                          const Gap(8),
                          DropdownButtonFormField<StudentModel>(
                            initialValue: _selectedStudent,
                            hint: const Text('Choose Student'),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: colors.cardBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colors.border),
                              ),
                            ),
                            items: _students.map((student) {
                              return DropdownMenuItem<StudentModel>(
                                value: student,
                                child: Text('${student.fullName} (${student.admissionNumber})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedStudent = val);
                            },
                          ),
                          const Gap(24),
                          
                          Text('Evaluation Term', style: typography.h4),
                          const Gap(8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedTerm,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: colors.cardBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colors.border),
                              ),
                            ),
                            items: _terms.map((term) {
                              return DropdownMenuItem<String>(
                                value: term,
                                child: Text(term),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedTerm = val);
                              }
                            },
                          ),
                          const Gap(24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subject Scores', style: typography.h4),
                              TextButton.icon(
                                onPressed: _addSubjectRow,
                                icon: const Icon(LucideIcons.plus, size: 16),
                                label: const Text('Add Subject'),
                              ),
                            ],
                          ),
                          const Gap(8),
                          
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _subjectScores.length,
                            separatorBuilder: (_, index) => const Gap(12),
                            itemBuilder: (context, index) {
                              final score = _subjectScores[index];
                              return Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: score['subject'],
                                      decoration: InputDecoration(
                                        hintText: 'Subject',
                                        filled: true,
                                        fillColor: colors.cardBackground,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                                      onChanged: (val) {
                                        score['subject'] = val;
                                      },
                                    ),
                                  ),
                                  const Gap(10),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: score['mark'].toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'Mark',
                                        filled: true,
                                        fillColor: colors.cardBackground,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.isEmpty) return 'Required';
                                        final numVal = num.tryParse(val);
                                        if (numVal == null || numVal < 0 || numVal > 100) return '0-100';
                                        return null;
                                      },
                                      onChanged: (val) {
                                        score['mark'] = num.tryParse(val) ?? 0;
                                        setState(() {}); // Recalculate status live
                                      },
                                    ),
                                  ),
                                  const Gap(10),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, color: Colors.red),
                                    onPressed: () => _removeSubjectRow(index),
                                  ),
                                ],
                              );
                            },
                          ),
                          const Gap(24),

                          Text('Teacher Remarks', style: typography.h4),
                          const Gap(8),
                          TextFormField(
                            controller: _remarksController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add specific behavioral or academic performance feedback...',
                              filled: true,
                              fillColor: colors.cardBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colors.border),
                              ),
                            ),
                          ),
                          const Gap(24),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Evaluation Result Status:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _calculateStatus() == 'Passed'
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _calculateStatus() == 'Passed'
                                          ? Colors.green.shade200
                                          : Colors.red.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    _calculateStatus().toUpperCase(),
                                    style: TextStyle(
                                      color: _calculateStatus() == 'Passed'
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(32),

                          ABMButton(
                            text: 'Submit Evaluation',
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
}
