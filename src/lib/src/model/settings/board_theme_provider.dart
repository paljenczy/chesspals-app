import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';

const _key = 'board_theme';

enum BoardTheme {
  brown(Color(0xfff0d9b6), Color(0xffb58863)),
  blue(Color(0xffdee3e6), Color(0xff8ca2ad)),
  green(Color(0xffffffdd), Color(0xff86a666)),
  ic(Color(0xffececec), Color(0xffc1c18e));

  const BoardTheme(this.lightSquare, this.darkSquare);

  final Color lightSquare;
  final Color darkSquare;

  String localizedLabel(AppLocalizations l) => switch (this) {
        brown => l.boardThemeBrown,
        blue => l.boardThemeBlue,
        green => l.boardThemeGreen,
        ic => l.boardThemeIce,
      };

  ChessboardColorScheme get colorScheme => switch (this) {
        brown => ChessboardColorScheme.brown,
        blue => ChessboardColorScheme.blue,
        green => ChessboardColorScheme.green,
        ic => ChessboardColorScheme.ic,
      };
}

class BoardThemeNotifier extends Notifier<BoardTheme> {
  @override
  BoardTheme build() {
    _loadPersisted();
    return BoardTheme.brown;
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (name != null && name != state.name) {
      final match = BoardTheme.values.where((t) => t.name == name);
      if (match.isNotEmpty) state = match.first;
    }
  }

  Future<void> setTheme(BoardTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
  }
}

final boardThemeProvider = NotifierProvider<BoardThemeNotifier, BoardTheme>(
  BoardThemeNotifier.new,
);
