import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../model/auth/lichess_account.dart';

/// Root scaffold with 3-tab bottom navigation:
///   🐾 Play Animal | 🧩 Puzzles | 👥 Play Human
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.child});

  final Widget child;

  static const _tabIcons = ['🐾', '🧩', '👥'];
  static const _tabPaths = ['/bot', '/puzzles', '/play'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _tabIndexFor(location);
    final account = ref.watch(accountProvider).value;

    final tabLabels = [l.navPlayBot, l.navPuzzles, l.navPlayHuman];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.appTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          if (account != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _AccountChip(account: account),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.settingsTooltip,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onDestinationSelected: (i) => context.go(_tabPaths[i]),
        destinations: List.generate(
          3,
          (i) => NavigationDestination(
            icon: Text(_tabIcons[i], style: const TextStyle(fontSize: 22)),
            label: tabLabels[i],
          ),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  int _tabIndexFor(String location) {
    if (location.startsWith('/bot')) return 0;
    if (location.startsWith('/puzzles')) return 1;
    if (location.startsWith('/play')) return 2;
    return 0;
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({required this.account});
  final LichessAccount account;

  @override
  Widget build(BuildContext context) {
    final rapid = account.rapidRating;
    final puzzle = account.puzzleRating;
    final parts = <String>[];
    if (rapid != null) parts.add('⚡$rapid');
    if (puzzle != null) parts.add('🧩$puzzle');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        parts.isEmpty ? account.username : '${account.username}  ${parts.join('  ')}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }
}
