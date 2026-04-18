import 'package:flutter/material.dart';
import 'package:poseidon_1/pages/Files_Page.dart';
import 'package:poseidon_1/pages/Home_Page.dart';
import 'package:poseidon_1/pages/Dev_Page.dart';
import 'package:poseidon_1/pages/Tune_Page.dart';
import 'package:poseidon_1/services/moonraker/instance/moonraker_instance.dart';

final List<Widget> appNavPages = [
  const HomePage(),
  const FilesPage(),
  const TunePage(),
  const DevPage(),
  const HomePage(),
];
const List<IconData> appNavIcons = [
  Icons.home,
  Icons.folder_rounded,
  Icons.tune_rounded,
  Icons.settings,
];

class AppNavigationScaffold extends StatelessWidget {
  const AppNavigationScaffold({
    super.key,
    required this.selectedIndex,
    required this.body,
  });

  final int selectedIndex;
  final Widget body;

  Widget _buildNavIcon(
    BuildContext context,
    int index, {
    required bool selected,
  }) {
    if (index == 4) {
      return ImageIcon(
        AssetImage('assets/car-brake-alert.png'),
        color: Theme.of(context).colorScheme.error,
        size: 46,
      );
    }

    return Icon(
      appNavIcons[index],
      fill: 1.0,
      size: selected ? 40 : 46,
      color: selected
          ? Theme.of(context).colorScheme.onPrimaryContainer
          : Theme.of(context).colorScheme.onSurface,
    );
  }

  void _goToDestination(BuildContext context, int index) {
    if (index == selectedIndex) {
      return;
    }

    if (index == 4) {
      MoonrakerInstance.moonrakerService.emergencyStop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => appNavPages[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 96,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              elevation: 6,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (int i = 0; i < 5; i++)
                    if (i == selectedIndex) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(1000),
                        ),
                        child: _buildNavIcon(context, i, selected: true),
                      ),
                    ] else ...[
                      InkWell(
                        onTap: () => _goToDestination(context, i),

                        child: _buildNavIcon(context, i, selected: false),
                      ),
                    ],
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(16.0), child: body),
          ),
        ],
      ),
    );
  }
}
