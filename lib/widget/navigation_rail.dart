import 'package:flutter/material.dart';
import 'package:poseidon_1/pages/Home_Page.dart';
import 'package:poseidon_1/pages/Dev_Page.dart';

final List<Widget> appNavPages = [
  const HomePage(),
  const DevPage(),
  const HomePage(),
  const DevPage(),
  const HomePage(),
];
const List<IconData> appNavIcons = [
  Icons.home,
  Icons.print_rounded,
  Icons.tune_rounded,
  Icons.settings,
  Icons.home,
];

class AppNavigationScaffold extends StatelessWidget {
  const AppNavigationScaffold({
    super.key,
    required this.selectedIndex,
    required this.body,
  });

  final int selectedIndex;
  final Widget body;

  void _goToDestination(BuildContext context, int index) {
    if (index == selectedIndex) {
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
                        child: Icon(
                          appNavIcons[i],
                          fill: 1.0,
                          size: 40,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ] else ...[
                      InkWell(
                        onTap: () => _goToDestination(context, i),

                        child: Icon(
                          appNavIcons[i],
                          fill: 1.0,
                          size: 46,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
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
