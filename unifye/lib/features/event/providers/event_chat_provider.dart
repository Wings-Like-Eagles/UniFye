import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/features/event/repositories/event_repository.dart';
import 'package:unifye/features/messages/models/chat_model.dart';

import 'event_provider.dart';
import 'event_request.dart';

final eventChatProvider = StateNotifierProvider.family<EventChatNotifier,
    AsyncValue<List<ChatMessage>>, String>(
  (ref, eventId) => EventChatNotifier(ref, eventId),
);

class EventChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  EventChatNotifier(this._ref, this._eventId)
      : super(const AsyncValue.loading());

  final Ref _ref;
  final String _eventId;

  EventRepository get _repo => _ref.read(eventRepositoryProvider);

  Future<void> fetchMessages() async {
    state = const AsyncValue.loading();
    final result = await _repo.getChatMessages(_eventId);
    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
    } else {
      state = AsyncValue.error(
        result.errorMessage!,
        StackTrace.current,
      );
    }
  }

  Future<void> sendMessage(String content) async {
    final result = await _repo.sendChatMessage(
      _eventId,
      SendChatMessageRequest(content: content),
    );
    if (result.isSuccess) {
      await fetchMessages();
    }
  }
}
