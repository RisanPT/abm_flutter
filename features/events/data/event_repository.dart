import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/events/domain/event_model.dart';
import 'package:dio/dio.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_repository.g.dart';

@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) {
  final dioClient = ref.watch(dioProvider);
  return EventRepository(dioClient);
}

class EventRepository {
  final Dio _dio;
  EventRepository(this._dio);

  Future<List<EventModel>> getEvents({String? instituteId}) async {
    try {
      final response = await _dio.get('/events', queryParameters: {'instituteId': instituteId}..removeWhere((k, v) => v == null));
      final List<dynamic> data = response.data;
      return data.map((json) => EventModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  Future<EventModel> addEvent(EventModel event, {bool notify = true}) async {
    try {
      final data = event.toJson();
      data.remove('_id');
      // `notify` drives the backend's in-app notification trigger; it is not part
      // of the EventModel (which is serialized elsewhere, e.g. on patch/upload).
      data['notify'] = notify;
      final response = await _dio.post('/events', data: data);
      return EventModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to add event: $e');
    }
  }

  Future<EventModel> updateEvent(String id, EventModel event) async {
    try {
      final response = await _dio.patch('/events/$id', data: event.toJson());
      return EventModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  Future<Map<String, dynamic>> uploadEventImage(String dataUri, String fileName) async {
    try {
      final response = await _dio.post('/events/upload-image', data: {
        'dataUri': dataUri,
        'fileName': fileName,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _dio.delete('/events/$id');
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }
}
