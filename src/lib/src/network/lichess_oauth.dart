import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Lichess OAuth2 PKCE flow for public clients.
///
/// No app registration or client secret needed — Lichess accepts
/// any client_id for PKCE flows.
class LichessOAuth {
  static const _clientId = 'chesspals';
  static const _redirectUri = 'com.chesspals.chesspals://oauth-callback';
  static const _scope = 'board:play puzzle:read';
  static const _authUrl = 'https://lichess.org/oauth';
  static const _tokenUrl = 'https://lichess.org/api/token';

  late final String _codeVerifier;
  late final String _state;

  LichessOAuth() {
    _codeVerifier = _generateCodeVerifier();
    _state = _generateState();
  }

  /// The authorization URL to open in the browser.
  Uri get authorizationUrl => Uri.parse(_authUrl).replace(
        queryParameters: {
          'response_type': 'code',
          'client_id': _clientId,
          'redirect_uri': _redirectUri,
          'scope': _scope,
          'code_challenge_method': 'S256',
          'code_challenge': _generateCodeChallenge(_codeVerifier),
          'state': _state,
        },
      );

  /// The expected state value — verify this matches the callback.
  String get state => _state;

  /// Exchange the authorization code for an access token.
  Future<String> exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': _codeVerifier,
        'redirect_uri': _redirectUri,
        'client_id': _clientId,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Token exchange failed: ${response.statusCode} ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['access_token'] as String;
  }

  // 64 random URL-safe characters
  static String _generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rng = Random.secure();
    return List.generate(64, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // SHA-256 hash, base64url-encoded, no padding
  static String _generateCodeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  static String _generateState() {
    final rng = Random.secure();
    return List.generate(16, (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
