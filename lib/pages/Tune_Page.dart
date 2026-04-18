import 'package:flutter/material.dart';
import 'package:poseidon_1/pages/Control/Move_Widget.dart';
import 'package:poseidon_1/pages/Control/Temp_Widget.dart';
import 'package:poseidon_1/widget/navigation_rail.dart';

class TunePage extends StatelessWidget {
  const TunePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: AppNavigationScaffold(
        selectedIndex: 2,
        body: Material(
          color: colorScheme.surfaceContainerLow,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Material(
                color: colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.thermostat), text: 'Temp'),
                    Tab(icon: Icon(Icons.open_with_rounded), text: 'Move'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(children: const [TempWidget(), MoveWidget()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
