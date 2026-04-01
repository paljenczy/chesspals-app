import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../network/lichess_client.dart';

/// Lichess user account data fetched from /api/account.
class LichessAccount {
  const LichessAccount({
    required this.id,
    required this.username,
    required this.avatarIndex,
    this.rapidRating,
    this.puzzleRating,
  });

  final String id;
  final String username;
  final int avatarIndex; // 0–11, index into KidAvatar.all
  final int? rapidRating;
  final int? puzzleRating;

  factory LichessAccount.fromJson(Map<String, dynamic> json, int avatarIndex) {
    final perfs = json['perfs'] as Map<String, dynamic>? ?? {};
    final rapid = perfs['rapid'] as Map<String, dynamic>?;
    final puzzle = perfs['puzzle'] as Map<String, dynamic>?;
    return LichessAccount(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarIndex: avatarIndex,
      rapidRating: rapid?['rating'] as int?,
      puzzleRating: puzzle?['rating'] as int?,
    );
  }
}

/// Provider for the currently logged-in Lichess account.
class AccountNotifier extends AsyncNotifier<LichessAccount?> {
  static const _avatarKey = 'kid_avatar_index';

  // Compile-time token injected via --dart-define=LICHESS_TOKEN=<value>
  static const _envToken = String.fromEnvironment('LICHESS_TOKEN');

  @override
  Future<LichessAccount?> build() async {
    final client = LichessClient();
    // Auto-seed token from compile-time constant when nothing is stored yet
    if (_envToken.isNotEmpty && !await client.isLoggedIn) {
      await client.saveToken(_envToken);
    }
    if (!await client.isLoggedIn) return null;
    try {
      final json = await client.fetchAccount();
      final avatarIndex = await _loadOrAssignAvatar(json['id'] as String);
      return LichessAccount.fromJson(json, avatarIndex);
    } on LichessAuthException {
      return null;
    }
  }

  Future<int> _loadOrAssignAvatar(String userId) async {
    const storage = FlutterSecureStorage();
    final key = '${_avatarKey}_$userId';
    final stored = await storage.read(key: key);
    if (stored != null) return int.tryParse(stored) ?? 0;
    // Assign a random avatar on first login
    final index = Random().nextInt(KidAvatar.all.length);
    await storage.write(key: key, value: index.toString());
    return index;
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = LichessClient();
      if (!await client.isLoggedIn) return null;
      final json = await client.fetchAccount();
      final avatarIndex = await _loadOrAssignAvatar(json['id'] as String);
      return LichessAccount.fromJson(json, avatarIndex);
    });
  }

  Future<void> login(String token) async {
    final client = LichessClient();
    await client.saveToken(token);
    await reload();
  }

  Future<void> logout() async {
    await LichessClient().clearToken();
    state = const AsyncData(null);
  }

  Future<void> cycleAvatar() async {
    final current = state.value;
    if (current == null) return;
    final next = (current.avatarIndex + 1) % KidAvatar.all.length;
    await _setAvatarIndex(current, next);
  }

  Future<void> setAvatar(int index) async {
    final current = state.value;
    if (current == null) return;
    await _setAvatarIndex(current, index.clamp(0, KidAvatar.all.length - 1));
  }

  Future<void> _setAvatarIndex(LichessAccount current, int index) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: '${_avatarKey}_${current.id}', value: index.toString());
    state = AsyncData(LichessAccount(
      id: current.id,
      username: current.username,
      avatarIndex: index,
      rapidRating: current.rapidRating,
      puzzleRating: current.puzzleRating,
    ));
  }
}

final accountProvider =
    AsyncNotifierProvider<AccountNotifier, LichessAccount?>(
  AccountNotifier.new,
);

// ─── Kid Avatar ───────────────────────────────────────────────────────────────

/// A kid avatar backed by a watercolor PNG asset.
class KidAvatar {
  const KidAvatar({
    required this.assetPath,
    required this.label,
    required this.bgColor,
  });

  final String assetPath; // e.g. 'assets/kid_avatars/kid_avatar_1.png'
  final String label;
  final Color bgColor;

  static const all = [
    // Boys
    KidAvatar(assetPath: 'assets/kid_avatars/kid_avatar_1.png', label: 'Boy 1', bgColor: Color(0xFFB6E3F4)),
    KidAvatar(assetPath: 'assets/kid_avatars/kid_avatar_2.png', label: 'Boy 2', bgColor: Color(0xFFFFDFBF)),
    KidAvatar(assetPath: 'assets/kid_avatars/kid_avatar_3.png', label: 'Boy 3', bgColor: Color(0xFFC0AEDE)),
    KidAvatar(assetPath: 'assets/kid_avatars/kid_avatar_4.png', label: 'Boy 4', bgColor: Color(0xFFD1D4F9)),
    // Girls
    KidAvatar(assetPath: 'assets/kid_avatars/kid_avatar_5.png', label: 'Girl 1', bgColor: Color(0xFFFFD5DC)),
    KidAvatar(assetPath: 'assets/kid_avatars/kid_avatar_6.png', label: 'Girl 2', bgColor: Color(0xFFFFDFBF)),
    KidAvatar(assetPath: 'assets/kid_avatars/kid_avatar_7.png', label: 'Girl 3', bgColor: Color(0xFFFFD5DC)),
    KidAvatar(assetPath: 'assets/kid_avatars/kid_avatar_8.png', label: 'Girl 4', bgColor: Color(0xFFC0AEDE)),
  ];
}

/// Renders a kid avatar as a circular widget using a watercolor PNG asset.
class KidAvatarWidget extends StatelessWidget {
  const KidAvatarWidget({
    super.key,
    required this.avatarIndex,
    this.size = 56,
    this.onTap,
    this.label,
  });

  final int avatarIndex;
  final double size;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final avatar = KidAvatar.all[avatarIndex.clamp(0, KidAvatar.all.length - 1)];
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: avatar.bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                avatar.assetPath,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label!,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
