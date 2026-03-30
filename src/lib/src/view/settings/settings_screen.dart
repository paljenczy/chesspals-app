import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../model/auth/lichess_account.dart';
import '../../model/settings/locale_provider.dart';

/// Settings screen — profile, language picker, app info.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final account = ref.watch(accountProvider).value;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l.settingsTitle),
      ),
      body: ListView(
        children: [
          if (account != null) ...[
            _SectionHeader(title: l.settingsSectionProfile),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.settingsAvatar,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(l.settingsAvatarSub,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  _AvatarPicker(
                    currentIndex: account.avatarIndex,
                    onSelected: (i) => ref
                        .read(accountProvider.notifier)
                        .setAvatar(i),
                  ),
                ],
              ),
            ),
            const Divider(),
          ],
          _SectionHeader(title: l.settingsSectionApp),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.settingsLanguage),
            subtitle: Text(l.settingsLanguageSub),
            trailing: _LanguageToggle(
              currentLocale: locale,
              onChanged: (loc) => ref.read(localeProvider.notifier).setLocale(loc),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.settingsAbout),
            subtitle: Text(l.settingsAboutVersion),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: l.appTitle,
              applicationVersion: l.settingsAboutVersion,
              children: [Text(l.settingsAboutText)],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l.settingsPrivacyPolicy),
            onTap: () {/* TODO: show privacy policy */},
          ),
        ],
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(KidAvatar.all.length, (i) {
        final avatar = KidAvatar.all[i];
        final selected = i == currentIndex;
        return GestureDetector(
          onTap: () => onSelected(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: avatar.bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: ClipOval(
              child: SvgPicture.asset(
                avatar.assetPath,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.currentLocale, required this.onChanged});

  final Locale currentLocale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'en', label: Text(l.settingsLanguageEnglish)),
        ButtonSegment(value: 'hu', label: Text(l.settingsLanguageHungarian)),
      ],
      selected: {currentLocale.languageCode},
      onSelectionChanged: (sel) => onChanged(Locale(sel.first)),
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

