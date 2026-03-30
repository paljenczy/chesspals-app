import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../model/auth/lichess_account.dart';
import '../../model/matchmaking/matchmaking_controller.dart';

/// Quick seek screen — choose a time control and find a human opponent.
/// Requires a Lichess account (OAuth token stored by LichessClient).
class PlayHumanScreen extends ConsumerStatefulWidget {
  const PlayHumanScreen({super.key});

  static const _timeControls = [
    _TimeControl(label: '10 + 0', minutes: 10, increment: 0, emoji: '🏃'),
    _TimeControl(label: '10 + 5', minutes: 10, increment: 5, emoji: '🧘'),
    _TimeControl(label: '15 + 10', minutes: 15, increment: 10, emoji: '🌳'),
  ];

  @override
  ConsumerState<PlayHumanScreen> createState() => _PlayHumanScreenState();
}

class _PlayHumanScreenState extends ConsumerState<PlayHumanScreen> {
  @override
  void initState() {
    super.initState();
    // Reset stale seeking state when navigating back to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchmakingProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchmakingProvider);

    // Auto-navigate when a game is found
    ref.listen<AsyncValue<MatchmakingState?>>(matchmakingProvider, (_, next) {
      final data = next.value;
      if (data != null && !data.isSeeking && data.gameId != null) {
        ref.read(matchmakingProvider.notifier).reset();
        if (mounted) context.go('/game/${data.gameId}?side=random');
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: matchState.when(
            loading: () => const _SeekingView(),
            error: (e, _) => _ErrorView(message: e.toString()),
            data: (state) => state == null
                ? _IdleView(timeControls: PlayHumanScreen._timeControls)
                : const _SeekingView(),
          ),
        ),
      ),
    );
  }
}

class _IdleView extends ConsumerStatefulWidget {
  const _IdleView({required this.timeControls});
  final List<_TimeControl> timeControls;

  @override
  ConsumerState<_IdleView> createState() => _IdleViewState();
}

class _IdleViewState extends ConsumerState<_IdleView> {
  bool _rated = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final account = ref.watch(accountProvider).value;
    final rapidRating = account?.rapidRating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          l.playHumanTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        if (rapidRating != null)
          Text(
            l.playHumanYourRating(rapidRating),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        Center(
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l.playHumanUnrated)),
              ButtonSegment(value: true, label: Text(l.playHumanRated)),
            ],
            selected: {_rated},
            onSelectionChanged: (v) => setState(() => _rated = v.first),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.playHumanChooseTime,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ...widget.timeControls.map(
          (tc) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _TimeControlCard(
              timeControl: tc,
              onTap: () => ref
                  .read(matchmakingProvider.notifier)
                  .seek(minutes: tc.minutes, increment: tc.increment, rated: _rated),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              const Text('👥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _rated ? l.playHumanRatedNote : l.playHumanUnratedNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeControlCard extends StatelessWidget {
  const _TimeControlCard({required this.timeControl, required this.onTap});

  final _TimeControl timeControl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Text(
                timeControl.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.playHumanTimeMinutes(timeControl.label),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      _description(l, timeControl),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _description(AppLocalizations l, _TimeControl tc) {
    if (tc.increment == 0) return l.playHumanDescMedium;
    if (tc.minutes <= 10) return l.playHumanDescSlow;
    return l.playHumanDescDeep;
  }
}

class _SeekingView extends ConsumerWidget {
  const _SeekingView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🔍', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 24),
        Text(
          l.playHumanSeeking,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const LinearProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          l.playHumanSeekingNote,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () =>
              ref.read(matchmakingProvider.notifier).cancelSeek(),
          icon: const Icon(Icons.close),
          label: Text(l.playHumanCancel),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final needsLogin = message.contains('401') || message.contains('auth');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('😕', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(
          needsLogin ? l.playHumanErrorLogin : l.playHumanErrorConnect,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => ref.read(matchmakingProvider.notifier).reset(),
          icon: const Icon(Icons.refresh),
          label: Text(l.playHumanTryAgain),
        ),
      ],
    );
  }
}

class _TimeControl {
  const _TimeControl({
    required this.label,
    required this.minutes,
    required this.increment,
    required this.emoji,
  });

  final String label;
  final int minutes;
  final int increment;
  final String emoji;
}
