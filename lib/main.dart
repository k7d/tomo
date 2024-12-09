import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:tomo/app_state.dart';
import 'package:tomo/timers.dart';
import 'package:tomo/firebase_options.dart';
import 'package:tomo/content_root.dart';
import 'package:tomo/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppState.syncEnabled = true;
  } catch (e) {
    debugPrint("Firebase not configured, sync will be disabled");
  }

  runApp(ChangeNotifierProvider(
    create: (context) => AppState(),
    builder: ((context, child) => const App()),
  ));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tomo',
      theme: theme,
      navigatorObservers: [routeObserver],
      home: const Timers(),
      debugShowCheckedModeBanner: false,
    );
  }
}
