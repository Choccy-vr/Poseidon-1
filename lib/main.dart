import 'dart:async';

import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:poseidon_1/pages/dev_page.dart';
import 'package:poseidon_1/services/moonraker/instance/moonraker_instance.dart';
import 'package:poseidon_1/services/moonraker/moonraker_service.dart';
import 'package:provider/provider.dart';

void main() {
  unawaited(
    MoonrakerInstance.moonrakerService.connectPrinter(
      ip: '192.168.68.53',
      port: 7125,
    ),
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MoonrakerService>.value(
      value: MoonrakerInstance.moonrakerService,
      child: MaterialApp(
        theme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 64, 142, 223),
        ).toM3EThemeData(),
        home: const DevPage(),
      ),
    );
  }
}
