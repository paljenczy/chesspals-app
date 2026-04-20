import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hu')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ChessPals'**
  String get appTitle;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @navPlayBot.
  ///
  /// In en, this message translates to:
  /// **'Play Animal'**
  String get navPlayBot;

  /// No description provided for @navPuzzles.
  ///
  /// In en, this message translates to:
  /// **'Puzzles'**
  String get navPuzzles;

  /// No description provided for @navPlayHuman.
  ///
  /// In en, this message translates to:
  /// **'Play Human'**
  String get navPlayHuman;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ChessPals'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Lichess account to play chess, solve puzzles, and challenge opponents.'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Lichess'**
  String get loginButton;

  /// No description provided for @loginSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loginSigningIn;

  /// No description provided for @loginErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get loginErrorInvalid;

  /// No description provided for @loginErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: {error}'**
  String loginErrorFailed(String error);

  /// No description provided for @botSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your opponent!'**
  String get botSelectTitle;

  /// No description provided for @botSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start easy and work your way up 🌟'**
  String get botSelectSubtitle;

  /// No description provided for @botRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'~{rating} rapid'**
  String botRatingLabel(int rating);

  /// No description provided for @botDifficultyBeginner.
  ///
  /// In en, this message translates to:
  /// **'⭐ Beginner'**
  String get botDifficultyBeginner;

  /// No description provided for @botDifficultyExplorer.
  ///
  /// In en, this message translates to:
  /// **'⭐⭐ Explorer'**
  String get botDifficultyExplorer;

  /// No description provided for @botDifficultySpeedy.
  ///
  /// In en, this message translates to:
  /// **'⭐⭐ Speedy'**
  String get botDifficultySpeedy;

  /// No description provided for @botDifficultyTricky.
  ///
  /// In en, this message translates to:
  /// **'⭐⭐⭐ Tricky'**
  String get botDifficultyTricky;

  /// No description provided for @botDifficultyCunning.
  ///
  /// In en, this message translates to:
  /// **'⭐⭐⭐ Cunning'**
  String get botDifficultyCunning;

  /// No description provided for @botDifficultySharp.
  ///
  /// In en, this message translates to:
  /// **'⭐⭐⭐ Sharp'**
  String get botDifficultySharp;

  /// No description provided for @botDifficultyFierce.
  ///
  /// In en, this message translates to:
  /// **'⭐⭐⭐⭐ Fierce'**
  String get botDifficultyFierce;

  /// No description provided for @botDifficultyFierceplus.
  ///
  /// In en, this message translates to:
  /// **'⭐⭐⭐⭐ Fierce+'**
  String get botDifficultyFierceplus;

  /// No description provided for @botDescBee.
  ///
  /// In en, this message translates to:
  /// **'I\'m just a little bee — I buzz around and make lots of mistakes!'**
  String get botDescBee;

  /// No description provided for @botDescButterfly.
  ///
  /// In en, this message translates to:
  /// **'I flutter around the board — I\'m still finding my wings!'**
  String get botDescButterfly;

  /// No description provided for @botDescHummingbird.
  ///
  /// In en, this message translates to:
  /// **'I move super fast — blink and you\'ll miss my tricks!'**
  String get botDescHummingbird;

  /// No description provided for @botDescRabbit.
  ///
  /// In en, this message translates to:
  /// **'I hop around quickly — watch out, I can be tricky!'**
  String get botDescRabbit;

  /// No description provided for @botDescKangaroo.
  ///
  /// In en, this message translates to:
  /// **'I learn by watching — I\'ll leap ahead when you least expect it!'**
  String get botDescKangaroo;

  /// No description provided for @botDescDeer.
  ///
  /// In en, this message translates to:
  /// **'I play sharp and fast — watch out for my attacks!'**
  String get botDescDeer;

  /// No description provided for @botDescGiraffe.
  ///
  /// In en, this message translates to:
  /// **'I see the whole board from up high — I play like a real person!'**
  String get botDescGiraffe;

  /// No description provided for @botDescTiger.
  ///
  /// In en, this message translates to:
  /// **'I pounce when you make a mistake — can you outsmart me?'**
  String get botDescTiger;

  /// No description provided for @botNameBee.
  ///
  /// In en, this message translates to:
  /// **'Bella the Bee'**
  String get botNameBee;

  /// No description provided for @botNameButterfly.
  ///
  /// In en, this message translates to:
  /// **'Flutter the Butterfly'**
  String get botNameButterfly;

  /// No description provided for @botNameHummingbird.
  ///
  /// In en, this message translates to:
  /// **'Zip the Hummingbird'**
  String get botNameHummingbird;

  /// No description provided for @botNameRabbit.
  ///
  /// In en, this message translates to:
  /// **'Rosie the Rabbit'**
  String get botNameRabbit;

  /// No description provided for @botNameKangaroo.
  ///
  /// In en, this message translates to:
  /// **'Kira the Kangaroo'**
  String get botNameKangaroo;

  /// No description provided for @botNameDeer.
  ///
  /// In en, this message translates to:
  /// **'Dino the Deer'**
  String get botNameDeer;

  /// No description provided for @botNameGiraffe.
  ///
  /// In en, this message translates to:
  /// **'Gabi the Giraffe'**
  String get botNameGiraffe;

  /// No description provided for @botNameTiger.
  ///
  /// In en, this message translates to:
  /// **'Tara the Tiger'**
  String get botNameTiger;

  /// No description provided for @botThinking.
  ///
  /// In en, this message translates to:
  /// **'{name} thinking...'**
  String botThinking(String name);

  /// No description provided for @botGameStatusYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn ♟'**
  String get botGameStatusYourTurn;

  /// No description provided for @botGameStatusBotThinking.
  ///
  /// In en, this message translates to:
  /// **'Bot is thinking...'**
  String get botGameStatusBotThinking;

  /// No description provided for @botGameStatusYouWon.
  ///
  /// In en, this message translates to:
  /// **'You won! 🎉'**
  String get botGameStatusYouWon;

  /// No description provided for @botGameStatusBotWins.
  ///
  /// In en, this message translates to:
  /// **'{name} wins! Try again 💪'**
  String botGameStatusBotWins(String name);

  /// No description provided for @botGameStatusDraw.
  ///
  /// In en, this message translates to:
  /// **'It\'s a draw! 🤝'**
  String get botGameStatusDraw;

  /// No description provided for @botGameButtonResign.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get botGameButtonResign;

  /// No description provided for @botGameButtonNewGame.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get botGameButtonNewGame;

  /// No description provided for @botGameTooltipNewGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get botGameTooltipNewGame;

  /// No description provided for @onlineConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get onlineConnecting;

  /// No description provided for @onlineYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get onlineYourTurn;

  /// No description provided for @onlineYouLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get onlineYouLabel;

  /// No description provided for @onlineOpponentsTurn.
  ///
  /// In en, this message translates to:
  /// **'Opponent\'s turn'**
  String get onlineOpponentsTurn;

  /// No description provided for @onlineResultWin.
  ///
  /// In en, this message translates to:
  /// **'You won! 🎉'**
  String get onlineResultWin;

  /// No description provided for @onlineResultLoss.
  ///
  /// In en, this message translates to:
  /// **'You lost'**
  String get onlineResultLoss;

  /// No description provided for @onlineResultDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get onlineResultDraw;

  /// No description provided for @onlineResultGameOver.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get onlineResultGameOver;

  /// No description provided for @onlineResignTooltip.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get onlineResignTooltip;

  /// No description provided for @onlineResignTitle.
  ///
  /// In en, this message translates to:
  /// **'Resign?'**
  String get onlineResignTitle;

  /// No description provided for @onlineResignContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to give up this game?'**
  String get onlineResignContent;

  /// No description provided for @onlineAbortTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel game?'**
  String get onlineAbortTitle;

  /// No description provided for @onlineAbortContent.
  ///
  /// In en, this message translates to:
  /// **'The game hasn\'t really started yet. Do you want to cancel it?'**
  String get onlineAbortContent;

  /// No description provided for @onlineKeepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get onlineKeepPlaying;

  /// No description provided for @onlineCancelGame.
  ///
  /// In en, this message translates to:
  /// **'Cancel game'**
  String get onlineCancelGame;

  /// No description provided for @onlineResignButton.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get onlineResignButton;

  /// No description provided for @onlineOpponentLabel.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get onlineOpponentLabel;

  /// No description provided for @onlineRapidSuffix.
  ///
  /// In en, this message translates to:
  /// **'rapid'**
  String get onlineRapidSuffix;

  /// No description provided for @onlineConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error:\n{error}'**
  String onlineConnectionError(String error);

  /// No description provided for @onlineRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get onlineRetry;

  /// No description provided for @onlineDrawOfferTooltip.
  ///
  /// In en, this message translates to:
  /// **'Offer draw'**
  String get onlineDrawOfferTooltip;

  /// No description provided for @onlineDrawOfferSent.
  ///
  /// In en, this message translates to:
  /// **'Draw offer sent'**
  String get onlineDrawOfferSent;

  /// No description provided for @onlineDrawOfferReceived.
  ///
  /// In en, this message translates to:
  /// **'Your opponent offers a draw'**
  String get onlineDrawOfferReceived;

  /// No description provided for @onlineDrawAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get onlineDrawAccept;

  /// No description provided for @onlineDrawDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get onlineDrawDecline;

  /// No description provided for @onlineOpponentGoneCountdown.
  ///
  /// In en, this message translates to:
  /// **'Opponent left. You can claim victory in {seconds}s'**
  String onlineOpponentGoneCountdown(int seconds);

  /// No description provided for @onlineOpponentGone.
  ///
  /// In en, this message translates to:
  /// **'Opponent left the game'**
  String get onlineOpponentGone;

  /// No description provided for @onlineClaimVictory.
  ///
  /// In en, this message translates to:
  /// **'Claim Victory'**
  String get onlineClaimVictory;

  /// No description provided for @onlineOfferDrawButton.
  ///
  /// In en, this message translates to:
  /// **'Offer Draw'**
  String get onlineOfferDrawButton;

  /// No description provided for @playHumanTitle.
  ///
  /// In en, this message translates to:
  /// **'Play a Real Person'**
  String get playHumanTitle;

  /// No description provided for @playHumanYourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rapid rating: {rating} ⚡'**
  String playHumanYourRating(int rating);

  /// No description provided for @playHumanChooseTime.
  ///
  /// In en, this message translates to:
  /// **'Choose how much time each player gets'**
  String get playHumanChooseTime;

  /// No description provided for @playHumanTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{label} minutes'**
  String playHumanTimeMinutes(String label);

  /// No description provided for @playHumanDescMedium.
  ///
  /// In en, this message translates to:
  /// **'Fast and fun 🏃'**
  String get playHumanDescMedium;

  /// No description provided for @playHumanDescSlow.
  ///
  /// In en, this message translates to:
  /// **'Take your time and think carefully 🧘'**
  String get playHumanDescSlow;

  /// No description provided for @playHumanDescDeep.
  ///
  /// In en, this message translates to:
  /// **'Plenty of time to think deeply 🌳'**
  String get playHumanDescDeep;

  /// No description provided for @playHumanRated.
  ///
  /// In en, this message translates to:
  /// **'Rated'**
  String get playHumanRated;

  /// No description provided for @playHumanUnrated.
  ///
  /// In en, this message translates to:
  /// **'Unrated'**
  String get playHumanUnrated;

  /// No description provided for @playHumanRatedNote.
  ///
  /// In en, this message translates to:
  /// **'Rated games affect your Lichess rapid rating.'**
  String get playHumanRatedNote;

  /// No description provided for @playHumanUnratedNote.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be matched with another player around your skill level. Unrated games only.'**
  String get playHumanUnratedNote;

  /// No description provided for @playHumanSeeking.
  ///
  /// In en, this message translates to:
  /// **'Finding an opponent...'**
  String get playHumanSeeking;

  /// No description provided for @playHumanSeekingNote.
  ///
  /// In en, this message translates to:
  /// **'This usually takes less than 30 seconds'**
  String get playHumanSeekingNote;

  /// No description provided for @playHumanCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get playHumanCancel;

  /// No description provided for @playHumanErrorLogin.
  ///
  /// In en, this message translates to:
  /// **'You need to log in to play against real people.'**
  String get playHumanErrorLogin;

  /// No description provided for @playHumanErrorConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check your internet and try again.'**
  String get playHumanErrorConnect;

  /// No description provided for @playHumanTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get playHumanTryAgain;

  /// No description provided for @puzzleDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'✨ Daily Puzzle'**
  String get puzzleDailyTitle;

  /// No description provided for @puzzleTitle.
  ///
  /// In en, this message translates to:
  /// **'🧩 Puzzle #{id}'**
  String puzzleTitle(String id);

  /// No description provided for @puzzleWhiteToMove.
  ///
  /// In en, this message translates to:
  /// **'White to move — find the best move!'**
  String get puzzleWhiteToMove;

  /// No description provided for @puzzleBlackToMove.
  ///
  /// In en, this message translates to:
  /// **'Black to move — find the best move!'**
  String get puzzleBlackToMove;

  /// No description provided for @puzzleCorrect.
  ///
  /// In en, this message translates to:
  /// **'Best move! 🎉'**
  String get puzzleCorrect;

  /// No description provided for @puzzleWrong.
  ///
  /// In en, this message translates to:
  /// **'That\'s not it — try again! 💪'**
  String get puzzleWrong;

  /// No description provided for @puzzleSolved.
  ///
  /// In en, this message translates to:
  /// **'Puzzle complete! 🏆'**
  String get puzzleSolved;

  /// No description provided for @puzzleHint.
  ///
  /// In en, this message translates to:
  /// **'Get a hint'**
  String get puzzleHint;

  /// No description provided for @puzzleViewSolution.
  ///
  /// In en, this message translates to:
  /// **'View solution'**
  String get puzzleViewSolution;

  /// No description provided for @puzzleContinueTraining.
  ///
  /// In en, this message translates to:
  /// **'Continue Training'**
  String get puzzleContinueTraining;

  /// No description provided for @puzzleViewingSolution.
  ///
  /// In en, this message translates to:
  /// **'Showing solution...'**
  String get puzzleViewingSolution;

  /// No description provided for @puzzleSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Solve Puzzles'**
  String get puzzleSetupTitle;

  /// No description provided for @puzzleErrorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.\nCheck your Wi-Fi and try again!'**
  String get puzzleErrorNoInternet;

  /// No description provided for @puzzleErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.\nPlease try again.'**
  String get puzzleErrorGeneric;

  /// No description provided for @puzzleTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get puzzleTryAgain;

  /// No description provided for @puzzleCategoryMeta.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get puzzleCategoryMeta;

  /// No description provided for @puzzleCategoryTactics.
  ///
  /// In en, this message translates to:
  /// **'Tactics'**
  String get puzzleCategoryTactics;

  /// No description provided for @puzzleCategoryCheckmates.
  ///
  /// In en, this message translates to:
  /// **'Checkmate Patterns'**
  String get puzzleCategoryCheckmates;

  /// No description provided for @puzzleCategoryPhases.
  ///
  /// In en, this message translates to:
  /// **'Game Phases'**
  String get puzzleCategoryPhases;

  /// No description provided for @puzzleCategoryEndgameTypes.
  ///
  /// In en, this message translates to:
  /// **'Endgame Types'**
  String get puzzleCategoryEndgameTypes;

  /// No description provided for @puzzleCategoryGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get puzzleCategoryGoals;

  /// No description provided for @puzzleCategorySpecialMoves.
  ///
  /// In en, this message translates to:
  /// **'Special Moves'**
  String get puzzleCategorySpecialMoves;

  /// No description provided for @puzzleCategoryLength.
  ///
  /// In en, this message translates to:
  /// **'Puzzle Length'**
  String get puzzleCategoryLength;

  /// No description provided for @puzzleCategoryAttackSide.
  ///
  /// In en, this message translates to:
  /// **'Attack Side'**
  String get puzzleCategoryAttackSide;

  /// No description provided for @puzzleCategoryOrigin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get puzzleCategoryOrigin;

  /// No description provided for @puzzleDifficultyEasiest.
  ///
  /// In en, this message translates to:
  /// **'Easiest'**
  String get puzzleDifficultyEasiest;

  /// No description provided for @puzzleDifficultyEasier.
  ///
  /// In en, this message translates to:
  /// **'Easier'**
  String get puzzleDifficultyEasier;

  /// No description provided for @puzzleDifficultyNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get puzzleDifficultyNormal;

  /// No description provided for @puzzleDifficultyHarder.
  ///
  /// In en, this message translates to:
  /// **'Harder'**
  String get puzzleDifficultyHarder;

  /// No description provided for @puzzleDifficultyHardest.
  ///
  /// In en, this message translates to:
  /// **'Hardest'**
  String get puzzleDifficultyHardest;

  /// No description provided for @puzzleRated.
  ///
  /// In en, this message translates to:
  /// **'Rated'**
  String get puzzleRated;

  /// No description provided for @puzzleUnrated.
  ///
  /// In en, this message translates to:
  /// **'Unrated'**
  String get puzzleUnrated;

  /// No description provided for @puzzleRatedNote.
  ///
  /// In en, this message translates to:
  /// **'Rated puzzles affect your Lichess puzzle rating.'**
  String get puzzleRatedNote;

  /// No description provided for @puzzleUnratedNote.
  ///
  /// In en, this message translates to:
  /// **'Practice mode — your rating won\'t change.'**
  String get puzzleUnratedNote;

  /// No description provided for @puzzleStartTraining.
  ///
  /// In en, this message translates to:
  /// **'Start Training'**
  String get puzzleStartTraining;

  /// No description provided for @puzzleTopicLabel.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get puzzleTopicLabel;

  /// No description provided for @puzzleSelectTopic.
  ///
  /// In en, this message translates to:
  /// **'Select a topic'**
  String get puzzleSelectTopic;

  /// No description provided for @puzzleDifficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get puzzleDifficultyLabel;

  /// No description provided for @puzzleChangeSettings.
  ///
  /// In en, this message translates to:
  /// **'Change Settings'**
  String get puzzleChangeSettings;

  /// No description provided for @puzzleStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} in a row'**
  String puzzleStreakLabel(int count);

  /// No description provided for @puzzleStreakStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start a streak!'**
  String get puzzleStreakStart;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsSectionApp;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About ChessPals'**
  String get settingsAbout;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get settingsAboutVersion;

  /// No description provided for @settingsAboutText.
  ///
  /// In en, this message translates to:
  /// **'A kid-friendly chess app. Bot play uses the open-source Stockfish engine. Online puzzles and matchmaking use the Lichess API.'**
  String get settingsAboutText;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSub.
  ///
  /// In en, this message translates to:
  /// **'English / Magyar'**
  String get settingsLanguageSub;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageHungarian.
  ///
  /// In en, this message translates to:
  /// **'Magyar'**
  String get settingsLanguageHungarian;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsLogoutCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsLogoutCancel;

  /// No description provided for @settingsLogoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogoutButton;

  /// No description provided for @settingsSectionProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsSectionProfile;

  /// No description provided for @settingsAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar'**
  String get settingsAvatar;

  /// No description provided for @settingsAvatarSub.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick your character'**
  String get settingsAvatarSub;

  /// No description provided for @gameOverGoHome.
  ///
  /// In en, this message translates to:
  /// **'Main Menu'**
  String get gameOverGoHome;

  /// No description provided for @gameOverAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Review Game'**
  String get gameOverAnalyze;

  /// No description provided for @analysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Review'**
  String get analysisTitle;

  /// No description provided for @analysisMoveCounter.
  ///
  /// In en, this message translates to:
  /// **'Move {current} of {total}'**
  String analysisMoveCounter(int current, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
