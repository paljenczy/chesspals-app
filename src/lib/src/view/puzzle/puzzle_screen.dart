import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../model/puzzle/puzzle_controller.dart';
import '../../model/puzzle/puzzle_theme.dart';

/// Puzzle tab — Setup panel for theme/difficulty/rated, then navigates to
/// the full-screen puzzle solve screen.
class PuzzleScreen extends ConsumerWidget {
  const PuzzleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(puzzleControllerProvider, (prev, next) {
      final hadPuzzle = prev?.value != null;
      final hasPuzzle = next.value != null;
      if (!hadPuzzle && hasPuzzle) {
        context.go('/puzzles/solve');
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const _PuzzleSetupView(),
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
