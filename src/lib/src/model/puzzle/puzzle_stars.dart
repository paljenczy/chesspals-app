/// Daily puzzle stars and streak tracking.
///
/// Stars are earned for perfect solves (no wrong moves, no viewing solution).
/// Both counters reset at midnight (local time) and persist via SharedPreferences.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyStars = 'puzzle_stars_count';
const _keyStreak = 'puzzle_stars_streak';
const _keyDate = 'puzzle_stars_date';

class PuzzleStarsState {
  const PuzzleStarsState({
    this.stars = 0,
    this.streak = 0,
    this.dateKey = '',
  });

  /// Total stars earned today.
  final int stars;

  /// Current consecutive perfect solves.
  final int streak;

  /// ISO date string (e.g. "2026-04-02") for daily reset detection.
  final String dateKey;

  PuzzleStarsState copyWith({int? stars, int? streak, String? dateKey}) =>
      PuzzleStarsState(
        stars: stars ?? this.stars,
        streak: streak ?? this.streak,
        dateKey: dateKey ?? this.dateKey,
      );
}

class PuzzleStarsNotifier extends Notifier<PuzzleStarsState> {
  late final Future<void> _ready;

  @override
  PuzzleStarsState build() {
    _ready = _loadFromDisk();
    return const PuzzleStarsState();
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_keyDate) ?? '';
    final today = _todayKey();

    if (savedDate == today) {
      state = PuzzleStarsState(
        stars: prefs.getInt(_keyStars) ?? 0,
        streak: prefs.getInt(_keyStreak) ?? 0,
        dateKey: today,
      );
    } else {
      // New day — reset and persist
      state = PuzzleStarsState(dateKey: today);
      await _persist(prefs);
    }
  }

  Future<void> _persist([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    await prefs.setInt(_keyStars, state.stars);
    await prefs.setInt(_keyStreak, state.streak);
    await prefs.setString(_keyDate, state.dateKey);
  }

  /// Called when a puzzle is solved without any wrong moves.
  Future<void> recordPerfectSolve() async {
    await _ready;
    final today = _todayKey();
    state = state.copyWith(
      stars: state.stars + 1,
      streak: state.streak + 1,
      dateKey: today,
    );
    _persist();
  }

  /// Called when a puzzle is solved but the user made wrong moves or viewed solution.
  Future<void> recordImperfectSolve() async {
    await _ready;
    final today = _todayKey();
    state = state.copyWith(
      streak: 0,
      dateKey: today,
    );
    _persist();
  }
}

final puzzleStarsProvider =
    NotifierProvider<PuzzleStarsNotifier, PuzzleStarsState>(
  PuzzleStarsNotifier.new,
);
