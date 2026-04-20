import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Shows a game-over dialog with the result and options to go home or review.
///
/// Returns `'home'` or `'analyze'` depending on which button was tapped,
/// or `null` if dismissed.
Future<String?> showGameOverDialog(
  BuildContext context, {
  required String resultText,
  required Color resultColor,
}) {
  final l = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            resultText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: resultColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'home'),
              icon: const Icon(Icons.home_outlined, size: 20),
              label: Text(l.gameOverGoHome),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, 'analyze'),
              icon: const Icon(Icons.search, size: 20),
              label: Text(l.gameOverAnalyze),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
