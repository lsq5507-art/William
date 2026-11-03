import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/space_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SpaceStore();
  await store.load();
  await store.onAppOpen();
  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const LittlePawApp(),
    ),
  );
}
