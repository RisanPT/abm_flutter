import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/accounts/data/finance_repository.dart';
import 'package:abm_madrasa/features/accounts/domain/account_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountSummariesProvider = FutureProvider<List<AccountSummary>>((ref) {
  final institute = ref.watch(selectedInstituteProvider);
  return ref.read(accountRepositoryProvider).getStudentSummaries(instituteId: institute.id);
});

final studentAccountDetailsProvider =
    FutureProvider.family<StudentAccountDetails, String>((ref, studentId) {
  return ref.read(accountRepositoryProvider).getStudentAccountDetails(studentId);
});
