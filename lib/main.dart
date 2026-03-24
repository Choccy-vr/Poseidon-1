import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:poseidon_1/services/moonraker/moonraker_service.dart';

void main() {
  MoonrakerService.connectPrinter(ip: '192.168.68.53', port: 7125);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ColorScheme.fromSeed(
        seedColor: Color.fromARGB(255, 64, 142, 223),
      ).toM3EThemeData(),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Moonraker Demo'),
              ButtonM3E(
                label: Text('Test Printer Info'),
                onPressed: () {
                  MoonrakerService.testPrinterInfo();
                },
              ),

              Column(
                children: [
                  Text('Loading Indicator'),
                  SizedBox(height: 16),
                  LoadingIndicatorM3E(),
                ],
              ),
              Column(
                children: [
                  Text('Circular Progress Indicator - flat'),
                  SizedBox(height: 16),
                  CircularProgressIndicatorM3E(
                    size: CircularProgressM3ESize.m,
                    shape: ProgressM3EShape.flat,
                    value: 50,
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Circular Progress Indicator - wavy'),
                  SizedBox(height: 16),
                  CircularProgressIndicatorM3E(
                    size: CircularProgressM3ESize.m,
                    shape: ProgressM3EShape.wavy,
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Linear Progress Indicator - wavy'),
                  SizedBox(height: 16),
                  LinearProgressIndicatorM3E(
                    value: 50,
                    size: LinearProgressM3ESize.m,
                    shape: ProgressM3EShape.wavy,
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Linear Progress Indicator - flat'),
                  SizedBox(height: 16),
                  LinearProgressIndicatorM3E(
                    value: 50,
                    size: LinearProgressM3ESize.m,
                    shape: ProgressM3EShape.flat,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
