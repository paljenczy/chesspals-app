import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../model/auth/lichess_account.dart';
import '../../network/lichess_oauth.dart';

/// OAuth login screen — "Sign in with Lichess" button triggers PKCE flow.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;
  LichessOAuth? _oauth;
  StreamSubscription<Uri>? _linkSub;

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _startOAuthFlow() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _oauth = LichessOAuth();

      // Listen for the redirect callback
      _linkSub?.cancel();
      final appLinks = AppLinks();
      _linkSub = appLinks.uriLinkStream.listen(
        _handleCallback,
        onError: (_) => _onError(null),
      );

      // Open the Lichess authorization page in the browser
      final url = _oauth!.authorizationUrl;
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _onError(null);
      }
    } catch (e) {
      _onError(e);
    }
  }

  Future<void> _handleCallback(Uri uri) async {
    // Only handle our OAuth callback scheme
    if (uri.scheme != 'com.chesspals.chesspals') return;

    _linkSub?.cancel();

    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];

    if (code == null || state != _oauth?.state) {
      _onError(null);
      return;
    }

    try {
      final token = await _oauth!.exchangeCodeForToken(code);
      await ref.read(accountProvider.notifier).login(token);
      final account = ref.read(accountProvider).value;
      if (account == null) {
        _onError(null);
      } else {
        if (mounted) context.go('/bot');
      }
    } catch (e) {
      _onError(e);
    }
  }

  void _onError(Object? e) {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _loading = false;
      _error = e != null ? l.loginErrorFailed(e.toString()) : l.loginErrorInvalid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text('♟', style: TextStyle(fontSize: 72), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Text(
                l.loginTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l.loginSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _startOAuthFlow,
                  icon: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(_loading ? l.loginSigningIn : l.loginButton),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
