import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'data/cwmp_session_store.dart';
import 'router_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Allow app boot without .env in environments where it is not provided.
  }
  final session = await CwmpSessionStore.read();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RouterFlutter(initialSession: session),
    ),
  );
}
