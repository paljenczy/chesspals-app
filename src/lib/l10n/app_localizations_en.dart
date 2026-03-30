// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ChessPals';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get navPlayBot => 'Play Animal';

  @override
  String get navPuzzles => 'Puzzles';

  @override
  String get navPlayHuman => 'Play Human';

  @override
  String get loginTitle => 'Welcome to ChessPals';

  @override
  String get loginSubtitle =>
      'Sign in with your Lichess account to play chess, solve puzzles, and challenge opponents.';

  @override
  String get loginButton => 'Sign in with Lichess';

  @override
  String get loginSigningIn => 'Signing in...';

  @override
  String get loginErrorInvalid => 'Sign-in failed. Please try again.';

  @override
  String loginErrorFailed(String error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get botSelectTitle => 'Choose your opponent!';

  @override
  String get botSelectSubtitle => 'Start easy and work your way up 🌟';

  @override
  String get botErrorLoginRequired => 'Login required';

  @override
  String get botErrorCouldNotStart => 'Could not start game';

  @override
  String botRatingLabel(int rating) {
    return '~$rating rapid';
  }

  @override
  String get botDifficultyBeginner => '⭐ Beginner';

  @override
  String get botDifficultyExplorer => '⭐⭐ Explorer';

  @override
  String get botDifficultySpeedy => '⭐⭐ Speedy';

  @override
  String get botDifficultyTricky => '⭐⭐⭐ Tricky';

  @override
  String get botDifficultyCunning => '⭐⭐⭐ Cunning';

  @override
  String get botDifficultySharp => '⭐⭐⭐ Sharp';

  @override
  String get botDifficultyFierce => '⭐⭐⭐⭐ Fierce';

  @override
  String get botDifficultyFierceplus => '⭐⭐⭐⭐ Fierce+';

  @override
  String get botDescBee =>
      'I\'m just a little bee — I buzz around and make lots of mistakes!';

  @override
  String get botDescButterfly =>
      'I flutter around the board — I\'m still finding my wings!';

  @override
  String get botDescHummingbird =>
      'I move super fast — blink and you\'ll miss my tricks!';

  @override
  String get botDescRabbit =>
      'I hop around quickly — watch out, I can be tricky!';

  @override
  String get botDescKangaroo =>
      'I learn by watching — I\'ll leap ahead when you least expect it!';

  @override
  String get botDescDeer => 'I play sharp and fast — watch out for my attacks!';

  @override
  String get botDescGiraffe =>
      'I see the whole board from up high — I play like a real person!';

  @override
  String get botDescTiger =>
      'I pounce when you make a mistake — can you outsmart me?';

  @override
  String get botNameBee => 'Bella the Bee';

  @override
  String get botNameButterfly => 'Flutter the Butterfly';

  @override
  String get botNameHummingbird => 'Zip the Hummingbird';

  @override
  String get botNameRabbit => 'Rosie the Rabbit';

  @override
  String get botNameKangaroo => 'Kira the Kangaroo';

  @override
  String get botNameDeer => 'Dino the Deer';

  @override
  String get botNameGiraffe => 'Gabi the Giraffe';

  @override
  String get botNameTiger => 'Tara the Tiger';

  @override
  String botThinking(String name) {
    return '$name thinking...';
  }

  @override
  String get offlineStatusYourTurn => 'Your turn ♟';

  @override
  String get offlineStatusBotThinking => 'Bot is thinking...';

  @override
  String get offlineStatusYouWon => 'You won! 🎉';

  @override
  String get offlineStatusBotWins => 'Bot wins! Try again 💪';

  @override
  String get offlineStatusDraw => 'It\'s a draw! 🤝';

  @override
  String get offlineButtonResign => 'Resign';

  @override
  String get offlineButtonNewGame => 'New Game';

  @override
  String get offlineTooltipNewGame => 'New game';

  @override
  String get onlineConnecting => 'Connecting...';

  @override
  String get onlineYourTurn => 'Your turn';

  @override
  String get onlineYouLabel => 'You';

  @override
  String onlineOpponentThinking(String name) {
    return '$name thinking...';
  }

  @override
  String get onlineOpponentsTurn => 'Opponent\'s turn';

  @override
  String get onlineResultWin => 'You won! 🎉';

  @override
  String get onlineResultLoss => 'You lost';

  @override
  String get onlineResultDraw => 'Draw';

  @override
  String get onlineResultGameOver => 'Game over';

  @override
  String get onlineResignTooltip => 'Resign';

  @override
  String get onlineResignTitle => 'Resign?';

  @override
  String get onlineResignContent =>
      'Are you sure you want to give up this game?';

  @override
  String get onlineAbortTitle => 'Cancel game?';

  @override
  String get onlineAbortContent =>
      'The game hasn\'t really started yet. Do you want to cancel it?';

  @override
  String get onlineKeepPlaying => 'Keep playing';

  @override
  String get onlineCancelGame => 'Cancel game';

  @override
  String get onlineResignButton => 'Resign';

  @override
  String get onlinePlayAgain => 'Play Again';

  @override
  String get onlineYourTurnBadge => 'Your turn';

  @override
  String get onlineOpponentLabel => 'Opponent';

  @override
  String get onlineRapidSuffix => 'rapid';

  @override
  String onlineConnectionError(String error) {
    return 'Connection error:\n$error';
  }

  @override
  String get onlineRetry => 'Retry';

  @override
  String get onlineDrawOfferTooltip => 'Offer draw';

  @override
  String get onlineDrawOfferSent => 'Draw offer sent';

  @override
  String get onlineDrawOfferReceived => 'Your opponent offers a draw';

  @override
  String get onlineDrawAccept => 'Accept';

  @override
  String get onlineDrawDecline => 'Decline';

  @override
  String get playHumanTitle => 'Play a Real Person';

  @override
  String playHumanYourRating(int rating) {
    return 'Your rapid rating: $rating ⚡';
  }

  @override
  String get playHumanChooseTime => 'Choose how much time each player gets';

  @override
  String playHumanTimeMinutes(String label) {
    return '$label minutes';
  }

  @override
  String get playHumanDescFast => 'Super fast! Think quickly ⚡';

  @override
  String get playHumanDescMedium => 'Fast and fun 🏃';

  @override
  String get playHumanDescSlow => 'Take your time and think carefully 🧘';

  @override
  String get playHumanDescDeep => 'Plenty of time to think deeply 🌳';

  @override
  String get playHumanRated => 'Rated';

  @override
  String get playHumanUnrated => 'Unrated';

  @override
  String get playHumanRatedNote =>
      'Rated games affect your Lichess rapid rating.';

  @override
  String get playHumanUnratedNote =>
      'You\'ll be matched with another player around your skill level. Unrated games only.';

  @override
  String get playHumanSeeking => 'Finding an opponent...';

  @override
  String get playHumanSeekingNote => 'This usually takes less than 30 seconds';

  @override
  String get playHumanCancel => 'Cancel';

  @override
  String get playHumanErrorLogin =>
      'You need to log in to play against real people.';

  @override
  String get playHumanErrorConnect =>
      'Could not connect. Check your internet and try again.';

  @override
  String get playHumanTryAgain => 'Try Again';

  @override
  String get puzzleDailyTitle => '✨ Daily Puzzle';

  @override
  String puzzleTitle(String id) {
    return '🧩 Puzzle #$id';
  }

  @override
  String get puzzleWhiteToMove => 'White to move — find the best move!';

  @override
  String get puzzleBlackToMove => 'Black to move — find the best move!';

  @override
  String get puzzleCorrect => 'Best move! 🎉';

  @override
  String get puzzleWrong => 'That\'s not it — try again! 💪';

  @override
  String get puzzleSolved => 'Puzzle complete! 🏆';

  @override
  String get puzzleHint => 'Get a hint';

  @override
  String get puzzleViewSolution => 'View solution';

  @override
  String get puzzleContinueTraining => 'Continue Training';

  @override
  String get puzzleViewingSolution => 'Showing solution...';

  @override
  String get puzzleButtonDaily => 'Daily';

  @override
  String get puzzleButtonNext => 'Next Puzzle';

  @override
  String get puzzleButtonLoad => 'Load Daily Puzzle';

  @override
  String get puzzleButtonRandom => 'Random Puzzle';

  @override
  String get puzzleReadyText => 'Ready to solve puzzles?';

  @override
  String get puzzleErrorNoInternet =>
      'No internet connection.\nCheck your Wi-Fi and try again!';

  @override
  String get puzzleErrorGeneric => 'Something went wrong.\nPlease try again.';

  @override
  String get puzzleTryAgain => 'Try Again';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsAbout => 'About ChessPals';

  @override
  String get settingsAboutVersion => 'Version 1.0.0';

  @override
  String get settingsAboutText =>
      'A kid-friendly chess app. Bot play uses the open-source Stockfish engine. Online puzzles and matchmaking use the Lichess API.';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSub => 'English / Magyar';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageHungarian => 'Magyar';

  @override
  String get settingsSectionProfile => 'Profile';

  @override
  String get settingsAvatar => 'Choose Avatar';

  @override
  String get settingsAvatarSub => 'Tap to pick your character';

  @override
  String get gameOverGoHome => 'Main Menu';

  @override
  String get gameOverAnalyze => 'Review Game';

  @override
  String get analysisTitle => 'Game Review';

  @override
  String analysisMoveCounter(int current, int total) {
    return 'Move $current of $total';
  }
}
