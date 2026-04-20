import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../model/bot/bot_character.dart';
import '../../network/lichess_client.dart';
import '../../utils/bot_l10n.dart';

/// 8-animal grid. Tapping starts a bot game at the matching level.
class KidBotSelectScreen extends StatelessWidget {
  const KidBotSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                l.botSelectTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                l.botSelectSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: BotCharacter.values.length,
                itemBuilder: (context, index) => _BotCard(
                  character: BotCharacter.values[index],
                  index: index,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotCard extends StatefulWidget {
  const _BotCard({required this.character, required this.index});
  final BotCharacter character;
  final int index;

  @override
  State<_BotCard> createState() => _BotCardState();
}

class _BotCardState extends State<_BotCard> {
  bool _loading = false;

  Future<void> _challenge() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final service = BotService(LichessClient());
      final gameId = await service.challengeBot(widget.character);
      if (!mounted) return;
      context.go('/game/$gameId?side=white&from=bot&char=${widget.index}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not challenge bot: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final character = widget.character;
    final cardColor = Color(character.colorHex).withValues(alpha: 0.12);
    final borderColor = Color(character.colorHex).withValues(alpha: 0.5);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 2),
      ),
      color: cardColor,
      child: InkWell(
        onTap: _loading ? null : _challenge,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              character.hasPngEmotions
                  ? Image.asset(character.emotionAsset(null), width: 100, height: 100, fit: BoxFit.contain)
                  : SvgPicture.asset(character.emotionAsset(null), width: 100, height: 100),
              const SizedBox(height: 6),
              Text(
                localizedBotName(l, character),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                localizedBotDifficulty(l, character),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                l.botRatingLabel(roundedRating(character.approxRating)),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                localizedBotDescription(l, character),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
