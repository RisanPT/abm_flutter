import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:abm_madrasa/core/repositories/institute_repository.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';

part 'institute_provider.freezed.dart';
part 'institute_provider.g.dart';

@freezed
abstract class Institute with _$Institute {
  const factory Institute({
    @JsonKey(name: '_id') required String id,
    required String name,
    required String location,
    String? address,
    String? contactNumber,
    String? email,
    @Default('school') String iconName,
    @Default(true) bool isActive,
    @Default(25.2048) double latitude,
    @Default(55.2708) double longitude,
    @Default(500.0) double radius,
  }) = _Institute;

  factory Institute.fromJson(Map<String, dynamic> json) => _$InstituteFromJson(json);
}

extension InstituteX on Institute {
  IconData get icon {
    switch (iconName) {
      case 'building': return LucideIcons.building;
      case 'globe': return LucideIcons.globe;
      case 'school':
      default: return LucideIcons.school;
    }
  }
}

@riverpod
class InstituteList extends _$InstituteList {
  @override
  Future<List<Institute>> build() {
    return ref.watch(instituteRepositoryProvider).getInstitutes();
  }

  Future<void> addInstitute(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(instituteRepositoryProvider).createInstitute(data);
      return ref.read(instituteRepositoryProvider).getInstitutes();
    });
  }

  Future<void> updateInstitute(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(instituteRepositoryProvider).updateInstitute(id, data);
      return ref.read(instituteRepositoryProvider).getInstitutes();
    });
  }

  Future<void> deleteInstitute(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(instituteRepositoryProvider).deleteInstitute(id);
      return ref.read(instituteRepositoryProvider).getInstitutes();
    });
  }
}

@riverpod
class SelectedInstitute extends _$SelectedInstitute {
  Institute? _manualSelection;

  @override
  Institute build() {
    final authState = ref.watch(authControllerProvider);
    final institutesAsync = ref.watch(instituteListProvider);

    return institutesAsync.maybeWhen(
      data: (list) {
        if (list.isEmpty) {
          return const Institute(id: 'default', name: 'No Institutes', location: '...');
        }

        if (_manualSelection != null && list.any((i) => i.id == _manualSelection!.id)) {
          return _manualSelection!;
        }

        final user = authState.asData?.value;
        if (user != null && user.instituteId != null) {
          final matched = list.firstWhere(
            (i) => i.id == user.instituteId,
            orElse: () => list.first,
          );
          return matched;
        }

        return list.first;
      },
      orElse: () => const Institute(id: 'default', name: 'Loading...', location: '...'),
    );
  }

  void setInstitute(Institute institute) {
    _manualSelection = institute;
    state = institute;
  }
}

