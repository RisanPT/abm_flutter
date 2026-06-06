import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/features/students/presentation/student_controller.dart';
import 'package:abm_madrasa/features/students/presentation/widgets/student_form_widgets.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_date_picker_field.dart';
import 'package:abm_madrasa/shared/widgets/abm_dropdown_field.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  final StudentModel? existingStudent;
  const AddStudentScreen({super.key, this.existingStudent});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEdit;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _admissionController;
  late TextEditingController _guardianNameController;
  late TextEditingController _guardianContactController;
  late TextEditingController _addressController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _parentPassportController;
  late TextEditingController _parentIqamaController;
  late TextEditingController _transportFeeController;

  // State
  DateTime _dob = DateTime(2015);
  Gender _gender = Gender.male;
  String? _selectedClass;
  Uint8List? _pickedImageBytes;
  String? _photoUrl;
  bool _isSaving = false;
  bool _needsTransportation = false;
  String _selectedInstituteId = 'abm-offline-1';
  bool _showConcessionBanner = false;
  int _siblingCount = 0;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.existingStudent != null;
    final s = widget.existingStudent;

    _nameController = TextEditingController(text: s?.fullName ?? '');
    _admissionController = TextEditingController(text: s?.admissionNumber ?? '');
    _guardianNameController = TextEditingController(text: s?.guardianName ?? '');
    _guardianContactController = TextEditingController(text: s?.guardianContact ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _bloodGroupController = TextEditingController(text: s?.bloodGroup ?? '');
    _parentPassportController = TextEditingController(text: s?.parentPassportId ?? '');
    _parentIqamaController = TextEditingController(text: s?.parentIqamaId ?? '');
    _transportFeeController = TextEditingController(text: s?.transportationFee.toString() ?? '0');
    _needsTransportation = s?.needsTransportation ?? false;

    if (s != null) {
      _dob = s.dateOfBirth;
      _gender = s.gender;
      _selectedClass = s.classroom;
      _photoUrl = s.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _admissionController.dispose();
    _guardianNameController.dispose();
    _guardianContactController.dispose();
    _addressController.dispose();
    _bloodGroupController.dispose();
    _parentPassportController.dispose();
    _parentIqamaController.dispose();
    _transportFeeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _pickedImageBytes = bytes);
    }
  }

  Future<void> _checkConcession(String value) async {
    final familyId = _parentPassportController.text.trim().isNotEmpty
        ? _parentPassportController.text.trim()
        : _parentIqamaController.text.trim();
    if (familyId.length < 4) {
      setState(() { _showConcessionBanner = false; _siblingCount = 0; });
      return;
    }
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/students/siblings-count/$familyId');
      final count = (response.data['count'] as int?) ?? 0;
      if (mounted) {
        setState(() {
          _siblingCount = count;
          _showConcessionBanner = count >= 2;
        });
      }
    } catch (_) {}
  }


  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a classroom')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? finalPhotoUrl = _photoUrl;
      if (_pickedImageBytes != null) {
        finalPhotoUrl = await ref.read(studentRepositoryProvider).uploadStudentImage(
          bytes: _pickedImageBytes!,
          fileName: _nameController.text.trim(),
        );
      }

      final student = StudentModel(
        id: widget.existingStudent?.id ?? '',
        fullName: _nameController.text.trim(),
        admissionNumber: _admissionController.text.trim(),
        dateOfBirth: _dob,
        gender: _gender,
        classroom: _selectedClass!,
        guardianName: _guardianNameController.text.trim(),
        guardianContact: _guardianContactController.text.trim(),
        address: _addressController.text.trim(),
        bloodGroup: _bloodGroupController.text.trim(),
        parentPassportId: _parentPassportController.text.trim(),
        parentIqamaId: _parentIqamaController.text.trim(),
        needsTransportation: _needsTransportation,
        transportationFee: double.tryParse(_transportFeeController.text.trim()) ?? 0,
        photoUrl: finalPhotoUrl,
        instituteId: _selectedInstituteId,
        admissionDate: widget.existingStudent?.admissionDate ?? DateTime.now(),
      );

      if (_isEdit) {
        await ref.read(studentControllerProvider.notifier).updateStudent(student);
      } else {
        await ref.read(studentControllerProvider.notifier).addStudent(student);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Student updated successfully' : 'Student enrolled successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ABMPageHeader(
              title: _isEdit ? 'Edit Student' : 'New Enrollment',
              subtitle: _isEdit ? 'Updating records for ${_nameController.text}' : 'Complete the form to register a new student',
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 960),
                  padding: EdgeInsets.all(context.isMobile ? 20 : 32),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Student Photo'),
                        const Gap(20),
                        PhotoPickerCard(imageBytes: _pickedImageBytes, photoUrl: _photoUrl, studentName: _nameController.text, onPick: _pickImage),
                        const Gap(32),
                        const SectionHeader(title: 'Basic Information'),
                        const Gap(24),
                        _ResponsiveRow([
                          ABMTextField(label: 'Full Name', hint: 'Enter full name', controller: _nameController, onChanged: (_) => setState(() {}), validator: (v) => v?.isEmpty == true ? 'Required' : null),
                          ABMTextField(label: 'Admission Number', hint: 'ABM/000', controller: _admissionController, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                        ]),
                        const Gap(24),
                        _ResponsiveRow([
                          ABMDropdownField<Gender>(
                            label: 'Gender',
                            value: _gender,
                            items: Gender.values,
                            labelMapper: (g) => g.name.toUpperCase(),
                            onChanged: (v) => setState(() => _gender = v!),
                          ),
                          ABMDatePickerField(label: 'Date of Birth', date: _dob, onTap: () async {
                            final picked = await showDatePicker(context: context, initialDate: _dob, firstDate: DateTime(2000), lastDate: DateTime.now());
                            if (picked != null) setState(() => _dob = picked);
                          }),
                        ]),
                        const Gap(24),
                        _ResponsiveRow([
                          _buildClassroomDropdown(),
                          ABMTextField(label: 'Blood Group', hint: 'e.g. O+', controller: _bloodGroupController),
                        ]),
                        const Gap(32),
                        const SectionHeader(title: 'Guardian & Contact'),
                        const Gap(24),
                        _ResponsiveRow([
                          ABMTextField(label: 'Guardian Name', hint: "Father/Mother's name", controller: _guardianNameController, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                          ABMTextField(label: 'Contact Number', hint: '+91 XXXXX XXXXX', controller: _guardianContactController, keyboardType: TextInputType.phone, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                        ]),
                        const Gap(24),
                        ABMTextField(label: 'Full Address', hint: 'Residential address', controller: _addressController, maxLines: 3, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                        const Gap(32),
                        const SectionHeader(title: 'Parent IDs & Transportation'),
                        const Gap(24),
                        _ResponsiveRow([
                          ABMTextField(
                            label: 'Parent Passport ID',
                            hint: 'Enter passport number',
                            controller: _parentPassportController,
                            onChanged: _checkConcession,
                          ),
                          ABMTextField(
                            label: 'Parent Iqama ID',
                            hint: 'Enter iqama number',
                            controller: _parentIqamaController,
                            onChanged: _checkConcession,
                          ),
                        ]),
                        if (_showConcessionBanner) ...[  
                          const Gap(12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.badgeCheck, color: Colors.green, size: 20),
                                const Gap(12),
                                Expanded(
                                  child: Text(
                                    'Family fee concession will be automatically applied — $_siblingCount sibling(s) already enrolled from the same family.',
                                    style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Gap(24),
                        _buildInstituteDropdown(),
                        const Gap(24),
                        SwitchListTile(
                          title: const Text('Needs Transportation', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Does this student require madrasa transport?'),
                          value: _needsTransportation,
                          activeThumbColor: colors.primary,
                          onChanged: (v) => setState(() => _needsTransportation = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_needsTransportation) ...[
                          const Gap(16),
                          ABMTextField(
                            label: 'Monthly Transportation Fee',
                            hint: 'Enter amount',
                            controller: _transportFeeController,
                            keyboardType: TextInputType.number,
                            prefixIcon:  LucideIcons.banknote,
                          ),
                        ],
                        const Gap(40),
                        ABMButton(text: _isEdit ? 'Update Student Record' : 'Enroll Student', onPressed: _isSaving ? null : () => _save(), isLoading: _isSaving),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomDropdown() {
    return Consumer(builder: (context, ref, _) {
      final classroomsAsync = ref.watch(classroomControllerProvider);
      return classroomsAsync.when(
        data: (classes) {
          final classNames = classes.map((c) => c.name).toList();
          final dropdownItems = classNames.isEmpty ? ['No classes available'] : classNames;
          if (_selectedClass == null && classNames.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedClass = classNames.first);
            });
          }
          String effectiveValue = classNames.contains(_selectedClass) ? _selectedClass! : (classNames.isNotEmpty ? classNames.first : 'No classes available');
          
          return ABMDropdownField<String>(
            label: 'Classroom',
            value: effectiveValue,
            items: dropdownItems,
            onChanged: (v) { 
              if (v != 'No classes available') {
                setState(() => _selectedClass = v!);
              }
            },
            trailing: Material(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              child: IconButton(
                icon: const Icon(Icons.add, size: 24),
                onPressed: () => _showAddClassDialog(context),
                color: context.colors.primary,
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Text('Error loading classes'),
      );
    });
  }

  Future<void> _showAddClassDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Add New Class'),
      content: TextField(controller: nameController, decoration: const InputDecoration(hintText: 'e.g. Grade 1A'), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
      ],
    ));
    if (result == true && nameController.text.isNotEmpty) {
      await ref.read(classroomControllerProvider.notifier).addClassroom(nameController.text.trim());
    }
  }

  Widget _buildInstituteDropdown() {
    return ABMDropdownField<String>(
      label: 'Institute',
      value: _selectedInstituteId,
      items: const ['abm-offline-1', 'abm-offline-2', 'abm-online'],
      labelMapper: (id) => id == 'abm-offline-1' ? 'Institute 1 (Offline)' : (id == 'abm-offline-2' ? 'Institute 2 (Offline)' : 'Online Madrasa'),
      onChanged: (v) => setState(() => _selectedInstituteId = v!),
    );
  }
}

class _ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  const _ResponsiveRow(this.children);
  @override
  Widget build(BuildContext context) {
    if (context.isMobile) return Column(children: [children[0], const Gap(24), children[1]]);
    return Row(children: [Expanded(child: children[0]), const Gap(24), Expanded(child: children[1])]);
  }
}
