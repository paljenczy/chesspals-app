// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'SakkBarátok';

  @override
  String get settingsTooltip => 'Beállítások';

  @override
  String get navPlayBot => 'Sakkozz állattal';

  @override
  String get navPuzzles => 'Feladványok';

  @override
  String get navPlayHuman => 'Ember ellen';

  @override
  String get loginTitle => 'Üdvözöl a SakkBarátok';

  @override
  String get loginSubtitle =>
      'Jelentkezz be a Lichess fiókoddal a sakkozáshoz, feladványokhoz és az online játékhoz.';

  @override
  String get loginButton => 'Bejelentkezés Lichess-szel';

  @override
  String get loginSigningIn => 'Bejelentkezés...';

  @override
  String get loginErrorInvalid => 'A bejelentkezés sikertelen. Próbáld újra.';

  @override
  String loginErrorFailed(String error) {
    return 'Bejelentkezés sikertelen: $error';
  }

  @override
  String get botSelectTitle => 'Válassz ellenfelet!';

  @override
  String get botSelectSubtitle => 'Kezdd könnyűvel és haladj felfelé 🌟';

  @override
  String get botErrorLoginRequired => 'Bejelentkezés szükséges';

  @override
  String get botErrorCouldNotStart => 'Nem sikerült elindítani a játékot';

  @override
  String botRatingLabel(int rating) {
    return '~$rating gyors';
  }

  @override
  String get botDifficultyBeginner => '⭐ Kezdő';

  @override
  String get botDifficultyExplorer => '⭐⭐ Felfedező';

  @override
  String get botDifficultySpeedy => '⭐⭐ Sebesen';

  @override
  String get botDifficultyTricky => '⭐⭐⭐ Ravaszdi';

  @override
  String get botDifficultyCunning => '⭐⭐⭐ Ravasz';

  @override
  String get botDifficultySharp => '⭐⭐⭐ Éles';

  @override
  String get botDifficultyFierce => '⭐⭐⭐⭐ Vadász';

  @override
  String get botDifficultyFierceplus => '⭐⭐⭐⭐ Vadász+';

  @override
  String get botDescBee =>
      'Csak egy kis méhecske vagyok — buzgón röpülök és sok hibát követek el!';

  @override
  String get botDescButterfly =>
      'Libbenve szállok a táblán — még épp csak szárnyra kapok!';

  @override
  String get botDescHummingbird =>
      'Villámgyorsan mozgok — pislogj, és lemaradsz a trükkjeimről!';

  @override
  String get botDescRabbit =>
      'Szökhetek ide-oda — vigyázz, tudok ravasz lenni!';

  @override
  String get botDescKangaroo =>
      'Figyeléssel tanulok — előre ugrok, mikor nem számítasz rá!';

  @override
  String get botDescDeer =>
      'Gyorsan és éleszen játszom — vigyázz a támadásaimra!';

  @override
  String get botDescGiraffe =>
      'Felülről látom az egész táblát — úgy játszom, mint egy igazi ember!';

  @override
  String get botDescTiger => 'Lecsapok, ha hibázol — le tudsz győzni?';

  @override
  String get botNameBee => 'Bella a Méhecske';

  @override
  String get botNameButterfly => 'Pillangó Peti';

  @override
  String get botNameHummingbird => 'Zümi a Kolibri';

  @override
  String get botNameRabbit => 'Nyuszi Rozi';

  @override
  String get botNameKangaroo => 'Kira a Kenguru';

  @override
  String get botNameDeer => 'Ödön az Őzike';

  @override
  String get botNameGiraffe => 'Zsuzsi a Zsiráf';

  @override
  String get botNameTiger => 'Tara a Tigris';

  @override
  String botThinking(String name) {
    return '$name gondolkodik...';
  }

  @override
  String get botGameStatusYourTurn => 'Te jössz ♟';

  @override
  String get botGameStatusBotThinking => 'A bot gondolkodik...';

  @override
  String get botGameStatusYouWon => 'Nyertél! 🎉';

  @override
  String get botGameStatusBotWins => 'A bot nyert! Próbáld újra 💪';

  @override
  String get botGameStatusDraw => 'Döntetlen! 🤝';

  @override
  String get botGameButtonResign => 'Feladás';

  @override
  String get botGameButtonNewGame => 'Új játék';

  @override
  String get botGameTooltipNewGame => 'Új játék';

  @override
  String get onlineConnecting => 'Csatlakozás...';

  @override
  String get onlineYourTurn => 'Te jössz';

  @override
  String get onlineYouLabel => 'Te';

  @override
  String onlineOpponentThinking(String name) {
    return '$name gondolkodik...';
  }

  @override
  String get onlineOpponentsTurn => 'Az ellenfél lép';

  @override
  String get onlineResultWin => 'Nyertél! 🎉';

  @override
  String get onlineResultLoss => 'Vesztettél';

  @override
  String get onlineResultDraw => 'Döntetlen';

  @override
  String get onlineResultGameOver => 'Játék vége';

  @override
  String get onlineResignTooltip => 'Feladás';

  @override
  String get onlineResignTitle => 'Feladod?';

  @override
  String get onlineResignContent => 'Biztosan fel akarod adni ezt a játékot?';

  @override
  String get onlineAbortTitle => 'Mérkőzés megszakítása?';

  @override
  String get onlineAbortContent =>
      'A játék még nem igazán kezdődött el. Meg akarod szakítani?';

  @override
  String get onlineKeepPlaying => 'Folytatom';

  @override
  String get onlineCancelGame => 'Mérkőzés megszakítása';

  @override
  String get onlineResignButton => 'Feladom';

  @override
  String get onlinePlayAgain => 'Újrajátszás';

  @override
  String get onlineYourTurnBadge => 'Te jössz';

  @override
  String get onlineOpponentLabel => 'Ellenfél';

  @override
  String get onlineRapidSuffix => 'gyors';

  @override
  String onlineConnectionError(String error) {
    return 'Kapcsolódási hiba:\n$error';
  }

  @override
  String get onlineRetry => 'Újrapróbálás';

  @override
  String get onlineDrawOfferTooltip => 'Döntetlen ajánlása';

  @override
  String get onlineDrawOfferSent => 'Döntetlen ajánlat elküldve';

  @override
  String get onlineDrawOfferReceived => 'Az ellenfeled döntetlent ajánl';

  @override
  String get onlineDrawAccept => 'Elfogadom';

  @override
  String get onlineDrawDecline => 'Elutasítom';

  @override
  String get playHumanTitle => 'Játssz egy valódi személlyel';

  @override
  String playHumanYourRating(int rating) {
    return 'Gyors értékelésed: $rating ⚡';
  }

  @override
  String get playHumanChooseTime =>
      'Válaszd meg, mennyi idő jusson minden játékosnak';

  @override
  String playHumanTimeMinutes(String label) {
    return '$label perc';
  }

  @override
  String get playHumanDescFast => 'Villámgyors! Gondolkodj gyorsan ⚡';

  @override
  String get playHumanDescMedium => 'Gyors és szórakoztató 🏃';

  @override
  String get playHumanDescSlow => 'Végy időt és gondolkodj alaposan 🧘';

  @override
  String get playHumanDescDeep => 'Bőven van idő az alapos gondolkodásra 🌳';

  @override
  String get playHumanRated => 'Értékelt';

  @override
  String get playHumanUnrated => 'Nem értékelt';

  @override
  String get playHumanRatedNote =>
      'Az értékelt játékok befolyásolják a Lichess értékelésedet.';

  @override
  String get playHumanUnratedNote =>
      'Hasonló szintű játékossal fogjuk összepárosítani. Csak értékelés nélküli játékok.';

  @override
  String get playHumanSeeking => 'Ellenfelet keresünk...';

  @override
  String get playHumanSeekingNote =>
      'Ez általában kevesebb mint 30 másodpercig tart';

  @override
  String get playHumanCancel => 'Mégse';

  @override
  String get playHumanErrorLogin =>
      'Be kell jelentkezned, hogy valódi emberek ellen játszhass.';

  @override
  String get playHumanErrorConnect =>
      'Nem sikerült csatlakozni. Ellenőrizd az internetkapcsolatod és próbáld újra.';

  @override
  String get playHumanTryAgain => 'Újrapróbálás';

  @override
  String get puzzleDailyTitle => '✨ Napi feladány';

  @override
  String puzzleTitle(String id) {
    return '🧩 Feladány #$id';
  }

  @override
  String get puzzleWhiteToMove => 'A fehér lép — találd meg a legjobb lépést!';

  @override
  String get puzzleBlackToMove => 'A fekete lép — találd meg a legjobb lépést!';

  @override
  String get puzzleCorrect => 'Legjobb lépés! 🎉';

  @override
  String get puzzleWrong => 'Ez nem az — próbáld újra! 💪';

  @override
  String get puzzleSolved => 'Feladány megoldva! 🏆';

  @override
  String get puzzleHint => 'Segítség kérése';

  @override
  String get puzzleViewSolution => 'Megoldás';

  @override
  String get puzzleContinueTraining => 'Következő feladány';

  @override
  String get puzzleViewingSolution => 'Megoldás mutatása...';

  @override
  String get puzzleButtonDaily => 'Napi';

  @override
  String get puzzleButtonNext => 'Következő feladány';

  @override
  String get puzzleButtonLoad => 'Napi feladány betöltése';

  @override
  String get puzzleButtonRandom => 'Véletlenszerű feladány';

  @override
  String get puzzleReadyText => 'Készen állsz feladványok megoldására?';

  @override
  String get puzzleSetupTitle => 'Feladványok';

  @override
  String get puzzleErrorNoInternet =>
      'Nincs internetkapcsolat.\nEllenőrizd a Wi-Fi-t és próbáld újra!';

  @override
  String get puzzleErrorGeneric => 'Valami hiba történt.\nKérlek próbáld újra.';

  @override
  String get puzzleTryAgain => 'Újrapróbálás';

  @override
  String get puzzleCategoryMeta => 'Ajánlott';

  @override
  String get puzzleCategoryTactics => 'Taktikák';

  @override
  String get puzzleCategoryCheckmates => 'Mattminták';

  @override
  String get puzzleCategoryPhases => 'Játékfázisok';

  @override
  String get puzzleCategoryEndgameTypes => 'Végjátéktípusok';

  @override
  String get puzzleCategoryGoals => 'Célok';

  @override
  String get puzzleCategorySpecialMoves => 'Különleges lépések';

  @override
  String get puzzleCategoryLength => 'Feladvány hossza';

  @override
  String get puzzleCategoryAttackSide => 'Támadási oldal';

  @override
  String get puzzleCategoryOrigin => 'Eredet';

  @override
  String get puzzleDifficultyEasiest => 'Legkönnyebb';

  @override
  String get puzzleDifficultyEasier => 'Könnyebb';

  @override
  String get puzzleDifficultyNormal => 'Normál';

  @override
  String get puzzleDifficultyHarder => 'Nehezebb';

  @override
  String get puzzleDifficultyHardest => 'Legnehezebb';

  @override
  String get puzzleRated => 'Értékelt';

  @override
  String get puzzleUnrated => 'Nem értékelt';

  @override
  String get puzzleRatedNote =>
      'Az értékelt feladványok befolyásolják a Lichess feladvány-értékelésedet.';

  @override
  String get puzzleUnratedNote =>
      'Gyakorlás mód — az értékelésed nem változik.';

  @override
  String get puzzleStartTraining => 'Gyakorlás indítása';

  @override
  String get puzzleTopicLabel => 'Téma';

  @override
  String get puzzleSelectTopic => 'Téma kiválasztása';

  @override
  String get puzzleDifficultyLabel => 'Nehézség';

  @override
  String get puzzleChangeSettings => 'Beállítások módosítása';

  @override
  String puzzleStreakLabel(int count) {
    return '$count egymás után';
  }

  @override
  String get puzzleStreakStart => 'Kezdjünk egy sorozatot!';

  @override
  String get settingsTitle => 'Beállítások';

  @override
  String get settingsSectionApp => 'Alkalmazás';

  @override
  String get settingsAbout => 'A SakkBarátokról';

  @override
  String get settingsAboutVersion => '1.0.0 verzió';

  @override
  String get settingsAboutText =>
      'Egy gyerekbarát sakk alkalmazás. A bot játék a nyílt forráskódú Stockfish motort használja. Az online feladványok és párosítás a Lichess API-t használja.';

  @override
  String get settingsPrivacyPolicy => 'Adatvédelmi irányelvek';

  @override
  String get settingsLanguage => 'Nyelv';

  @override
  String get settingsLanguageSub => 'English / Magyar';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageHungarian => 'Magyar';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsAvatar => 'Válassz avatárt';

  @override
  String get settingsAvatarSub => 'Koppints a karaktered kiválasztásához';

  @override
  String get gameOverGoHome => 'Kezdőlap';

  @override
  String get gameOverAnalyze => 'Játék áttekintése';

  @override
  String get analysisTitle => 'Játék áttekintése';

  @override
  String analysisMoveCounter(int current, int total) {
    return '$current. lépés / $total';
  }
}
