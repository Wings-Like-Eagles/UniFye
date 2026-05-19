import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/features/auth/providers/auth_provider.dart';

import '../../../pages/event_page.dart';
import '../models/event_detail.dart';
import '../models/event_summary_model.dart';
import '../repositories/event_repository.dart';
import 'event_request.dart';

// ---------------------------------------------------------------------------
// Repository provider — rebuilds automatically when the token changes.
// ---------------------------------------------------------------------------

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final token = ref.watch(authProvider).token ?? '';
  return EventRepository(token: token);
});

// ---------------------------------------------------------------------------
// Events list provider
// ---------------------------------------------------------------------------

final eventsProvider =
StateNotifierProvider<EventsNotifier, AsyncValue<List<EventSummary>>>(
      (ref) => EventsNotifier(ref),
);

class EventsNotifier extends StateNotifier<AsyncValue<List<EventSummary>>> {
  EventsNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchEvents();
  }

  final Ref _ref;

  EventRepository get _repo => _ref.read(eventRepositoryProvider);

  Future<void> fetchEvents({int page = 1, int pageSize = 20}) async {
    state = const AsyncValue.loading();
    final result = await _repo.getEvents(page: page, pageSize: pageSize);
    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
    } else {
      state = AsyncValue.error(
        result.errorMessage!,
        StackTrace.current,
      );
    }
  }

  /// Returns the error message on failure, null on success.
  Future<String?> joinEvent(String eventId) async {
    final result = await _repo.joinEvent(eventId);
    if (result.isSuccess) {
      await fetchEvents();
      return null;
    }
    return result.errorMessage;
  }

  /// Returns the error message on failure, null on success.
  Future<String?> leaveEvent(String eventId) async {
    final result = await _repo.leaveEvent(eventId);
    if (result.isSuccess) {
      await fetchEvents();
      return null;
    }
    return result.errorMessage;
  }

  /// Returns the error message on failure, null on success.
  Future<String?> createEvent(CreateEventRequest request) async {
    final result = await _repo.createEvent(request);
    if (result.isSuccess) {
      await fetchEvents();
      return null;
    }
    return result.errorMessage;
  }

  /// Returns the error message on failure, null on success.
  Future<String?> deleteEvent(String eventId) async {
    final result = await _repo.deleteEvent(eventId);
    if (result.isSuccess) {
      // Optimistic removal from list while refetch happens.
      state.whenData((events) {
        state = AsyncValue.data(
          events.where((e) => e.id != eventId).toList(),
        );
      });
      await fetchEvents();
      return null;
    }
    return result.errorMessage;
  }
}

// ---------------------------------------------------------------------------
// Single event detail provider — keyed by event ID.
// ---------------------------------------------------------------------------

final eventDetailProvider = StateNotifierProvider.family<EventDetailNotifier,
    AsyncValue<EventDetail>, String>(
      (ref, eventId) => EventDetailNotifier(ref, eventId),
);

class EventDetailNotifier
    extends StateNotifier<AsyncValue<EventDetail>> {
  EventDetailNotifier(this._ref, this._eventId)
      : super(const AsyncValue.loading()) {
    fetchDetail();
  }

  final Ref _ref;
  final String _eventId;

  EventRepository get _repo => _ref.read(eventRepositoryProvider);

  Future<void> fetchDetail() async {
    state = const AsyncValue.loading();
    final result = await _repo.getEvent(_eventId);
    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
    } else {
      state = AsyncValue.error(result.errorMessage!, StackTrace.current);
    }
  }

  /// Returns the error message on failure, null on success.
  Future<String?> updateEvent(UpdateEventRequest request) async {
    final result = await _repo.updateEvent(_eventId, request);
    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
      // Also refresh the list so the summary card reflects changes.
      _ref.read(eventsProvider.notifier).fetchEvents();
      return null;
    }
    return result.errorMessage;
  }
}
