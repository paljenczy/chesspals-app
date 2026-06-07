import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chesspals/src/view/game/bot_reaction.dart';

void main() {
  group('detectReaction', () {
    // Helper: play a UCI move on a position and return (oldPos, newPos, move).
    (Position, Position, NormalMove) playUci(Position pos, String uci) {
      final from = Square.fromName(uci.substring(0, 2));
      final to = Square.fromName(uci.substring(2, 4));
      Role? promo;
      if (uci.length == 5) promo = Role.fromChar(uci[4]);
      final move = NormalMove(from: from, to: to, promotion: promo);
      return (pos, pos.play(move), move);
    }

    // Helper: play a sequence of UCI moves from the initial position.
    Position playMoves(List<String> ucis) {
      Position pos = Chess.initial;
      for (final uci in ucis) {
        final from = Square.fromName(uci.substring(0, 2));
        final to = Square.fromName(uci.substring(2, 4));
        Role? promo;
        if (uci.length == 5) promo = Role.fromChar(uci[4]);
        pos = pos.play(NormalMove(from: from, to: to, promotion: promo));
      }
      return pos;
    }

    test('returns null for a quiet pawn push', () {
      final (old, next, move) = playUci(Chess.initial, 'e2e4');
      expect(detectReaction(old, next, move, playerSide: Side.white), isNull);
    });

    test('returns null when lastMove is null', () {
      expect(
        detectReaction(Chess.initial, Chess.initial, null, playerSide: Side.white),
        isNull,
      );
    });

    // ── Capture detection ──────────────────────────────────────────────────────

    test('player captures bot piece → sad', () {
      // Italian game: 1.e4 e5 2.Nf3 Nc6 3.Bc4 Bc5 4.Bxf7+ (player captures)
      final pos = playMoves(['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'f8c5']);
      final (old, next, move) = playUci(pos, 'c4f7');
      // Bxf7+ is also check — check (scared) takes priority over sad
      expect(detectReaction(old, next, move, playerSide: Side.white), BotReaction.scared);
    });

    test('player captures bot piece (no check) → sad', () {
      // 1.e4 d5 2.exd5 (player captures pawn, no check)
      final pos = playMoves(['e2e4', 'd7d5']);
      final (old, next, move) = playUci(pos, 'e4d5');
      expect(detectReaction(old, next, move, playerSide: Side.white), BotReaction.sad);
    });

    test('bot captures player piece → happy', () {
      // 1.e4 e5 2.Nf3 Nc6 3.Bc4 Bc5 4.d3 Bxf2+ (bot=black captures)
      final pos = playMoves(['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'f8c5', 'd2d3']);
      final (old, next, move) = playUci(pos, 'c5f2');
      expect(detectReaction(old, next, move, playerSide: Side.white), BotReaction.happy);
    });

    // ── Check detection ────────────────────────────────────────────────────────

    test('player gives check (non-capture) → scared', () {
      // 1.e4 f5 2.Qh5+ (check without capture)
      final pos = playMoves(['e2e4', 'f7f5']);
      final (old, next, move) = playUci(pos, 'd1h5');
      expect(detectReaction(old, next, move, playerSide: Side.white), BotReaction.scared);
    });

    test('capture + check → scared (check takes priority over sad)', () {
      // Bxf7+ from the Italian game
      final pos = playMoves(['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'f8c5']);
      final (old, next, move) = playUci(pos, 'c4f7');
      expect(next.isCheck, isTrue, reason: 'Bxf7+ should give check');
      expect(detectReaction(old, next, move, playerSide: Side.white), BotReaction.scared);
    });

    // ── Promotion detection ────────────────────────────────────────────────────

    test('player promotes a pawn → furious', () {
      final pos = Chess.fromSetup(Setup.parseFen(
        '8/P7/8/8/8/8/8/4K2k w - - 0 1',
      ));
      final (old, next, move) = playUci(pos, 'a7a8q');
      expect(detectReaction(old, next, move, playerSide: Side.white), BotReaction.furious);
    });

    test('promotion takes priority over check', () {
      final pos = Chess.fromSetup(Setup.parseFen(
        '8/P7/8/8/8/8/8/k3K3 w - - 0 1',
      ));
      final (old, next, move) = playUci(pos, 'a7a8q');
      expect(detectReaction(old, next, move, playerSide: Side.white), BotReaction.furious);
    });

    // ── Bot's turn moves should NOT trigger scared/sad ─────────────────────────

    test('bot giving check on its turn does NOT trigger scared', () {
      // 1.e4 f5 — white (bot) plays Qh5+, player is black
      final pos = playMoves(['e2e4', 'f7f5']);
      final (old, next, move) = playUci(pos, 'd1h5');
      expect(detectReaction(old, next, move, playerSide: Side.black), isNull);
    });

    // ── Edge: en passant capture ────────────────────────────────────────────────

    test('en passant by player → sad (piece count drops)', () {
      // 1.e4 d5 2.e5 f5 3.exf6 (en passant)
      final pos = playMoves(['e2e4', 'd7d5', 'e4e5', 'f7f5']);
      final (old, next, move) = playUci(pos, 'e5f6');
      expect(
        old.board.occupied.size > next.board.occupied.size,
        isTrue,
        reason: 'en passant removes a piece',
      );
      expect(detectReaction(old, next, move, playerSide: Side.white), BotReaction.sad);
    });

    // ── Regression: same position compared to itself → no reaction ─────────────
    // This simulates the bug where _submitMove updates _position optimistically
    // before _commitState runs, so old and new positions are identical.

    test('BUG: when old and new position are identical, no reaction fires', () {
      // Simulate: player captured a piece, but _position was already updated
      final pos = playMoves(['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'f8c5']);
      final move = NormalMove(
        from: Square.fromName('c4'),
        to: Square.fromName('f7'),
      );
      final afterCapture = pos.play(move);

      // This is what happens in the bug: _position is already afterCapture
      final reaction = detectReaction(
        afterCapture, afterCapture, move,
        playerSide: Side.white,
      );
      // No piece count difference, isCheck may differ but position is post-move
      // This demonstrates the bug: reaction is null when it should be scared/sad
      expect(reaction, isNull, reason: 'Bug: optimistic update makes old==new');
    });

    // ── Regression: bot move after optimistic player move ──────────────────────
    // After the player's optimistic update, the next server event carries BOTH
    // the player's move AND the bot's response. _commitState sees
    // old=playerMovePosition, new=afterBotMove. The bot's move should trigger
    // happy (if bot captured) but the player's move reaction is lost.

    test('BUG: player capture reaction lost due to optimistic update', () {
      // 1.e4 d5 2.exd5 (player captures) — then bot plays Qxd5
      final beforePlayerCapture = playMoves(['e2e4', 'd7d5']);
      final afterPlayerCapture = beforePlayerCapture.play(
        NormalMove(from: Square.fromName('e4'), to: Square.fromName('d5')),
      );
      // _submitMove sets _position = afterPlayerCapture
      // Server sends back: "e2e4 d7d5 e4d5" — _applyState replays all moves
      // But _position is already afterPlayerCapture, so detectReaction sees:
      // old=afterPlayerCapture, new=afterPlayerCapture, move=e4d5
      final reaction = detectReaction(
        afterPlayerCapture,
        afterPlayerCapture,
        NormalMove(from: Square.fromName('e4'), to: Square.fromName('d5')),
        playerSide: Side.white,
      );
      // The sad reaction for the player's capture is lost
      expect(reaction, isNull, reason: 'Bug: player capture reaction lost');
    });
  });
}
