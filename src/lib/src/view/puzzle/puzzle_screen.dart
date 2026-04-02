import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartchess/dartchess.dart';
import 'package:chessground/chessground.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../l10n/app_localizations.dart';
import '../../model/puzzle/puzzle_controller.dart';
import '../../model/puzzle/puzzle_stars.dart';
import '../../model/puzzle/puzzle_theme.dart';

/// Puzzle tab — Setup panel for theme/difficulty/rated, then puzzle solving.
class PuzzleScreen extends ConsumerWidget {
  const PuzzleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzleState = ref.watch(puzzleControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: puzzleState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (state) => state == null
            ? const _PuzzleSetupView()
            : _PuzzleView(state: state),
      ),
    );
  }
}

// ─── Setup View ──────────────────────────────────────────────────────────────

class _PuzzleSetupView extends ConsumerStatefulWidget {
  const _PuzzleSetupView();

  @override
  ConsumerState<_PuzzleSetupView> createState() => _PuzzleSetupViewState();
}

class _PuzzleSetupViewState extends ConsumerState<_PuzzleSetupView> {
  bool _topicPickerExpanded = false;
  PuzzleThemeCategory? _expandedCategory;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(puzzleSettingsProvider);
    final grouped = PuzzleTheme.groupedByCategory;
    final healthyMix = grouped[PuzzleThemeCategory.meta]!.first;
    final isHealthyMix = settings.theme == healthyMix.apiKey;
    final selectedTheme = isHealthyMix ? null : PuzzleTheme.fromApiKey(settings.theme);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Screen title
            Text(
              l.puzzleSetupTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // ── Topic row: Healthy Mix + Select a topic + selected display ──
            _SectionHeader(title: l.puzzleTopicLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // Healthy Mix chip — tapping selects and starts a puzzle
                FilterChip(
                  selected: isHealthyMix,
                  label: Text(
                    '${healthyMix.emoji} ${healthyMix.localizedName(context)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isHealthyMix ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  onSelected: (_) {
                    ref.read(puzzleSettingsProvider.notifier).update((s) => s.copyWith(theme: healthyMix.apiKey));
                    ref.read(puzzleControllerProvider.notifier).loadNextPuzzle();
                  },
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                // Select a topic chip — toggles the picker
                ActionChip(
                  avatar: Icon(
                    _topicPickerExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(
                    l.puzzleSelectTopic,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: () => setState(() {
                    _topicPickerExpanded = !_topicPickerExpanded;
                    if (!_topicPickerExpanded) _expandedCategory = null;
                  }),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                // Show selected topic when picker is collapsed and a non-mix theme is selected
                if (!_topicPickerExpanded && selectedTheme != null)
                  FilterChip(
                    selected: true,
                    label: Text(
                      '${selectedTheme.emoji} ${selectedTheme.localizedName(context)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    onSelected: (_) => setState(() {
                      _topicPickerExpanded = true;
                    }),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),

            // ── Expanded topic picker ──
            if (_topicPickerExpanded) ...[
              const SizedBox(height: 8),
              ...grouped.entries.where((e) => e.key != PuzzleThemeCategory.meta).expand((entry) {
                final cat = entry.key;
                final themes = entry.value;
                final isExpanded = _expandedCategory == cat;

                return [
                  InkWell(
                    onTap: () => setState(() {
                      _expandedCategory = isExpanded ? null : cat;
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.localizedName(l),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 20,
                            color: Colors.grey[500],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: themes.map((theme) {
                          final selected = settings.theme == theme.apiKey;
                          return FilterChip(
                            selected: selected,
                            label: Text(
                              '${theme.emoji} ${theme.localizedName(context)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            onSelected: (_) {
                              ref.read(puzzleSettingsProvider.notifier).update((s) => s.copyWith(theme: theme.apiKey));
                              setState(() {
                                _topicPickerExpanded = false;
                                _expandedCategory = null;
                              });
                            },
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ),
                ];
              }),
            ],

            const SizedBox(height: 20),

            // ── Difficulty selector ──
            _SectionHeader(title: l.puzzleDifficultyLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: PuzzleDifficulty.values.map((d) {
                final selected = settings.difficulty == d;
                return ChoiceChip(
                  selected: selected,
                  label: Text(
                    _difficultyLabel(l, d),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  onSelected: (_) => ref
                      .read(puzzleSettingsProvider.notifier)
                      .update((s) => s.copyWith(difficulty: d)),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ── Rated toggle ──
            Center(
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(l.puzzleRated)),
                  ButtonSegment(value: false, label: Text(l.puzzleUnrated)),
                ],
                selected: {settings.rated},
                onSelectionChanged: (v) => ref
                    .read(puzzleSettingsProvider.notifier)
                    .update((s) => s.copyWith(rated: v.first)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              settings.rated ? l.puzzleRatedNote : l.puzzleUnratedNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // ── Start Training button ──
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => ref
                    .read(puzzleControllerProvider.notifier)
                    .loadNextPuzzle(),
                icon: const Icon(Icons.play_arrow, size: 22),
                label: Text(
                  l.puzzleStartTraining,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _difficultyLabel(AppLocalizations l, PuzzleDifficulty d) =>
      switch (d) {
        PuzzleDifficulty.easiest => l.puzzleDifficultyEasiest,
        PuzzleDifficulty.easier => l.puzzleDifficultyEasier,
        PuzzleDifficulty.normal => l.puzzleDifficultyNormal,
        PuzzleDifficulty.harder => l.puzzleDifficultyHarder,
        PuzzleDifficulty.hardest => l.puzzleDifficultyHardest,
      };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

// ─── Puzzle View ─────────────────────────────────────────────────────────────

class _PuzzleView extends ConsumerWidget {
  const _PuzzleView({required this.state});
  final PuzzleState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final controller = ref.read(puzzleControllerProvider.notifier);
    final boardSize =
        MediaQuery.of(context).size.width.clamp(200.0, 500.0).toDouble();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 20, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => ref
                      .read(puzzleControllerProvider.notifier)
                      .backToSetup(),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: l.puzzleChangeSettings,
                ),
                Expanded(
                  child: Text(
                    state.isDaily
                        ? l.puzzleDailyTitle
                        : l.puzzleTitle(state.puzzle.id),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              state.mode == PuzzleMode.viewingSolution
                  ? l.puzzleViewingSolution
                  : state.mode == PuzzleMode.review
                      ? l.puzzleSolved
                      : state.sideToMove == Side.white
                          ? l.puzzleWhiteToMove
                          : l.puzzleBlackToMove,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),

          // Board
          Center(
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: Chessboard(
                size: boardSize,
                orientation: state.orientation,
                fen: state.fen,
                lastMove: state.lastMove,
                shapes: state.hintSquare != null
                    ? ISet({
                        Circle(
                          color: const Color(0x8015781B),
                          orig: state.hintSquare!,
                        ),
                      })
                    : null,
                game: GameData(
                  playerSide: state.orientation == Side.white
                      ? PlayerSide.white
                      : PlayerSide.black,
                  validMoves: state.validMoves,
                  sideToMove: state.sideToMove,
                  isCheck: state.isCheck,
                  promotionMove: null,
                  onMove: (move, {viaDragAndDrop}) =>
                      controller.onMove(move, viaDragAndDrop: viaDragAndDrop),
                  onPromotionSelection: (_) {},
                ),
                settings: ChessboardSettings(
                  colorScheme: ChessboardColorScheme.green,
                  pieceAssets: PieceSet.cburnett.assets,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Stars & streak bar
          const _StarsBar(),

          // Result overlay
          if (state.result != null) _ResultBanner(result: state.result!),

          // Toolbar: hint + view solution (during solving)
          if (state.mode == PuzzleMode.solving && state.result == null)
            _PuzzleToolbar(controller: controller),

          // Review navigation (during review mode)
          if (state.mode == PuzzleMode.review)
            _MoveNavigationBar(controller: controller, state: state),

          // Continue Training button (after solved or in review)
          if (state.result == PuzzleResult.solved ||
              state.mode == PuzzleMode.review)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () => controller.loadNextPuzzle(),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(l.puzzleContinueTraining),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Supporting Widgets ──────────────────────────────────────────────────────

class _StarsBar extends ConsumerWidget {
  const _StarsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final stars = ref.watch(puzzleStarsProvider);
    if (stars.stars == 0 && stars.streak == 0) return const SizedBox.shrink();

    final bigStars = stars.stars ~/ 5;
    final smallStars = stars.stars % 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Star icons + count
          if (stars.stars > 0) ...[
            ...List.generate(
              bigStars.clamp(0, 6),
              (_) => const Text('🌟', style: TextStyle(fontSize: 20)),
            ),
            ...List.generate(
              smallStars.clamp(0, 4),
              (_) => const Text('⭐', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 4),
            Text(
              '${stars.stars}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.amber[800],
                  ),
            ),
          ],
          // Separator
          if (stars.stars > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '|',
                style: TextStyle(color: Colors.grey[400], fontSize: 18),
              ),
            ),
          // Streak or encouragement
          if (stars.streak >= 1) ...[
            const Text('🔥', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(
              l.puzzleStreakLabel(stars.streak),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.deepOrange[600],
                  ),
            ),
          ] else ...[
            const Text('💪', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(
              l.puzzleStreakStart,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PuzzleToolbar extends StatelessWidget {
  const _PuzzleToolbar({required this.controller});
  final PuzzleController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () => controller.showHint(),
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: Text(l.puzzleHint),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => controller.viewSolution(),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: Text(l.puzzleViewSolution),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveNavigationBar extends StatelessWidget {
  const _MoveNavigationBar({required this.controller, required this.state});
  final PuzzleController controller;
  final PuzzleState state;

  @override
  Widget build(BuildContext context) {
    final atStart = state.reviewIndex <= 0;
    final atEnd = state.positionHistory.isEmpty ||
        state.reviewIndex >= state.positionHistory.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: atStart ? null : () => controller.reviewGoToStart(),
            icon: const Icon(Icons.skip_previous),
            tooltip: 'Go to start',
          ),
          IconButton(
            onPressed: atStart ? null : () => controller.reviewStepBack(),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Step back',
          ),
          IconButton(
            onPressed: atEnd ? null : () => controller.reviewStepForward(),
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Step forward',
          ),
          IconButton(
            onPressed: atEnd ? null : () => controller.reviewGoToEnd(),
            icon: const Icon(Icons.skip_next),
            tooltip: 'Go to end',
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result});
  final PuzzleResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (text, color, icon) = switch (result) {
      PuzzleResult.correct => (l.puzzleCorrect, Colors.green[700]!, '✅'),
      PuzzleResult.wrong => (l.puzzleWrong, Colors.red[700]!, '❌'),
      PuzzleResult.solved => (l.puzzleSolved, Colors.green[800]!, '🏆'),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final isNetworkError = message.contains('SocketException') ||
        message.contains('connection') ||
        message.contains('host lookup');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              isNetworkError ? l.puzzleErrorNoInternet : l.puzzleErrorGeneric,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(puzzleControllerProvider.notifier).backToSetup(),
              icon: const Icon(Icons.refresh),
              label: Text(l.puzzleTryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
