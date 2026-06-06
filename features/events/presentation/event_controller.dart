import 'package:abm_madrasa/features/events/data/event_repository.dart';
import 'package:abm_madrasa/features/events/domain/event_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_controller.g.dart';

@riverpod
class EventController extends _$EventController {
  @override
  FutureOr<List<EventModel>> build() async {
    return _fetchEvents();
  }

  Future<List<EventModel>> _fetchEvents() {
    return ref.read(eventRepositoryProvider).getEvents();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchEvents());
  }

  Future<String?> uploadImage(String dataUri, String fileName) async {
    try {
      final result = await ref.read(eventRepositoryProvider).uploadEventImage(dataUri, fileName);
      return result['imageUrl'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> addEvent(EventModel event) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(eventRepositoryProvider).addEvent(event);
      return _fetchEvents();
    });
  }

  Future<void> updateEvent(String id, EventModel event) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(eventRepositoryProvider).updateEvent(id, event);
      return _fetchEvents();
    });
  }

  Future<void> deleteEvent(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(eventRepositoryProvider).deleteEvent(id);
      return _fetchEvents();
    });
  }
}

@riverpod
Future<List<EventModel>> upcomingEvents(Ref ref) async {
  final events = await ref.watch(eventControllerProvider.future);
  final now = DateTime.now();
  return events
      .where((e) => e.date.isAfter(now) || e.date.isAtSameMomentAs(now))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
}
