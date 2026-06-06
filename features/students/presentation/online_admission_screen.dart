import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ─── Available Grades ───────────────────────────────────────────────────────────

const _grades = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Hifz 1', 'Hifz 2'];

// ─── Screen ─────────────────────────────────────────────────────────────────────

class OnlineAdmissionScreen extends ConsumerStatefulWidget {
  const OnlineAdmissionScreen({super.key});

  @override
  ConsumerState<OnlineAdmissionScreen> createState() => _OnlineAdmissionScreenState();
}

class _OnlineAdmissionScreenState extends ConsumerState<OnlineAdmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _guardianController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _passportController = TextEditingController();
  final _iqamaController = TextEditingController();

  DateTime? _dob;
  String _gender = 'Male';
  String _grade = 'Grade 1';
  bool _needsTransport = false;

  bool _isSubmitting = false;
  String? _submittedStudentId;
  bool _showConcessionHint = false;
  int _siblingCount = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _guardianController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _passportController.dispose();
    _iqamaController.dispose();
    super.dispose();
  }

  Future<void> _checkSiblings(String familyId) async {
    if (familyId.length < 4) {
      setState(() { _showConcessionHint = false; });
      return;
    }
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/students/siblings-count/$familyId');
      final count = (response.data['count'] as int?) ?? 0;
      setState(() {
        _siblingCount = count;
        _showConcessionHint = count >= 2;
      });
    } catch (_) {}
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 8),
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year - 3),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Date of Birth')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/students/public-admission', data: {
        'fullName': _nameController.text.trim(),
        'dateOfBirth': _dob!.toIso8601String(),
        'gender': _gender,
        'grade': _grade,
        'guardianName': _guardianController.text.trim(),
        'parentContact': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'parentPassportId': _passportController.text.trim(),
        'parentIqamaId': _iqamaController.text.trim(),
        'needsTransportation': _needsTransport,
        'isActive': true,
        'evaluationStatus': 'Pending',
      });

      final id = response.data['studentId'] as String? ?? '';
      setState(() => _submittedStudentId = id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    if (_submittedStudentId != null) {
      return _SuccessScreen(studentId: _submittedStudentId!);
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.primary, const Color(0xFF2E7D52)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Online Admission', style: typography.h3.copyWith(color: Colors.white)),
                        Text('Anas Bin Malik Madrasa • Registration Form',
                            style: typography.bodySmall.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormSection(
                          title: 'Student Information',
                          icon: LucideIcons.user,
                          children: [
                            ABMTextField(
                              label: 'Full Name *',
                              controller: _nameController,
                              hint: 'Enter student full name',
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                            ),
                            const Gap(16),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _pickDob,
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Date of Birth *',
                                          filled: true,
                                          fillColor: colors.cardBackground,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          suffixIcon: const Icon(LucideIcons.calendar, size: 18),
                                        ),
                                        controller: TextEditingController(
                                          text: _dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : '',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const Gap(16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _gender,
                                    decoration: InputDecoration(
                                      labelText: 'Gender *',
                                      filled: true,
                                      fillColor: colors.cardBackground,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                    onChanged: (v) => setState(() => _gender = v!),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(16),
                            DropdownButtonFormField<String>(
                              value: _grade,
                              decoration: InputDecoration(
                                labelText: 'Apply for Grade *',
                                filled: true,
                                fillColor: colors.cardBackground,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (v) => setState(() => _grade = v!),
                            ),
                          ],
                        ),
                        const Gap(24),
                        _FormSection(
                          title: 'Guardian & Contact',
                          icon: LucideIcons.users,
                          children: [
                            ABMTextField(
                              label: 'Guardian Name *',
                              controller: _guardianController,
                              hint: 'Father / Mother / Guardian',
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const Gap(16),
                            ABMTextField(
                              label: 'Contact Number *',
                              controller: _contactController,
                              hint: '+966 5X XXX XXXX',
                              keyboardType: TextInputType.phone,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const Gap(16),
                            ABMTextField(
                              label: 'Residential Address',
                              controller: _addressController,
                              hint: 'Street, City, Country',
                            ),
                          ],
                        ),
                        const Gap(24),
                        _FormSection(
                          title: 'Parent Identification',
                          icon: LucideIcons.fileText,
                          children: [
                            ABMTextField(
                              label: 'Parent Passport ID',
                              controller: _passportController,
                              hint: 'Used for family concession detection',
                              onChanged: (v) => _checkSiblings(v),
                            ),
                            const Gap(8),
                            Text(
                              'OR',
                              style: typography.bodySmall.copyWith(color: colors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const Gap(8),
                            ABMTextField(
                              label: 'Parent Iqama ID',
                              controller: _iqamaController,
                              hint: 'Saudi Iqama Number',
                              onChanged: (v) => _checkSiblings(v),
                            ),
                            if (_showConcessionHint) ...[
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
                                        'Family fee concession will be applied — $_siblingCount sibling(s) already enrolled.',
                                        style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Gap(24),
                        _FormSection(
                          title: 'Transportation',
                          icon: LucideIcons.bus,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _needsTransport,
                              onChanged: (v) => setState(() => _needsTransport = v),
                              title: Text('Opt-in for School Transportation', style: typography.bodyMedium),
                              subtitle: Text('Transportation fee will be added to monthly dues', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                            ),
                          ],
                        ),
                        const Gap(32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(LucideIcons.send),
                            label: Text(_isSubmitting ? 'Submitting...' : 'Submit Application'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const Gap(24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colors.primary, size: 20),
              ),
              const Gap(12),
              Text(title, style: context.typography.h4),
            ],
          ),
          const Gap(20),
          ...children,
        ],
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.checkCircle, color: Colors.green, size: 56),
                ),
                const Gap(28),
                Text('Application Submitted!', style: context.typography.h3, textAlign: TextAlign.center),
                const Gap(12),
                Text(
                  'Your application has been received. The administration will review and contact you shortly.',
                  style: context.typography.bodyMedium.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const Gap(28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text('Your Student ID', style: context.typography.bodySmall.copyWith(color: colors.textSecondary)),
                      const Gap(8),
                      Text(studentId, style: context.typography.h2.copyWith(color: colors.primary, letterSpacing: 3)),
                      const Gap(4),
                      Text('Save this ID to track your child\'s progress', style: context.typography.caption),
                    ],
                  ),
                ),
                const Gap(28),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/parent-portal'),
                  icon: const Icon(LucideIcons.search),
                  label: const Text('Track Student Progress'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
