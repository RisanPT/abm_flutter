import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
import 'package:abm_madrasa/features/students/data/student_login_repository.dart';
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
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:intl_phone_field/countries.dart';
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
  late TextEditingController _addressController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _countryController;
  late TextEditingController _stateController;
  late TextEditingController _studentIqamaController;
  late TextEditingController _parentIqamaController;
  late TextEditingController _parentPassportController;
  late TextEditingController _fatherOccupationController;
  late TextEditingController _motherOccupationController;
  late TextEditingController _numberOfChildrenController;
  late TextEditingController _transportFeeController;
  late List<TextEditingController> _childrenAgeControllers;

  String _fullGuardianContact = '';
  String _fullFatherWhatsapp = '';
  String _fullMotherWhatsapp = '';

  String _guardianCountryCode = 'IN';
  String _guardianNationalNumber = '';
  String _fatherWhatsappCountryCode = 'IN';
  String _fatherWhatsappNationalNumber = '';
  String _motherWhatsappCountryCode = 'IN';
  String _motherWhatsappNationalNumber = '';

  // State
  DateTime _dob = DateTime(2015);
  Gender _gender = Gender.male;
  String? _selectedClass;
  Uint8List? _pickedImageBytes;
  String? _photoUrl;
  Uint8List? _studentIqamaImageBytes;
  String? _studentIqamaUrl;
  String _shift = 'Shift-1';
  DateTime _admissionDate = DateTime.now();
  bool _isSaving = false;
  bool _needsTransportation = false;
  String _selectedInstituteId = '664c39f00000000000000001';
  bool _isAdmin = false;
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
    _addressController = TextEditingController(text: s?.address ?? '');
    _bloodGroupController = TextEditingController(text: s?.bloodGroup ?? '');
    _parentIqamaController = TextEditingController(text: s?.parentIqamaId ?? '');
    _parentPassportController = TextEditingController(text: s?.parentPassportId ?? '');
    
    _fullGuardianContact = s?.guardianContact ?? '';
    _fullFatherWhatsapp = s?.fatherWhatsapp ?? '';
    _fullMotherWhatsapp = s?.motherWhatsapp ?? '';

    void parsePhone(String fullPhone, void Function(String, String) onParsed) {
      if (fullPhone.isNotEmpty && fullPhone.startsWith('+')) {
        try {
          final phone = PhoneNumber.fromCompleteNumber(completeNumber: fullPhone);
          onParsed(phone.countryISOCode, phone.number);
        } catch (_) {
          onParsed('IN', fullPhone);
        }
      } else {
        onParsed('IN', fullPhone);
      }
    }

    parsePhone(_fullGuardianContact, (c, n) {
      _guardianCountryCode = c;
      _guardianNationalNumber = n;
    });
    parsePhone(_fullFatherWhatsapp, (c, n) {
      _fatherWhatsappCountryCode = c;
      _fatherWhatsappNationalNumber = n;
    });
    parsePhone(_fullMotherWhatsapp, (c, n) {
      _motherWhatsappCountryCode = c;
      _motherWhatsappNationalNumber = n;
    });

    _countryController = TextEditingController(text: s?.country ?? 'India');
    _stateController = TextEditingController(text: s?.state ?? '');
    _studentIqamaController = TextEditingController(text: s?.studentIqamaNumber ?? '');
    _fatherOccupationController = TextEditingController(text: s?.fatherOccupation ?? '');
    _motherOccupationController = TextEditingController(text: s?.motherOccupation ?? '');
    _numberOfChildrenController = TextEditingController(text: s?.numberOfChildren.toString() ?? '0');
    _transportFeeController = TextEditingController(text: s?.transportationFee.toString() ?? '0');
    _needsTransportation = s?.needsTransportation ?? false;
    _shift = s?.shift ?? 'Shift-1';
    _admissionDate = s?.admissionDate ?? DateTime.now();
    _childrenAgeControllers = [];

    final childrenAges = s?.childrenAges ?? [];
    for (var age in childrenAges) {
      _childrenAgeControllers.add(TextEditingController(text: age));
    }

    // Resolve institute: non-admin roles are locked to their own institute.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).value;
      final selectedInstitute = ref.read(selectedInstituteProvider);
      final isAdmin = user?.role == AppRoles.itAdmin || user?.role == AppRoles.superAdmin;
      setState(() {
        _isAdmin = isAdmin;
        if (s != null) {
          _selectedInstituteId = s.instituteId;
        } else if (isAdmin) {
          _selectedInstituteId = selectedInstitute.id;
        } else {
          _selectedInstituteId = user?.instituteId ?? selectedInstitute.id;
        }
      });
    });

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
    _addressController.dispose();
    _bloodGroupController.dispose();
    _parentIqamaController.dispose();
    _parentPassportController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _studentIqamaController.dispose();
    _fatherOccupationController.dispose();
    _motherOccupationController.dispose();
    _numberOfChildrenController.dispose();
    _transportFeeController.dispose();
    for (var c in _childrenAgeControllers) {
      c.dispose();
    }
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

  Future<void> _pickIqamaImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _studentIqamaImageBytes = bytes);
    }
  }

  void _onNumberOfChildrenChanged(String value) {
    int count = int.tryParse(value) ?? 0;
    if (count < 0) count = 0;
    
    setState(() {
      if (count > _childrenAgeControllers.length) {
        for (int i = _childrenAgeControllers.length; i < count; i++) {
          _childrenAgeControllers.add(TextEditingController());
        }
      } else if (count < _childrenAgeControllers.length) {
        for (int i = _childrenAgeControllers.length - 1; i >= count; i--) {
          _childrenAgeControllers[i].dispose();
          _childrenAgeControllers.removeAt(i);
        }
      }
    });
  }

  Future<void> _checkConcession(String value) async {
    final familyId = _parentIqamaController.text.trim();
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

      String? finalIqamaUrl = _studentIqamaUrl;
      if (_studentIqamaImageBytes != null) {
        finalIqamaUrl = await ref.read(studentRepositoryProvider).uploadStudentImage(
          bytes: _studentIqamaImageBytes!,
          fileName: '${_nameController.text.trim()}_iqama',
        );
      }

      final student = StudentModel(
        id: widget.existingStudent?.id ?? '',
        fullName: _nameController.text.trim(),
        admissionNumber: _isEdit ? _admissionController.text.trim() : '',
        dateOfBirth: _dob,
        gender: _gender,
        classroom: _selectedClass!,
        guardianName: _guardianNameController.text.trim(),
        guardianContact: _fullGuardianContact,
        address: _addressController.text.trim(),
        bloodGroup: _bloodGroupController.text.trim(),
        parentIqamaId: _parentIqamaController.text.trim(),
        parentPassportId: _parentPassportController.text.trim(),
        fatherWhatsapp: _fullFatherWhatsapp,
        motherWhatsapp: _fullMotherWhatsapp,
        country: _countryController.text.trim().isEmpty ? 'India' : _countryController.text.trim(),
        state: _stateController.text.trim(),
        studentIqamaNumber: _studentIqamaController.text.trim(),
        studentIqamaUrl: finalIqamaUrl,
        fatherOccupation: _fatherOccupationController.text.trim(),
        motherOccupation: _motherOccupationController.text.trim(),
        numberOfChildren: int.tryParse(_numberOfChildrenController.text.trim()) ?? 0,
        childrenAges: _childrenAgeControllers.map((c) => c.text.trim()).toList(),
        shift: _shift,
        needsTransportation: _needsTransportation,
        transportationFee: double.tryParse(_transportFeeController.text.trim()) ?? 0,
        photoUrl: finalPhotoUrl,
        instituteId: _selectedInstituteId,
        admissionDate: _admissionDate,
      );

      if (_isEdit) {
        await ref.read(studentControllerProvider.notifier).updateStudent(student);
      } else {
        await ref.read(studentControllerProvider.notifier).addStudent(student);
      }

      if (ref.read(studentControllerProvider).hasError) {
        throw ref.read(studentControllerProvider).error ?? Exception('Failed to save student');
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
              padding: EdgeInsets.all(context.isMobile ? 12 : 24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 960),
                  padding: EdgeInsets.all(context.isMobile ? 16 : 32),
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
                        if (_isEdit)
                          _ResponsiveRow([
                            ABMTextField(label: 'Full Name', hint: 'Enter full name', controller: _nameController, onChanged: (_) => setState(() {}), validator: (v) => v?.isEmpty == true ? 'Required' : null),
                            ABMTextField(label: 'Admission Number', hint: 'Auto-generated', controller: _admissionController, enabled: false),
                          ])
                        else
                          _ResponsiveRow([
                            ABMTextField(label: 'Full Name', hint: 'Enter full name', controller: _nameController, onChanged: (_) => setState(() {}), validator: (v) => v?.isEmpty == true ? 'Required' : null),
                            ABMTextField(label: 'Admission Number', hint: 'Auto-generated', controller: _admissionController, enabled: false),
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
                          IntlPhoneField(
                            initialCountryCode: _guardianCountryCode,
                            initialValue: _guardianNationalNumber,
                            decoration: InputDecoration(
                              labelText: 'Guardian Contact',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (phone) {
                              _fullGuardianContact = phone.number.isEmpty ? '' : phone.completeNumber;
                            },
                          ),
                        ]),
                        const Gap(24),
                        _ResponsiveRow([
                          IntlPhoneField(
                            initialCountryCode: _fatherWhatsappCountryCode,
                            initialValue: _fatherWhatsappNationalNumber,
                            decoration: InputDecoration(
                              labelText: "Father's WhatsApp",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (phone) {
                              _fullFatherWhatsapp = phone.number.isEmpty ? '' : phone.completeNumber;
                            },
                          ),
                          IntlPhoneField(
                            initialCountryCode: _motherWhatsappCountryCode,
                            initialValue: _motherWhatsappNationalNumber,
                            decoration: InputDecoration(
                              labelText: "Mother's WhatsApp",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (phone) {
                              _fullMotherWhatsapp = phone.number.isEmpty ? '' : phone.completeNumber;
                            },
                          ),
                        ]),
                        const Gap(24),
                        ABMTextField(label: 'Full Address', hint: 'Residential address', controller: _addressController, maxLines: 3, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                        const Gap(24),
                        _ResponsiveRow([
                          Autocomplete<String>(
                            initialValue: TextEditingValue(text: _countryController.text),
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return countries.map((c) => c.name);
                              }
                              return countries.map((c) => c.name).where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (String selection) {
                              _countryController.text = selection;
                            },
                            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                              return ABMTextField(
                                label: 'Country',
                                hint: 'India',
                                controller: textEditingController,
                                focusNode: focusNode,
                                onChanged: (val) => _countryController.text = val,
                              );
                            },
                          ),
                          ABMTextField(label: 'State', hint: 'State name', controller: _stateController),
                        ]),
                        const Gap(32),
                        const SectionHeader(title: 'IDs & Family Details'),
                        const Gap(24),
                        _ResponsiveRow([
                          ABMTextField(
                            label: 'Parent Iqama ID',
                            hint: 'Enter iqama number',
                            controller: _parentIqamaController,
                            onChanged: _checkConcession,
                          ),
                          ABMTextField(
                            label: 'Student Iqama Number',
                            hint: 'Enter student iqama number',
                            controller: _studentIqamaController,
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
                        const Text('Student Iqama Upload', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const Gap(16),
                        PhotoPickerCard(imageBytes: _studentIqamaImageBytes, photoUrl: _studentIqamaUrl, studentName: 'Iqama', onPick: _pickIqamaImage),
                        const Gap(24),
                        _ResponsiveRow([
                          ABMTextField(label: 'Father Occupation', hint: 'e.g., Engineer', controller: _fatherOccupationController),
                          ABMTextField(label: 'Mother Occupation', hint: 'e.g., Teacher', controller: _motherOccupationController),
                        ]),
                        const Gap(24),
                        ABMTextField(
                          label: 'No of Children', 
                          hint: '0', 
                          controller: _numberOfChildrenController, 
                          keyboardType: TextInputType.number,
                          onChanged: _onNumberOfChildrenChanged,
                        ),
                        if (_childrenAgeControllers.isNotEmpty) ...[
                          const Gap(16),
                          const Text('Ages of Children', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                          const Gap(8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(_childrenAgeControllers.length, (index) {
                              return SizedBox(
                                width: 80,
                                child: ABMTextField(
                                  label: 'Child ${index + 1}',
                                  hint: 'Age',
                                  controller: _childrenAgeControllers[index],
                                  keyboardType: TextInputType.number,
                                ),
                              );
                            }),
                          ),
                        ],
                        const Gap(32),
                        const SectionHeader(title: 'Enrollment & Transportation'),
                        const Gap(24),
                        _buildInstituteDropdown(),
                        const Gap(24),
                        _ResponsiveRow([
                          ABMDropdownField<String>(
                            label: 'Shift',
                            value: _shift,
                            items: const ['Shift-1', 'Shift-2'],
                            onChanged: (v) => setState(() => _shift = v!),
                          ),
                          ABMDatePickerField(
                            label: 'Date of Joining',
                            date: _admissionDate,
                            onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: _admissionDate, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)));
                              if (picked != null) setState(() => _admissionDate = picked);
                            },
                          ),
                        ]),
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
                        if (_isEdit &&
                            const [AppRoles.itAdmin, AppRoles.superAdmin, AppRoles.headMaster]
                                .contains(ref.watch(authControllerProvider).value?.role)) ...[
                          const Gap(28),
                          const SectionHeader(title: 'Student Login Access'),
                          const Gap(8),
                          _StudentLoginSection(studentId: widget.existingStudent!.id),
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
          final user = ref.read(authControllerProvider).value;
          final allowedModules = user != null ? ref.read(permissionControllerProvider.notifier).getPermissionsForRole(user.role) : <String>{};
          final canAddClass = user?.role.canEditAdministration(allowedModules) ?? false;
          
          return ABMDropdownField<String>(
            label: 'Classroom',
            value: effectiveValue,
            items: dropdownItems,
            onChanged: (v) { 
              if (v != 'No classes available') {
                setState(() => _selectedClass = v!);
              }
            },
            trailing: canAddClass ? Material(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              child: IconButton(
                icon: const Icon(Icons.add, size: 24),
                onPressed: () => _showAddClassDialog(context),
                color: context.colors.primary,
              ),
            ) : null,
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
    // IT Admin: full dropdown from live institute list
    if (_isAdmin) {
      return Consumer(builder: (context, ref, _) {
        final institutesAsync = ref.watch(instituteListProvider);
        return institutesAsync.when(
          data: (institutes) {
            if (institutes.isEmpty) return const SizedBox.shrink();
            // Ensure the current value is valid
            final ids = institutes.map((i) => i.id).toList();
            if (!ids.contains(_selectedInstituteId)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _selectedInstituteId = ids.first);
              });
            }
            return ABMDropdownField<String>(
              label: 'Institute',
              value: ids.contains(_selectedInstituteId) ? _selectedInstituteId : ids.first,
              items: ids,
              labelMapper: (id) {
                final match = institutes.where((i) => i.id == id);
                return match.isNotEmpty ? match.first.name : id;
              },
              onChanged: (v) => setState(() => _selectedInstituteId = v!),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
        );
      });
    }

    return Consumer(builder: (context, ref, _) {
      final colors = context.colors;
      final institutesAsync = ref.watch(instituteListProvider);
      final instituteName = institutesAsync.maybeWhen(
        data: (list) {
          final match = list.where((i) => i.id == _selectedInstituteId);
          return match.isNotEmpty ? match.first.name : _selectedInstituteId;
        },
        orElse: () => _selectedInstituteId,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Institute',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
          ),
          const Gap(8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lock, size: 16, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    instituteName,
                    style: TextStyle(fontWeight: FontWeight.w600, color: colors.primary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Auto-assigned',
                    style: TextStyle(fontSize: 10, color: colors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
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

/// Lets a Head Master / IT Admin create, update, disable or remove a student's
/// login from the edit screen. Login = a Student-role account tied to this record.
class _StudentLoginSection extends ConsumerStatefulWidget {
  const _StudentLoginSection({required this.studentId});
  final String studentId;
  @override
  ConsumerState<_StudentLoginSection> createState() => _StudentLoginSectionState();
}

class _StudentLoginSectionState extends ConsumerState<_StudentLoginSection> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  StudentLoginStatus? _status;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final s = await ref.read(studentLoginRepositoryProvider).getStatus(widget.studentId);
      _username.text = s.username ?? s.suggestedUsername;
      if (mounted) setState(() { _status = s; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load login status'; _loading = false; });
    }
  }

  Future<void> _run(Future<StudentLoginStatus> Function() action, String okMsg) async {
    setState(() { _busy = true; _error = null; });
    try {
      final s = await action();
      _password.clear();
      _username.text = s.username ?? _username.text;
      if (mounted) {
        setState(() { _status = s; _busy = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(okMsg), backgroundColor: const Color(0xFF16A34A)));
      }
    } catch (e) {
      if (mounted) {
        setState(() { _busy = false; _error = e.toString().replaceFirst('Exception: ', ''); });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final repo = ref.read(studentLoginRepositoryProvider);
    final has = _status?.hasLogin ?? false;
    final enabled = _status?.loginEnabled ?? false;

    if (_loading) {
      return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(has && enabled ? LucideIcons.userCheck : LucideIcons.userCog,
                  size: 18, color: has && enabled ? const Color(0xFF16A34A) : colors.textSecondary),
              const Gap(9),
              Expanded(
                child: Text(
                  !has ? 'No login yet' : (enabled ? 'Login active' : 'Login disabled'),
                  style: context.typography.bodyMediumSemiBold,
                ),
              ),
              if (has)
                Switch(
                  value: enabled,
                  onChanged: _busy ? null : (v) => _run(
                    () => repo.setLogin(widget.studentId, username: _username.text.trim(), enabled: v),
                    v ? 'Login enabled' : 'Login disabled',
                  ),
                ),
            ],
          ),
          const Gap(4),
          Text(
            'The student signs in with this username and password to see their dashboard, attendance and fees.',
            style: context.typography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const Gap(14),
          ABMTextField(label: 'Username', hint: 'e.g. roll number', controller: _username, prefixIcon: LucideIcons.atSign),
          const Gap(12),
          ABMTextField(
            label: has ? 'New Password (leave blank to keep)' : 'Password',
            hint: has ? 'Reset password' : 'Set a password',
            controller: _password,
            isPassword: true,
            prefixIcon: LucideIcons.lock,
          ),
          if (_error != null) ...[
            const Gap(10),
            Text(_error!, style: context.typography.bodySmall.copyWith(color: const Color(0xFFDC2626))),
          ],
          const Gap(14),
          Row(
            children: [
              Expanded(
                child: ABMButton(
                  text: has ? 'Save Login' : 'Create Login',
                  isLoading: _busy,
                  onPressed: _busy
                      ? null
                      : () {
                          final u = _username.text.trim();
                          if (u.isEmpty) { setState(() => _error = 'Enter a username'); return; }
                          if (!has && _password.text.isEmpty) { setState(() => _error = 'Set a password to create the login'); return; }
                          _run(
                            () => repo.setLogin(widget.studentId, username: u, password: _password.text, enabled: true),
                            has ? 'Login updated' : 'Login created',
                          );
                        },
                ),
              ),
              if (has) ...[
                const Gap(10),
                IconButton(
                  tooltip: 'Remove login',
                  onPressed: _busy
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await repo.removeLogin(widget.studentId);
                          _password.clear();
                          if (!mounted) return;
                          setState(() => _status = const StudentLoginStatus(
                              hasLogin: false, loginEnabled: false, suggestedUsername: ''));
                          messenger.showSnackBar(const SnackBar(content: Text('Login removed')));
                        },
                  icon: const Icon(LucideIcons.trash2, color: Color(0xFFDC2626)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
