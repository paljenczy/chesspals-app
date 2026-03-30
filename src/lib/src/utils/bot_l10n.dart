import '../../../l10n/app_localizations.dart';
import '../model/bot/bot_character.dart';

int roundedRating(int rating) => (rating / 10).round() * 10;

String localizedBotName(AppLocalizations l, BotCharacter c) => switch (c) {
      BotCharacter.bee => l.botNameBee,
      BotCharacter.butterfly => l.botNameButterfly,
      BotCharacter.hummingbird => l.botNameHummingbird,
      BotCharacter.rabbit => l.botNameRabbit,
      BotCharacter.kangaroo => l.botNameKangaroo,
      BotCharacter.deer => l.botNameDeer,
      BotCharacter.giraffe => l.botNameGiraffe,
      BotCharacter.tiger => l.botNameTiger,
    };

String localizedBotDifficulty(AppLocalizations l, BotCharacter c) => switch (c) {
      BotCharacter.bee => l.botDifficultyBeginner,
      BotCharacter.butterfly => l.botDifficultyExplorer,
      BotCharacter.hummingbird => l.botDifficultySpeedy,
      BotCharacter.rabbit => l.botDifficultyTricky,
      BotCharacter.kangaroo => l.botDifficultyCunning,
      BotCharacter.deer => l.botDifficultySharp,
      BotCharacter.giraffe => l.botDifficultyFierce,
      BotCharacter.tiger => l.botDifficultyFierceplus,
    };

String localizedBotDescription(AppLocalizations l, BotCharacter c) => switch (c) {
      BotCharacter.bee => l.botDescBee,
      BotCharacter.butterfly => l.botDescButterfly,
      BotCharacter.hummingbird => l.botDescHummingbird,
      BotCharacter.rabbit => l.botDescRabbit,
      BotCharacter.kangaroo => l.botDescKangaroo,
      BotCharacter.deer => l.botDescDeer,
      BotCharacter.giraffe => l.botDescGiraffe,
      BotCharacter.tiger => l.botDescTiger,
    };
