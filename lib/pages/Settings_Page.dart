import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:poseidon_1/services/moonraker/discovery_service.dart';
import 'package:poseidon_1/widget/navigation_rail.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppNavigationScaffold(
      selectedIndex: 3,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Expanded(
          child: Material(
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    'Settings',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  Divider(
                    height: 32,
                    thickness: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  Row(
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: colorScheme.copyWith(
                            primary: colorScheme.surfaceContainerHigh,
                            onPrimary: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        child: ButtonM3E(
                          label: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Clear Printer Connection',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                          onPressed: () {
                            DiscoveryService.clearSavedInstance();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Saved printer connection cleared. Restart required',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
