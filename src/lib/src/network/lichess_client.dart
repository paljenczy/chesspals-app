/// Lichess API client for ChessPals
///
/// Handles authentication, HTTP requests, and ndjson streaming
/// for all three core features: bot games, puzzles, and human play.

// lib/src/network/lichess_client.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LichessClient {
  static const _baseUrl = 'https://lichess.org';
  static const _tokenKey = 'lichess_token';

  final http.Client _httpClient;
  final FlutterSecureStorage _storage;

  LichessClient({
    http.Client? httpClient,
    FlutterSecureStorage? storage,
  })  : _httpClient = httpClient ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  // ─── Authentication ────────────────────────────────────────────────────────

  Future<String?> get _token => _storage.read(key: _tokenKey);

  /// Returns true if a token is stored.
  Future<bool> get isLoggedIn async => (await _token) != null;

  /// Persists the OAuth token returned after login.
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  /// Clears the stored token (logout).
  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<Map<String, String>> get _authHeaders async {
    final token = await _token;
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  // ─── Account ───────────────────────────────────────────────────────────────

  /// GET /api/account — Returns the logged-in user's public data.
  /// Includes username, perfs (rapid, puzzle ratings).
  Future<Map<String, dynamic>> fetchAccount() async {
    final headers = await _authHeaders;
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/api/account'),
      headers: headers,
    );
    _checkStatus(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Bot Games ─────────────────────────────────────────────────────────────

  /// POST /api/challenge/{username} — Challenge a specific Lichess bot account.
  /// Used for all bot characters (uSunfish-l0, nittedal, maia1, maia5, maia9, etc.)
  /// Requires board:play OAuth scope.
  Future<String> challengeUser({
    required String username,
    String color = 'random',
    int clockLimit = 600,
    int clockIncrement = 5,
    bool rated = false,
  }) async {
    final headers = await _authHeaders;
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/challenge/$username'),
      headers: headers,
      body: {
        'rated': rated.toString(),
        'color': color,
        'clock.limit': clockLimit.toString(),
        'clock.increment': clockIncrement.toString(),
      },
    );
    _checkStatus(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['id'] as String;
  }

  /// GET /api/board/game/stream/{gameId} — Stream game events as ndjson.
  Stream<Map<String, dynamic>> streamGame(String gameId) async* {
    final token = await _token;
    final request = http.Request(
      'GET',
      Uri.parse('$_baseUrl/api/board/game/stream/$gameId'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/x-ndjson';

    final response = await _httpClient.send(request);
    if (response.statusCode == 401) throw LichessAuthException();
    if (response.statusCode == 429) throw LichessRateLimitException();
    if (response.statusCode >= 400) {
      throw LichessApiException(response.statusCode, 'stream error');
    }

    await for (final line in response.stream.toStringStream()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        if (json.containsKey('error')) {
          throw LichessApiException(200, json['error'] as String? ?? 'stream error');
        }
        yield json;
      } on FormatException {
        // Stream may send non-JSON data when closing — ignore it
        continue;
      }
    }
  }

  /// POST /api/board/game/{gameId}/move/{move} — Submit a move in UCI format.
  Future<void> makeMove(String gameId, String move) async {
    final headers = await _authHeaders;
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/board/game/$gameId/move/$move'),
      headers: headers,
    );
    _checkStatus(response);
  }

  /// POST /api/board/game/{gameId}/resign
  Future<void> resign(String gameId) async {
    final headers = await _authHeaders;
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/board/game/$gameId/resign'),
      headers: headers,
    );
    _checkStatus(response);
  }

  /// POST /api/board/game/{gameId}/abort — abort a game before any moves.
  Future<void> abort(String gameId) async {
    final headers = await _authHeaders;
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/board/game/$gameId/abort'),
      headers: headers,
    );
    _checkStatus(response);
  }

  /// POST /api/board/game/{gameId}/draw/yes — Offer or accept a draw.
  Future<void> offerDraw(String gameId) async {
    final headers = await _authHeaders;
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/board/game/$gameId/draw/yes'),
      headers: headers,
    );
    _checkStatus(response);
  }

  /// POST /api/board/game/{gameId}/draw/no — Decline a draw offer.
  Future<void> declineDraw(String gameId) async {
    final headers = await _authHeaders;
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/board/game/$gameId/draw/no'),
      headers: headers,
    );
    _checkStatus(response);
  }

  // ─── Puzzles ───────────────────────────────────────────────────────────────

  /// GET /api/puzzle/daily — No auth required.
  Future<Map<String, dynamic>> fetchDailyPuzzle() async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/api/puzzle/daily'),
    );
    _checkStatus(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /api/puzzle/batch/{angle}?nb={count}&difficulty={difficulty}
  /// Fetch a batch of puzzles filtered by theme and difficulty.
  Future<List<Map<String, dynamic>>> fetchPuzzleBatch(
    String angle, {
    int count = 50,
    String? difficulty,
  }) async {
    final headers = await _authHeaders;
    final params = <String, String>{'nb': count.toString()};
    if (difficulty != null) params['difficulty'] = difficulty;
    final uri = Uri.parse('$_baseUrl/api/puzzle/batch/$angle').replace(queryParameters: params);
    final response = await _httpClient.get(uri, headers: headers);
    _checkStatus(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['puzzles'] as List).cast<Map<String, dynamic>>();
  }

  /// POST /api/puzzle/batch/{angle} — Submit puzzle results.
  Future<void> submitPuzzleResults(
    String angle,
    List<({String id, bool win})> results,
  ) async {
    final headers = await _authHeaders;
    headers['Content-Type'] = 'application/json';
    final body = jsonEncode({
      'solutions': results.map((r) => {'id': r.id, 'win': r.win}).toList(),
    });
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/api/puzzle/batch/$angle'),
      headers: headers,
      body: body,
    );
    _checkStatus(response);
  }

  // ─── Human Matchmaking ─────────────────────────────────────────────────────

  /// POST /api/board/seek — Seek a human opponent.
  /// This is a streaming endpoint — the connection stays open until matched.
  Future<void> seekOpponent({
    int timeMinutes = 10,
    int increment = 5,
    bool rated = false,
    String? ratingRange,
  }) async {
    final token = await _token;
    final seekHeaders = <String, String>{};
    if (token != null) seekHeaders['Authorization'] = 'Bearer $token';
    final body = {
      'rated': rated.toString(),
      'time': timeMinutes.toString(),
      'increment': increment.toString(),
      if (ratingRange != null) 'ratingRange': ratingRange,
    };
    // Fire and forget — this blocks until matched or cancelled
    _httpClient.post(
      Uri.parse('$_baseUrl/api/board/seek'),
      headers: seekHeaders,
      body: body,
    );
  }

  /// GET /api/stream/event — Stream incoming game events.
  Stream<Map<String, dynamic>> streamEvents() async* {
    final token = await _token;
    final request = http.Request(
      'GET',
      Uri.parse('$_baseUrl/api/stream/event'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/x-ndjson';

    final response = await _httpClient.send(request);
    if (response.statusCode == 401) throw LichessAuthException();
    if (response.statusCode >= 400) {
      throw LichessApiException(response.statusCode, 'stream error');
    }

    await for (final line in response.stream.toStringStream()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        yield jsonDecode(trimmed) as Map<String, dynamic>;
      } on FormatException {
        continue;
      }
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _checkStatus(http.Response response) {
    if (response.statusCode == 401) throw LichessAuthException();
    if (response.statusCode == 429) throw LichessRateLimitException();
    if (response.statusCode >= 400) {
      throw LichessApiException(response.statusCode, response.body);
    }
  }

  void dispose() => _httpClient.close();
}

// ─── Exceptions ───────────────────────────────────────────────────────────────

class LichessAuthException implements Exception {
  @override
  String toString() => 'Lichess: authentication failed (token expired?)';
}

class LichessRateLimitException implements Exception {
  @override
  String toString() => 'Lichess: rate limited (429)';
}

class LichessApiException implements Exception {
  final int statusCode;
  final String body;
  LichessApiException(this.statusCode, this.body);

  @override
  String toString() => 'Lichess API error $statusCode: $body';
}
