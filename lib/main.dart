import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ColorScheme.fromSeed(seedColor: Colors.blue).toM3EThemeData(),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Hello World!'),
              ButtonM3E(label: Text('Hello World!'), onPressed: () {}),
              LoadingIndicatorM3E(semanticValue: 'Loading...'),
              CircularProgressIndicatorM3E(
                size: CircularProgressM3ESize.m,
                shape: ProgressM3EShape.flat,
                value: 50,
              ),
              CircularProgressIndicatorM3E(
                size: CircularProgressM3ESize.m,
                shape: ProgressM3EShape.wavy,
                value: 50,
              ),
              LinearProgressIndicatorM3E(
                value: 50,
                size: LinearProgressM3ESize.m,
                shape: ProgressM3EShape.wavy,
              ),
              LinearProgressIndicatorM3E(
                value: 50,
                size: LinearProgressM3ESize.m,
                shape: ProgressM3EShape.flat,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
