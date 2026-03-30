import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/lichess_client.dart';

class MatchmakingState {
  const MatchmakingState({
    required this.isSeeking,
    this.gameId,
  });

  final bool isSeeking;
  final String? gameId;
}

class MatchmakingNotifier extends AsyncNotifier<MatchmakingState?> {
  StreamSubscription<Map<String, dynamic>>? _eventSub;

  @override
  Future<MatchmakingState?> build() async => null;

  Future<void> seek({required int minutes, required int increment, required bool rated}) async {
    state = const AsyncData(MatchmakingState(isSeeking: true));

    try {
      final client = LichessClient();

      // Start listening for gameStart events first
      _eventSub = client.streamEvents().listen(
        (event) {
          if (event['type'] == 'gameStart') {
            final game = event['game'] as Map<String, dynamic>?;
            final gameId = game?['gameId'] as String? ?? game?['id'] as String?;
            if (gameId != null) {
              state = AsyncData(
                MatchmakingState(isSeeking: false, gameId: gameId),
              );
              _eventSub?.cancel();
            }
          }
        },
        onError: (e, st) {
          state = AsyncError(e, st as StackTrace);
        },
      );

      // Small delay to ensure the event stream is open, then post seek
      await Future.delayed(const Duration(milliseconds: 300));

      // seekOpponent is fire-and-forget (streaming endpoint, blocks until matched)
      LichessClient().seekOpponent(
        timeMinutes: minutes,
        increment: increment,
        rated: rated,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void cancelSeek() {
    _eventSub?.cancel();
    state = const AsyncData(null);
  }

  void reset() {
    _eventSub?.cancel();
    state = const AsyncData(null);
  }
}

final matchmakingProvider =
    AsyncNotifierProvider<MatchmakingNotifier, MatchmakingState?>(
  MatchmakingNotifier.new,
);
