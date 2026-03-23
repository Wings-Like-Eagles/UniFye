import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/features/swipe/models/swipe_candidate.dart';
import 'package:unifye/features/swipe/services/swipe_service.dart';

class SwipeState {
  final bool isLoading;
  final bool isSwiping;
  final List<SwipeCandidate> candidates;
  final String? error;
  final String? infoMessage;
  final String? matchMessage;

  const SwipeState({
    this.isLoading = false,
    this.isSwiping = false,
    this.candidates = const <SwipeCandidate>[],
    this.error,
    this.infoMessage,
    this.matchMessage,
  });

  SwipeState copyWith({
    bool? isLoading,
    bool? isSwiping,
    List<SwipeCandidate>? candidates,
    String? error,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
    String? matchMessage,
    bool clearMatch = false,
  }) {
    return SwipeState(
      isLoading: isLoading ?? this.isLoading,
      isSwiping: isSwiping ?? this.isSwiping,
      candidates: candidates ?? this.candidates,
      error: clearError ? null : (error ?? this.error),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      matchMessage: clearMatch ? null : (matchMessage ?? this.matchMessage),
    );
  }
}

class SwipeNotifier extends StateNotifier<SwipeState> {
  SwipeNotifier(this._swipeService) : super(const SwipeState());

  final SwipeService _swipeService;

  Future<void> loadCandidates(String userId) async {
    if (userId.trim().isEmpty) {
      state = state.copyWith(error: 'Missing user id.', clearInfo: true, clearMatch: true);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true, clearMatch: true);
    try {
      final candidates = await _swipeService.getCandidates(userId: userId);
      state = state.copyWith(
        isLoading: false,
        candidates: candidates,
        infoMessage: candidates.isEmpty ? 'No more profiles right now.' : null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> swipeCurrent({
    required String userId,
    required bool isLiked,
  }) async {
    if (state.candidates.isEmpty || state.isSwiping) {
      return;
    }

    final current = state.candidates.first;
    state = state.copyWith(isSwiping: true, clearError: true, clearInfo: true, clearMatch: true);

    try {
      final result = await _swipeService.swipe(
        userId: userId,
        targetUserId: current.id,
        isLiked: isLiked,
      );

      final nextCandidates = List<SwipeCandidate>.from(state.candidates)..removeAt(0);
      final infoMessage = !result.isMatch && result.message.isNotEmpty
          ? result.message
          : nextCandidates.isEmpty
              ? 'No more profiles right now.'
              : null;
      state = state.copyWith(
        isSwiping: false,
        candidates: nextCandidates,
        matchMessage: result.isMatch ? result.message : null,
        infoMessage: infoMessage,
      );
    } catch (error) {
      state = state.copyWith(
        isSwiping: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearInfo: true, clearMatch: true);
  }
}

final swipeProvider = StateNotifierProvider<SwipeNotifier, SwipeState>((ref) {
  final service = ref.watch(swipeServiceProvider);
  return SwipeNotifier(service);
});
