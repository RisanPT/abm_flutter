import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/class_sort.dart';
import 'package:abm_madrasa/features/books/domain/book_model.dart';
import 'package:abm_madrasa/features/books/presentation/book_controller.dart';
import 'package:abm_madrasa/features/students/domain/classroom_model.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BookFormDialog extends ConsumerStatefulWidget {
  const BookFormDialog({
    super.key,
    this.initialBook,
    this.defaultClassroomId,
    this.defaultClassName,
  });

  final BookModel? initialBook;
  final String? defaultClassroomId;
  final String? defaultClassName;

  @override
  ConsumerState<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends ConsumerState<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _codeController;
  late final TextEditingController _isbnController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _authorController;
  late final TextEditingController _publisherController;
  late final TextEditingController _editionController;
  late final TextEditingController _descriptionController;

  String? _selectedClassroomId;
  String _selectedGrade = 'All';
  String _selectedSubject = 'General';
  bool _isSaving = false;

  static const List<String> _defaultSubjects = [
    'General',
    'Quran',
    'Tajweed',
    'Hadith',
    'Fiqh',
    'Aqeedah',
    'Seerah',
    'Arabic',
    'Islamic Studies',
    'Urdu',
    'English',
    'Mathematics',
    'Science',
    'Moral Science',
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.initialBook;
    _titleController = TextEditingController(text: b?.title ?? '');
    _codeController = TextEditingController(text: b?.bookCode ?? '');
    _isbnController = TextEditingController(text: b?.isbn ?? '');
    _priceController = TextEditingController(text: b != null ? b.price.toStringAsFixed(2) : '0.00');
    _stockController = TextEditingController(text: b != null ? b.stockQuantity.toString() : '10');
    _authorController = TextEditingController(text: b?.author ?? '');
    _publisherController = TextEditingController(text: b?.publisher ?? '');
    _editionController = TextEditingController(text: b?.edition ?? '');
    _descriptionController = TextEditingController(text: b?.description ?? '');

    _selectedClassroomId = b?.classroomId ?? widget.defaultClassroomId;
    _selectedGrade = b?.grade ?? widget.defaultClassName ?? 'All';

    if (b != null && b.subject.isNotEmpty) {
      _selectedSubject = b.subject;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _isbnController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _editionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    final data = {
      'title': _titleController.text.trim(),
      'bookCode': _codeController.text.trim(),
      'isbn': _isbnController.text.trim(),
      'subject': _selectedSubject,
      'classroomId': _selectedClassroomId,
      'grade': _selectedGrade,
      'price': price,
      'stockQuantity': stock,
      'author': _authorController.text.trim(),
      'publisher': _publisherController.text.trim(),
      'edition': _editionController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    final isEdit = widget.initialBook != null;
    final success = isEdit
        ? await ref.read(bookControllerProvider.notifier).updateBook(widget.initialBook!.id, data)
        : await ref.read(bookControllerProvider.notifier).addBook(data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Book updated successfully' : 'Book added successfully'),
          backgroundColor: const Color(0xFF0F4A3A),
        ),
      );
    } else {
      final err = ref.read(bookControllerProvider).errorMessage ?? 'Operation failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isEdit = widget.initialBook != null;

    final classroomsAsync = ref.watch(classroomControllerProvider);
    final List<ClassroomModel> classrooms = classroomsAsync.value ?? [];
    final sortedClassrooms = sortByClassName<ClassroomModel>(classrooms, (c) => c.name);

    // Build subject choices incorporating subjects configured for this classroom
    final Set<String> subjectSet = {..._defaultSubjects};
    if (_selectedClassroomId != null) {
      final matchedClass = classrooms.where((c) => c.id == _selectedClassroomId).firstOrNull;
      if (matchedClass != null) {
        subjectSet.addAll(matchedClass.subjects);
      }
    }
    final List<String> availableSubjects = subjectSet.toList();
    if (!availableSubjects.contains(_selectedSubject)) {
      availableSubjects.add(_selectedSubject);
    }

    return Dialog(
      backgroundColor: colors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F4A3A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEdit ? LucideIcons.edit3 : LucideIcons.bookPlus,
                        color: const Color(0xFF0F4A3A),
                        size: 24,
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isEdit ? 'Edit Book Record' : 'Add Book to Class Curriculum', style: typography.h4),
                          const Gap(2),
                          Text(
                            'Link book directly with madrasa classes, set price and manage stock',
                            style: typography.bodySmall.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Gap(16),
                Divider(height: 1, color: colors.border),
                const Gap(16),

                // Form Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Book Title *',
                            hintText: 'e.g. Noorani Qaida, Fiqh Al-Muyassar Part 1',
                            prefixIcon: Icon(LucideIcons.book),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter book title' : null,
                        ),
                        const Gap(14),

                        // Class / Grade Linkage & Code
                        Row(
                          children: [
                            // Class Linkage Dropdown
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedGrade,
                                decoration: const InputDecoration(
                                  labelText: 'Linked Class *',
                                  prefixIcon: Icon(LucideIcons.graduationCap),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'All',
                                    child: Text('All Classes (General / Library)'),
                                  ),
                                  ...sortedClassrooms.map((c) => DropdownMenuItem(
                                        value: c.name,
                                        child: Text('${c.name} (${c.shift})'),
                                      )),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _selectedGrade = v;
                                      if (v == 'All') {
                                        _selectedClassroomId = null;
                                      } else {
                                        final matched = sortedClassrooms.where((c) => c.name == v).firstOrNull;
                                        _selectedClassroomId = matched?.id;
                                        if (matched != null && matched.subjects.isNotEmpty) {
                                          if (!matched.subjects.contains(_selectedSubject)) {
                                            _selectedSubject = matched.subjects.first;
                                          }
                                        }
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                            const Gap(14),
                            // Book Code
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _codeController,
                                decoration: const InputDecoration(
                                  labelText: 'Book Code / SKU',
                                  hintText: 'e.g. BK-101',
                                  prefixIcon: Icon(LucideIcons.tag),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(14),

                        // Subject & ISBN
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                key: ValueKey('subject_${_selectedGrade}_$_selectedSubject'),
                                initialValue: _selectedSubject,
                                decoration: const InputDecoration(
                                  labelText: 'Subject / Category',
                                  prefixIcon: Icon(LucideIcons.folder),
                                ),
                                items: availableSubjects
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _selectedSubject = v);
                                },
                              ),
                            ),
                            const Gap(14),
                            Expanded(
                              child: TextFormField(
                                controller: _isbnController,
                                decoration: const InputDecoration(
                                  labelText: 'ISBN / Barcode',
                                  hintText: 'Optional ISBN',
                                  prefixIcon: Icon(LucideIcons.hash),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(14),

                        // Price & Stock
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Price (SAR) *',
                                  hintText: '0.00',
                                  prefixIcon: Icon(LucideIcons.tag),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Price is required';
                                  final num = double.tryParse(v.trim());
                                  if (num == null || num < 0) return 'Invalid price';
                                  return null;
                                },
                              ),
                            ),
                            const Gap(14),
                            Expanded(
                              child: TextFormField(
                                controller: _stockController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Stock Quantity *',
                                  hintText: 'e.g. 50',
                                  prefixIcon: Icon(LucideIcons.boxes),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Stock is required';
                                  final num = int.tryParse(v.trim());
                                  if (num == null || num < 0) return 'Invalid quantity';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const Gap(14),

                        // Author & Publisher
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _authorController,
                                decoration: const InputDecoration(
                                  labelText: 'Author / Compiler',
                                  hintText: 'e.g. Sheikh Noor',
                                  prefixIcon: Icon(LucideIcons.user),
                                ),
                              ),
                            ),
                            const Gap(14),
                            Expanded(
                              child: TextFormField(
                                controller: _publisherController,
                                decoration: const InputDecoration(
                                  labelText: 'Publisher',
                                  hintText: 'e.g. Darul Kutub',
                                  prefixIcon: Icon(LucideIcons.building2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(14),

                        // Edition
                        TextFormField(
                          controller: _editionController,
                          decoration: const InputDecoration(
                            labelText: 'Edition / Year',
                            hintText: 'e.g. 3rd Edition, 2024',
                            prefixIcon: Icon(LucideIcons.bookmark),
                          ),
                        ),
                        const Gap(14),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description / Notes',
                            hintText: 'Curriculum syllabus details or usage guide',
                            prefixIcon: Icon(LucideIcons.fileText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Gap(16),
                Divider(height: 1, color: colors.border),
                const Gap(16),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const Gap(12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4A3A),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.check, size: 16),
                      label: Text(_isSaving ? 'Saving...' : (isEdit ? 'Save Changes' : 'Link Book to Class')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
