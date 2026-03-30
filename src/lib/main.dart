import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'src/app.dart';

// Pass --dart-define=LICHESS_TOKEN=lip_xxx to pre-seed a token for local testing.
// In production builds this constant is empty and the login screen is shown normally.
const _devToken = String.fromEnvironment('LICHESS_TOKEN');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_devToken.isNotEmpty) {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'lichess_token', value: _devToken);
  }

  runApp(const ProviderScope(child: ChessPalsApp()));
}
