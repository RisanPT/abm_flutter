import 'package:abm_madrasa/features/accounts/data/finance_repository.dart';
import 'package:abm_madrasa/features/accounts/domain/account_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fee_structure_controller.g.dart';

@riverpod
class FeeStructureController extends _$FeeStructureController {
  @override
  FutureOr<List<FeeStructureModel>> build() async {
    return _fetch();
  }

  Future<List<FeeStructureModel>> _fetch() async {
    final repo = ref.read(accountRepositoryProvider);
    return repo.getFeeStructures();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create(FeeStructureModel model) async {
    final repo = ref.read(accountRepositoryProvider);
    await repo.createFeeStructure(model);
    await refresh();
  }

  Future<void> updateStructure(FeeStructureModel model) async {
    final repo = ref.read(accountRepositoryProvider);
    await repo.updateFeeStructure(model);
    await refresh();
  }

  Future<void> deleteStructure(String id) async {
    final repo = ref.read(accountRepositoryProvider);
    await repo.deleteFeeStructure(id);
    await refresh();
  }
}
