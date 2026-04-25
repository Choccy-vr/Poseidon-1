import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:poseidon_1/services/moonraker/instance/moonraker_instance.dart';

class MacrosWidget extends StatelessWidget {
  const MacrosWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final macros =
        MoonrakerInstance.moonrakerService.currentPrinter?.macros ?? [];
    final hasMacros = macros.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: hasMacros
              ? Align(
                  alignment: Alignment.topLeft,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final macro in macros)
                          Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: colorScheme.copyWith(
                                primary: colorScheme.primaryContainer
                                    .withValues(alpha: 0.6),
                                onPrimary: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            child: ButtonM3E(
                              onPressed: () {
                                MoonrakerInstance.moonrakerService.runMacro(
                                  macro,
                                );
                              },
                              label: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 14.0,
                                ),
                                child: Text(
                                  macro.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.playlist_play_rounded,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text('Macros', style: textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'No macros yet. Add your first macro action.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
