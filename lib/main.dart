import 'dart:async';
import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poseidon_1/pages/Discovery_Page.dart';
import 'package:poseidon_1/pages/Home_Page.dart';
import 'package:poseidon_1/services/moonraker/discovery_service.dart';
import 'package:poseidon_1/services/moonraker/instance/moonraker_instance.dart';
import 'package:poseidon_1/services/moonraker/moonraker_service.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /*Widget initialHome = const DiscoveryPage();

  final MoonrakerDNSInstance? savedInstance =
      await DiscoveryService.loadSavedInstance();

  if (savedInstance != null) {
    print(
      'Saved Moonraker instance found: ${savedInstance.ip}:${savedInstance.port}',
    );
    try {
      await MoonrakerInstance.moonrakerService.connectPrinter(savedInstance);
      initialHome = const HomePage();
    } catch (e) {
      print('Failed to connect to saved printer: $e');
      initialHome = const DiscoveryPage();
    }
  } else {
    print('No saved Moonraker instance found. Opening discovery page.');
  }*/

  await MoonrakerInstance.moonrakerService.connectPrinter(
    MoonrakerDNSInstance(ip: '192.168.68.53', port: 7125),
  );
  Widget initialHome = const HomePage();

  runApp(MainApp(initialHome: initialHome));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.initialHome});

  final Widget initialHome;

  @override
  Widget build(BuildContext context) {
    final ThemeData baseTheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 64, 142, 223),
      brightness: Brightness.dark,
    ).toM3EThemeData();

    return ChangeNotifierProvider<MoonrakerService>.value(
      value: MoonrakerInstance.moonrakerService,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: baseTheme.copyWith(
          textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme),
          primaryTextTheme: GoogleFonts.plusJakartaSansTextTheme(
            baseTheme.primaryTextTheme,
          ),
        ),
        home: initialHome,
      ),
    );
  }
}
