import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/features/auth/providers/auth_provider.dart';
import 'package:unifye/features/swipe/providers/swipe_provider.dart';
import 'package:unifye/features/swipe/widgets/swipe_user_card.dart';

class SwipePage extends ConsumerStatefulWidget {
  const SwipePage({super.key});

  @override
  ConsumerState<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends ConsumerState<SwipePage> {
  String? _activeUserId;
  String? _lastToast;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final swipeState = ref.watch(swipeProvider);

    return authState.when(
      unauthenticated: () => const Scaffold(
        body: Center(child: Text('Please login first.')),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      authenticated: (user, token) {
        if (_activeUserId != user.id) {
          _activeUserId = user.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(swipeProvider.notifier).loadCandidates(user.id);
          });
        }

        _consumeTransientMessages(swipeState);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Discover'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: swipeState.isLoading
                    ? null
                    : () => ref.read(swipeProvider.notifier).loadCandidates(user.id),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBody(user.id, swipeState),
          ),
        );
      },
    );
  }

  Widget _buildBody(String userId, SwipeState state) {
    if (state.isLoading && state.candidates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.candidates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              state.error!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(swipeProvider.notifier).loadCandidates(userId),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (state.candidates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 48),
            const SizedBox(height: 12),
            Text(state.infoMessage ?? 'No users available right now.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(swipeProvider.notifier).loadCandidates(userId),
              child: const Text('Reload'),
            ),
          ],
        ),
      );
    }

    final candidate = state.candidates.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: SwipeUserCard(candidate: candidate),
              ),
              if (state.isSwiping)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x44000000),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.isSwiping
                    ? null
                    : () => ref.read(swipeProvider.notifier).swipeCurrent(
                          userId: userId,
                          isLiked: false,
                        ),
                icon: const Icon(Icons.close),
                label: Text(state.isSwiping ? 'Please wait...' : 'Pass'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: state.isSwiping
                    ? null
                    : () => ref.read(swipeProvider.notifier).swipeCurrent(
                          userId: userId,
                          isLiked: true,
                        ),
                icon: const Icon(Icons.favorite),
                label: Text(state.isSwiping ? 'Please wait...' : 'Like'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _consumeTransientMessages(SwipeState swipeState) {
    final notifier = ref.read(swipeProvider.notifier);

    if (swipeState.error != null && swipeState.error != _lastToast) {
      _lastToast = swipeState.error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(swipeState.error!)),
        );
        notifier.clearMessages();
      });
      return;
    }

    if (swipeState.matchMessage != null && swipeState.matchMessage != _lastToast) {
      _lastToast = swipeState.matchMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(swipeState.matchMessage!),
            backgroundColor: Colors.pink.shade400,
          ),
        );
        notifier.clearMessages();
      });
      return;
    }

    if (swipeState.infoMessage != null && swipeState.infoMessage != _lastToast) {
      _lastToast = swipeState.infoMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(swipeState.infoMessage!)),
        );
        notifier.clearMessages();
      });
    }
  }
}
