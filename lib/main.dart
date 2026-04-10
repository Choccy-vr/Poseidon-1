import 'dart:async';
import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poseidon_1/pages/Home_Page.dart';
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
    final ThemeData baseTheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 64, 142, 223),
      brightness: Brightness.dark,
    ).toM3EThemeData();

    return ChangeNotifierProvider<MoonrakerService>.value(
      value: MoonrakerInstance.moonrakerService,
      child: MaterialApp(
        theme: baseTheme.copyWith(
          textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme),
          primaryTextTheme: GoogleFonts.plusJakartaSansTextTheme(
            baseTheme.primaryTextTheme,
          ),
        ),
        home: HomePage(),
      ),
    );
  }
}
