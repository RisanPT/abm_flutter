import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/timetable/domain/shift_plan_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shift_planner_controller.g.dart';

@riverpod
class ShiftPlannerController extends _$ShiftPlannerController {
  @override
  Future<List<DateTime>> build(String shift, int year, int month) async {
    return _fetchShiftPlan(shift, year, month);
  }

  Future<List<DateTime>> _fetchShiftPlan(String shift, int year, int month) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '/shift-plans',
        queryParameters: {
          'shift': shift,
          'year': year,
          'month': month,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (data.isNotEmpty) {
          final plan = ShiftPlanModel.fromJson(data.first);
          return plan.classDates;
        }
        return [];
      } else {
        throw Exception('Failed to load shift plan');
      }
    } catch (e) {
      throw Exception('Error loading shift plan: $e');
    }
  }

  Future<void> savePlan(List<DateTime> classDates) async {
    try {
      state = const AsyncLoading();
      final dio = ref.read(dioProvider);
      
      final response = await dio.post(
        '/shift-plans',
        data: {
          'shift': shift,
          'year': year,
          'month': month,
          'classDates': classDates.map((d) => d.toIso8601String()).toList(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = AsyncData(classDates);
      } else {
        throw Exception('Failed to save shift plan');
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}
